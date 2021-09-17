// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'dart:io';
import 'package:matrix_sdk/src/model/api_call_statistics.dart';
import 'package:matrix_sdk/src/model/request_update.dart';
import 'package:matrix_sdk/src/model/sync_token.dart';
import 'package:matrix_sdk/src/model/sync_update.dart';
import 'package:matrix_sdk/src/model/update.dart';
import 'package:matrix_sdk/src/updater/syncer.dart';
import 'package:mime/mime.dart';
import 'package:pedantic/pedantic.dart';
import 'package:image/image.dart';
import 'package:synchronized/synchronized.dart';
import '../model/context.dart';
import '../event/ephemeral/ephemeral.dart';
import '../event/ephemeral/typing_event.dart';
import '../event/event.dart';
import '../event/room/message_event.dart';
import '../event/room/redaction_event.dart';
import '../event/room/room_event.dart';
import '../event/room/state/room_creation_event.dart';
import '../event/room/state/state_event.dart';
import '../homeserver.dart';
import '../model/identifier.dart';
import '../room/member/member_timeline.dart';
import '../room/member/membership.dart';
import '../model/my_user.dart';
import '../room/room.dart';
import '../room/rooms.dart';
import '../store/store.dart';
import '../room/timeline.dart';
import '../util/random.dart';
import '../model/error_with_stacktrace.dart';
import 'package:collection/collection.dart';

/// Manages updates to [MyUser].
class Updater {
  static final _register = <UserId, Updater>{};

  static Updater? get(UserId id) {
    return _register[id];
  }

  static void register(UserId id, Updater updater) {
    _register[id] = updater;
  }

  final Homeserver homeServer;

  final Store _store;

  /// Most up to date instance of our user.
  MyUser get user => _user;

  MyUser _user;

  late final Syncer _syncer = Syncer(this);

  Syncer get syncer => _syncer;

  final _updatesSubject = StreamController<Update>.broadcast();
  Stream<Update> get updates => _updatesSubject.stream;

  final _errorSubject = StreamController<ErrorWithStackTraceString>.broadcast();
  Stream<ErrorWithStackTraceString> get outError => _errorSubject.stream;
  Sink<ErrorWithStackTraceString> get inError => _errorSubject.sink;

  final _tokenSubject = StreamController<SyncToken>.broadcast();
  Stream<SyncToken> get outSyncToken => _tokenSubject.stream;

  Stream<ApiCallStatistics> get outApiCallStatistics =>
      homeServer.outApiCallStats;

  bool get isReady => _store.isOpen && !_updatesSubject.isClosed;

  /// Initializes the [myUser] with a valid [Context], and will also
  /// initialize it's properties that need the context, such as [Rooms].
  ///
  /// Will also make the [_store] ready to use.
  Updater(
    this._user,
    this.homeServer,
    StoreLocation storeLocation, {
    bool saveMyUserToStore = false,
  }) : _store = storeLocation.create() {
    Updater.register(_user.id, this);

    _store.open();

    if (saveMyUserToStore) {
      unawaited(_store.setMyUserDelta(_user));
    }
  }

  Future<void> saveRoomToDB(Room room) {
    return _store.setRoom(room);
  }

  Future<List<String?>?> getRoomIDs() {
    return _store.getRoomIDs();
  }

  Future<void> startSync({
    Duration maxRetryAfter = const Duration(seconds: 30),
    int timelineLimit = 30,
    String? syncToken,
  }) async {
    if (syncToken == null) {
      final local = await _store.getMyUser(
        _user.id.value,
      );
      syncToken = local?.syncToken;
    }
    _syncer.start(
      maxRetryAfter: maxRetryAfter,
      timelineLimit: timelineLimit,
      syncToken: syncToken,
    );
  }

  final _lock = Lock();

  /// Send out an update, with a new user which is the current [user]
  /// merged with [delta].
  Future<U> _update<U extends Update>(
    MyUser delta,
    U Function(MyUser user, MyUser delta) createUpdate,
  ) async {
    return _lock.synchronized(() async {
      _user = _user.merge(delta);

      await _store.setMyUserDelta(delta.copyWith(id: _user.id));

      final update = createUpdate(_user, delta);
      _updatesSubject.add(update);
      return update;
    });
  }

  Future<RequestUpdate<MyUser>?> setDisplayName({
    required String name,
  }) async {
    await homeServer.api.profile.putDisplayName(
      accessToken: _user.accessToken!,
      userId: _user.id.toString(),
      value: name,
    );

    return _update(
      _user.delta(name: name)!,
      (user, delta) => RequestUpdate(
        user,
        delta,
        data: user,
        deltaData: delta,
        type: RequestType.setName,
      ),
    );
  }

  Future<RequestUpdate<MemberTimeline>?> kick(
    UserId id, {
    required RoomId from,
  }) async {
    if (_user.rooms?[from]?.members?[id]?.membership == Membership.kicked) {
      return RequestUpdate.fromUpdate(
        await updates.first,
        data: (u) => u.rooms?[from]?.memberTimeline,
        deltaData: (u) => u.rooms?[from]?.memberTimeline,
        type: RequestType.kick,
      );
    }

    await homeServer.api.rooms.kick(
      accessToken: _user.accessToken!,
      roomId: from.toString(),
      userId: id.toString(),
    );

    return RequestUpdate.fromUpdate(
      await updates.firstWhere(
        (u) =>
            u.delta.rooms?[from]?.members?.current.kicked.any(
              (m) => m.id == id,
            ) ??
            false,
      ),
      data: (u) => u.rooms?[from]?.memberTimeline,
      deltaData: (u) => u.rooms?[from]?.memberTimeline,
      type: RequestType.kick,
    );
  }

  Stream<RequestUpdate<Timeline>?> send(
    RoomId roomId,
    EventContent content, {
    Room? room,
    String? transactionId,
    String stateKey = '',
    String type = '',
  }) async* {
    final Room? currentRoom = room ??= _user.rooms![roomId];

    transactionId ??= randomString();

    final eventArgs = RoomEventArgs(
      id: EventId(transactionId),
      roomId: roomId,
      time: DateTime.now(),
      senderId: _user.id,
      sentState: SentState.unsent,
      transactionId: transactionId,
    );

    var event = RoomEvent.fromContent(
      content,
      eventArgs,
      type: type,
      isState: stateKey.isNotEmpty,
    );

    if (event == null) {
      return;
    }

    if (event is RoomCreationEvent) {
      throw ArgumentError('This event type cannot be send.');
    }

    var timelineDelta = currentRoom?.timeline?.delta(events: [event]);

    if (timelineDelta == null) {
      return;
    }

    var roomDelta = currentRoom?.delta(timeline: timelineDelta);

    if (roomDelta == null) {
      return;
    }

    yield await _update(
      _user.delta(rooms: [roomDelta])!,
      (user, delta) => RequestUpdate(
        user,
        delta,
        data: currentRoom?.timeline,
        deltaData: currentRoom?.timeline,
        type: RequestType.sendRoomEvent,
      ),
    );

    // TODO: Support for web
    // Upload images from image message events that have a file uri
    if (event is ImageMessageEvent && event.content?.url?.scheme == 'file') {
      final file = File(
        event.content!.url!.toFilePath(windows: Platform.isWindows),
      );

      final fileName = file.path.split(Platform.pathSeparator).last;

      final matrixUrl = await _user.context?.updater?.homeServer.upload(
        as: _user,
        bytes: file.openRead(),
        length: await file.length(),
        contentType: lookupMimeType(file.path) ?? '',
        fileName: fileName,
      );

      final image = decodeImage(file.readAsBytesSync());

      // TODO: Add copyWith
      event = RoomEvent.fromContent(
        ImageMessage(
          url: matrixUrl!,
          body: event.content!.body,
          inReplyToId: event.content!.inReplyToId,
          info: ImageInfo(
            width: image?.width ?? 0,
            height: image?.height ?? 0,
          ),
        ),
        eventArgs,
        type: "",
      );
    }

    if (event == null) {
      return;
    }

    Map<String, dynamic> body;
    if (event is StateEvent) {
      body = await homeServer.api.rooms.sendState(
        accessToken: _user.accessToken!,
        roomId: roomId.toString(),
        eventType: event.type,
        stateKey: stateKey,
        content: event.content?.toJson() ?? {},
      );
    } else {
      body = await homeServer.api.rooms.send(
        accessToken: _user.accessToken!,
        roomId: roomId.toString(),
        eventType: event.type,
        transactionId: transactionId,
        content: event.content?.toJson() ?? {},
      );
    }

    final eventId = EventId(body['event_id']);

    final sentEvent = RoomEvent.fromContent(
      content,
      eventArgs.copyWith(
        id: eventId,
        sentState: SentState.sent,
      ),
      type: type,
      isState: stateKey.isNotEmpty,
    );

    if (sentEvent == null) {
      return;
    }

    timelineDelta = currentRoom?.timeline?.delta(
      events: [sentEvent],
    );
    if (timelineDelta == null) {
      return;
    }

    roomDelta = currentRoom?.delta(
      timeline: timelineDelta,
    );

    if (roomDelta == null) {
      return;
    }

    yield await _update(
      _user.delta(rooms: [roomDelta])!,
      (user, delta) => RequestUpdate(
        user,
        delta,
        data: currentRoom?.timeline,
        deltaData: currentRoom?.timeline,
        type: RequestType.sendRoomEvent,
      ),
    );
  }

  Future<RequestUpdate<Timeline>?> edit(
    RoomId roomId,
    TextMessageEvent event,
    String newContent, {
    Room? room,
    String? transactionId,
  }) async {
    final Room? currentRoom = room ??=
        _user.rooms?.firstWhereOrNull((element) => element.id == roomId);

    if (currentRoom == null) {
      throw ArgumentError('Room not found in users list');
    }

    transactionId ??= randomString();

    await homeServer.api.rooms.edit(
      accessToken: _user.accessToken ?? "",
      roomId: roomId.value,
      transactionId: transactionId,
      event: event,
      newContent: newContent,
    );

    final relevantUpdate = await updates.cast<Update?>().firstWhere(
            (update) => update?.delta.rooms?[roomId] != null,
            orElse: () => null) ??
        await updates.first;

    return _update(
      relevantUpdate.delta,
      (user, delta) => RequestUpdate(
        user,
        delta,
        data: user.rooms?[roomId]?.timeline,
        deltaData: delta.rooms?[roomId]?.timeline,
        type: RequestType.sendRoomEvent,
        basedOnUpdate: true,
      ),
    );
  }

  Future<RequestUpdate<Timeline>?> delete(
    RoomId roomId,
    EventId eventId, {
    String? transactionId,
    String? reason,
    Room? room,
  }) async {
    final Room? currentRoom = room ??=
        _user.rooms?.firstWhereOrNull((element) => element.id == roomId);

    if (currentRoom == null) {
      throw ArgumentError('Room not found in users list');
    }

    transactionId ??= randomString();

    await homeServer.api.rooms.redact(
        accessToken: _user.accessToken ?? '',
        roomId: roomId.value,
        eventId: eventId.value,
        transactionId: transactionId,
        reason: reason);

    final relevantUpdate = await updates.cast<Update?>().firstWhere(
              (update) =>
                  update?.delta.rooms?[roomId]?.timeline?.toList().any(
                      (element) =>
                          element is RedactionEvent &&
                          element.redacts == eventId) ==
                  true,
              orElse: () => null,
            ) ??
        await updates.first;

    return _update(
      relevantUpdate.delta,
      (user, delta) => RequestUpdate(
        user,
        delta,
        data: user.rooms?[roomId]?.timeline,
        deltaData: delta.rooms?[roomId]?.timeline,
        type: RequestType.sendRoomEvent,
        basedOnUpdate: true,
      ),
    );
  }

  Future<RequestUpdate<ReadReceipts>?> markRead({
    required RoomId roomId,
    required EventId until,
    bool receipt = true,
    Room? room,
  }) async {
    if (receipt) {
      final Room? currentRoom = room ??=
          _user.rooms?.firstWhereOrNull((element) => element.id == roomId);
      final isReadAlready = currentRoom?.readReceipts.any(
            (receipt) => receipt.eventId == until && receipt.userId == _user.id,
          ) ??
          false;

      if (isReadAlready) {
        return RequestUpdate.fromUpdate(
          await updates.first,
          data: (u) => u.rooms?[roomId]?.readReceipts,
          deltaData: (u) => u.rooms?[roomId]?.readReceipts,
          type: RequestType.markRead,
        );
      }
    }

    await homeServer.api.rooms.readMarkers(
      accessToken: _user.accessToken!,
      roomId: roomId.toString(),
      fullyRead: until.toString(),
      read: receipt ? until.toString() : null,
    );

    final relevantUpdate = await updates.first;

    //TODO: firstWhere doesn't work good with streams :(
    //Would be great to return this code in future, but let's remove it for now
//    final relevantUpdate = receipt
//        ? await updates.firstWhere(
//          (update) =>
//      update.delta.rooms?[roomId]?.readReceipts.any(
//            (receipt) => receipt.eventId == until,
//      ) ??
//          false,
//    )
//        : await updates.first;

    return RequestUpdate.fromUpdate(
      relevantUpdate,
      data: (u) => u.rooms?[roomId]?.readReceipts,
      deltaData: (u) => u.rooms?[roomId]?.readReceipts,
      type: RequestType.markRead,
    );
  }

  Future<RequestUpdate<MyUser>?> logout() async {
    await syncer.stop();
    await homeServer.api.logout(accessToken: _user.accessToken!);

    final update = await _update(
      _user.delta(isLoggedOut: true)!,
      (user, delta) => RequestUpdate(
        user,
        delta,
        data: user,
        deltaData: delta,
        type: RequestType.logout,
      ),
    );

    await _store.close();

    return update;
  }

  Future<RequestUpdate<Rooms>?> loadRoomsByIDs(
    Iterable<RoomId> roomIds,
    int timelineLimit,
  ) async {
    final rooms = await _store.getRoomsByIDs(
      roomIds,
      timelineLimit: timelineLimit,
      context: _user.context!,
      memberIds: [_user.id],
    );

    return _update(
      _user.delta(rooms: rooms)!,
      (user, delta) => RequestUpdate(
        user,
        delta,
        data: user.rooms!,
        deltaData: delta.rooms!,
        type: RequestType.loadRooms,
      ),
    );
  }

  Future<RequestUpdate<Rooms>?> loadRooms(
    int limit,
    int offset,
    int timelineLimit,
  ) async {
    final rooms = await _store.getRooms(
      timelineLimit: timelineLimit,
      context: _user.context!,
      memberIds: [_user.id],
      limit: limit,
      offset: offset,
    );

    final update = RequestUpdate(
      _user,
      _user.delta(rooms: rooms)!,
      data: Rooms(rooms, context: _user.context),
      deltaData: Rooms(rooms, context: _user.context),
      type: RequestType.loadRooms,
    );

    _updatesSubject.add(update);

    return update;
  }

  Future<RequestUpdate<Timeline>?> loadRoomEvents({
    required RoomId roomId,
    int count = 20,
    Room? room,
  }) async {
    final Room? currentRoom = room ??=
        _user.rooms?.firstWhereOrNull((element) => element.id == roomId);

    if (currentRoom?.timeline == null) {
      return Future.value(null);
    }

    final messages = await _store.getMessages(
      roomId,
      count: count,
      fromTime: currentRoom?.timeline?.last.time,
    );

    var timeline = Timeline(
      messages.events,
      context: currentRoom?.context,
    );

    var memberTimeline = MemberTimeline(
      messages.state,
      context: currentRoom?.context,
    );

    if (timeline.length < count) {
      count -= timeline.length;

      final body = await homeServer.api.rooms.messages(
        accessToken: _user.accessToken ?? '',
        roomId: roomId.toString(),
        limit: count,
        from: currentRoom?.timeline?.previousBatch ?? '',
        filter: {
          'lazy_load_members': true,
        },
      );

      timeline = timeline.merge(
        Timeline.fromJson(
          (body['chunk'] as List<dynamic>).cast(),
          context: currentRoom?.context,
          previousBatch: body['end'],
          previousBatchSetBySync: false,
        ),
      )!;

      if (body.containsKey('state')) {
        memberTimeline = memberTimeline.merge(
          MemberTimeline.fromEvents([
            ...timeline,
            ...(body['state'] as List<dynamic>)
                .cast<Map<String, dynamic>>()
                .map((e) => RoomEvent.fromJson(e, roomId: roomId)!),
          ]),
        );
      }
    }

    final newRoom = Room(
      context: _user.context!,
      id: currentRoom!.id,
      timeline: timeline,
      memberTimeline: memberTimeline,
    );

    return _update(
      _user.delta(rooms: [newRoom])!,
      (user, delta) => RequestUpdate(user, delta,
          data: user.rooms?[newRoom.id]?.timeline,
          deltaData: delta.rooms?[newRoom.id]?.timeline,
          type: RequestType.loadRoomEvents,
          basedOnUpdate: true),
    );
  }

  Future<RequestUpdate<MemberTimeline>?> loadMembers({
    required RoomId roomId,
    int count = 10,
    Room? room,
  }) async {
    final Room? currentRoom = room ??=
        _user.rooms?.firstWhereOrNull((element) => element.id == roomId);

    if (currentRoom == null) {
      return Future.value(null);
    }

    final members = await _store.getMembers(
      roomId,
      fromTime: currentRoom.memberTimeline?.last.since,
      count: count,
    );

    var memberTimeline = MemberTimeline(
      members,
      context: currentRoom.context,
    );

    if (members.length < count) {
      count -= members.length;

      final body = await homeServer.api.rooms.members(
        accessToken: _user.accessToken ?? '',
        roomId: roomId.toString(),
        at: currentRoom.timeline?.previousBatch ?? '',
      );

      final events = (body['chunk'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((e) => RoomEvent.fromJson(e, roomId: roomId))
          .whereNotNull();

      memberTimeline = memberTimeline.merge(
        MemberTimeline.fromEvents(events),
      );
    }

    final newRoom = Room(
      context: _user.context!,
      id: roomId,
      memberTimeline: memberTimeline,
    );

    return _update(
      _user.delta(rooms: [newRoom])!,
      (user, delta) => RequestUpdate(
        user,
        delta,
        data: user.rooms?[newRoom.id]?.memberTimeline,
        deltaData: user.rooms?[newRoom.id]?.memberTimeline,
        type: RequestType.loadMembers,
      ),
    );
  }

  Future<RequestUpdate<Ephemeral>?> setIsTyping({
    required RoomId roomId,
    required bool isTyping,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    await homeServer.api.rooms.typing(
      accessToken: _user.accessToken ?? '',
      roomId: roomId.toString(),
      userId: _user.id.toString(),
      typing: isTyping,
      timeout: timeout.inMilliseconds,
    );

    final updates = _user.context?.updater?.updates;

    if (updates == null) {
      return null;
    } else {
      return RequestUpdate.fromUpdate(
        await updates.firstWhere((u) {
          final containsMe = u.delta.rooms?[roomId]?.ephemeral
              ?.get<TypingEvent>()
              .content
              ?.typerIds
              .contains(_user.id);

          return containsMe == null
              ? false
              : isTyping
                  ? containsMe
                  : !containsMe;
        }),
        data: (u) => u.rooms?[roomId]?.ephemeral!,
        deltaData: (u) => u.rooms?[roomId]?.ephemeral,
        type: RequestType.setIsTyping,
      );
    }
  }

  Future<RequestUpdate<Room>?> joinRoom({
    RoomId? id,
    RoomAlias? alias,
    required Uri serverUrl,
  }) async {
    final body = await homeServer.api.join(
      accessToken: _user.accessToken ?? '',
      roomIdOrAlias: id?.toString() ?? alias?.toString() ?? '',
      serverName: serverUrl.host,
    );

    final roomId = RoomId(body['room_id']);

    return RequestUpdate.fromUpdate(
      await updates.firstWhere(
        (u) => u.user.rooms?[roomId]?.me?.membership == Membership.joined,
      ),
      data: (u) => u.rooms?[roomId],
      deltaData: (u) => u.rooms?[roomId],
      type: RequestType.joinRoom,
    );
  }

  Future<RequestUpdate<Room>?> leaveRoom(RoomId id) async {
    await homeServer.api.rooms.leave(
      accessToken: _user.accessToken ?? '',
      roomId: id.toString(),
    );

    return RequestUpdate.fromUpdate(
      await updates.firstWhere(
        (u) => u.delta.rooms?[id]?.me?.hasLeft ?? false,
      ),
      data: (u) => u.rooms?[id],
      deltaData: (u) => u.rooms?[id],
      type: RequestType.leaveRoom,
    );
  }

  /// Note: Will return RequestUpdate<Pushers> in the future.
  Future<void> setPusher(Map<String, dynamic> pusher) {
    return homeServer.api.pushers.set(
      accessToken: _user.accessToken ?? '',
      body: pusher,
    );

    //  RequestUpdate.fromUpdate(
    //   await updates.first,
    //   data: (user) => user,
    //   deltaData: (delta) => delta,
    //   type: RequestType.setPusher,
    // );
  }

  Future<void> processSync(Map<String, dynamic> body) async {
    final roomDeltas = await _processRooms(body);

    if (roomDeltas.isNotEmpty) {
      await _update(
        _user.delta(
          syncToken: body['next_batch'],
          rooms: roomDeltas,
          hasSynced: !(_user.hasSynced ?? false) ? true : null,
        )!,
        (user, delta) => SyncUpdate(user, delta),
      );
    }
  }

  /// Returns list of room delta.
  Future<List<Room>> _processRooms(Map<String, dynamic> body) async {
    final jRooms = body['rooms'];

    const join = 'join';
    const invite = 'invite';
    const leave = 'leave';

    Future<List<Room>?> process(
      Map<String, dynamic>? rooms, {
      required String type,
    }) async {
      final roomDeltas = <Room>[];

      if (rooms != null) {
        for (final entry in rooms.entries) {
          final roomId = RoomId(entry.key);
          final json = entry.value;

          var currentRoom = _user.rooms?[roomId];

          /// Room is from store or newly joined/invited.
          var isNewRoom = false;
          if (currentRoom == null) {
            isNewRoom = true;
            currentRoom = await _store.getRoom(
                  roomId,
                  context: _user.context!,
                  memberIds: [_user.id],
                ) ??
                Room.base(
                  context: Context(myId: _user.id),
                  id: roomId,
                );
          }

          var roomDelta = Room.fromJson(json, context: currentRoom.context!);

          // Set previous batch to null if it wasn't set by sync before
          if (!(currentRoom.timeline?.previousBatchSetBySync ?? true)) {
            roomDelta = roomDelta.copyWith(
              // We can't use copyWith because we're setting previousBatch to
              // null again
              timeline: Timeline(
                roomDelta.timeline!,
                context: roomDelta.context,
                previousBatch: null,
                previousBatchSetBySync: false,
              ),
            );
          }

          final accountData = body['account_data'];
          // Process account data
          if (accountData != null) {
            final events = accountData['events'] as List<dynamic>;

            final event = events.firstWhere(
              (event) => event['type'] == 'm.direct',
              orElse: () => null,
            );

            if (event != null) {
              final content = event['content'] as Map<String, dynamic>;

              for (final entry in content.entries) {
                final userId = entry.key;
                final roomIds = entry.value;

                if (UserId.isValidFullyQualified(userId) &&
                    roomIds.contains(roomId.toString())) {
                  roomDelta = roomDelta.copyWith(directUserId: UserId(userId));
                  break;
                }
              }
            }
          }

          // Process redactions
          // TODO: Redaction deltas
          for (final event
              in currentRoom.timeline!.whereType<RedactionEvent>()) {
            final redactedId = event.redacts;

            final original = currentRoom.timeline?[redactedId];
            if (original != null && original is! RedactedEvent) {
              final newTimeline = currentRoom.timeline!.merge(
                Timeline(
                  [
                    ...currentRoom.timeline!.where((e) => e.id != redactedId),
                    RedactedEvent.fromRedaction(
                      redaction: event,
                      original: original,
                    ),
                  ],
                  context: currentRoom.context,
                ),
              );

              roomDelta = roomDelta.copyWith(timeline: newTimeline!);
            }
          }

          if (isNewRoom) {
            roomDelta = currentRoom.merge(roomDelta);
          }

          roomDeltas.add(roomDelta);
        }

        return roomDeltas;
      }

      return null;
    }

    final joins =
        jRooms == null ? [] : ((await process(jRooms[join], type: join)) ?? []);
    final invites = jRooms == null
        ? []
        : ((await process(jRooms[invite], type: invite)) ?? []);
    final leaves = jRooms == null
        ? []
        : ((await process(jRooms[leave], type: leave)) ?? []);
    return [
      ...joins,
      ...invites,
      ...leaves,
    ];
  }
}
