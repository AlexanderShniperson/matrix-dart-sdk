// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'dart:io';

import 'package:mime/mime.dart';
import 'package:pedantic/pedantic.dart';
import 'package:async/async.dart';
import 'package:meta/meta.dart';
import 'package:image/image.dart';
import 'package:synchronized/synchronized.dart';

import '../context.dart';
import '../event/ephemeral/ephemeral.dart';
import '../event/ephemeral/typing_event.dart';
import '../event/event.dart';
import '../event/room/message_event.dart';
import '../event/room/redaction_event.dart';
import '../event/room/room_event.dart';
import '../event/room/state/room_creation_event.dart';
import '../event/room/state/state_event.dart';
import '../homeserver.dart';
import '../identifier.dart';
import '../room/member/member_timeline.dart';
import '../room/member/membership.dart';
import '../my_user.dart';
import '../room/room.dart';
import '../room/rooms.dart';
import '../store/store.dart';
import '../room/timeline.dart';
import 'isolated/isolated_updater.dart';
import '../util/random.dart';
import '../model/error_with_stacktrace.dart';

/// Manages updates to [MyUser].
class Updater {
  static final _register = <UserId, Updater>{};

  static Updater get(UserId id) => _register[id];

  static void register(UserId id, Updater updater) => _register[id] = updater;

  final Homeserver homeserver;

  final Store _store;

  /// Most up to date instance of our user.
  MyUser get user => _user;

  MyUser _user;

  Syncer _syncer;
  Syncer get syncer => _syncer ??= Syncer(this);

  final _updatesSubject = StreamController<Update>.broadcast();
  Stream<Update> get updates => _updatesSubject.stream;

  final _errorSubject = StreamController<ErrorWithStackTraceString>.broadcast();
  Stream<ErrorWithStackTraceString> get outError => _errorSubject.stream;

  bool get isReady => _store.isOpen && !_updatesSubject.isClosed;

  /// Initializes the [myUser] with a valid [Context], and will also
  /// initialize it's properties that need the context, such as [Rooms].
  ///
  /// Will also make the [_store] ready to use.
  Updater(
    this._user,
    this.homeserver,
    StoreLocation storeLocation, {
    bool saveMyUserToStore = false,
  }) : _store = storeLocation.create() {
    register(_user.id, this);

    _store.open();

    if (saveMyUserToStore) {
      unawaited(_store.setMyUserDelta(_user));
    }
  }

  static Future<IsolatedUpdater> isolated(
    MyUser myUser,
    Homeserver homeserver,
    StoreLocation storeLocation, {
    bool saveMyUserToStore = false,
  }) =>
      IsolatedUpdater.create(
        myUser,
        homeserver,
        storeLocation,
        saveMyUserToStore: saveMyUserToStore,
      );

  final _lock = Lock();

  /// Send out an update, with a new user which is the current [user]
  /// merged with [delta].
  Future<U> _update<U extends Update>(
    MyUser delta,
    U Function(MyUser user, MyUser delta) createUpdate,
  ) async {
    return await _lock.synchronized(() async {
      _user = _user.merge(delta);

      await _store.setMyUserDelta(delta.copyWith(id: _user.id));

      final update = createUpdate(_user, delta);
      _updatesSubject.add(update);
      return update;
    });
  }

  Future<RequestUpdate<MyUser>> setName({@required String name}) async {
    await homeserver.api.profile.putDisplayName(
      accessToken: _user.accessToken,
      userId: _user.id.toString(),
      value: name,
    );

    return await _update(
      _user.delta(name: name),
      (user, delta) => RequestUpdate(
        user,
        delta,
        data: user,
        deltaData: delta,
        type: RequestType.setName,
      ),
    );
  }

  Future<RequestUpdate<MemberTimeline>> kick(
    UserId id, {
    @required RoomId from,
  }) async {
    if (_user.rooms[from].members[id]?.membership == Membership.kicked) {
      return RequestUpdate.fromUpdate(
        await updates.first,
        data: (u) => u.rooms[from].memberTimeline,
        deltaData: (u) => u?.rooms[from]?.memberTimeline,
        type: RequestType.kick,
      );
    }

    await homeserver.api.rooms.kick(
      accessToken: _user.accessToken,
      roomId: from.toString(),
      userId: id.toString(),
    );

    return RequestUpdate.fromUpdate(
      await updates.firstWhere(
        (u) => u.delta.rooms[from].members.current.kicked.any(
          (m) => m.id == id,
        ),
      ),
      data: (u) => u.rooms[from].memberTimeline,
      deltaData: (u) => u.rooms[from].memberTimeline,
      type: RequestType.kick,
    );
  }

  Stream<RequestUpdate<Timeline>> send(
    RoomId roomId,
    EventContent content, {
    String transactionId,
    String stateKey = '',
    String type,
  }) async* {
    final currentRoom = _user.rooms[roomId];

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

    if (event == null || event is RoomCreationEvent) {
      throw ArgumentError('This event type cannot be send.');
    }

    yield await _update(
      _user.delta(
        rooms: [
          currentRoom.delta(
            timeline: currentRoom.timeline.delta(
              events: [event],
            ),
          ),
        ],
      ),
      (user, delta) => RequestUpdate(
        user,
        delta,
        data: user.rooms[roomId].timeline,
        deltaData: user.rooms[roomId].timeline,
        type: RequestType.sendRoomEvent,
      ),
    );

    // TODO: Support for web
    // Upload images from image message events that have a file uri
    if (event is ImageMessageEvent && event.content.url.scheme == 'file') {
      final imageEvent = event as ImageMessageEvent;

      final file = File(
        imageEvent.content.url.toFilePath(windows: Platform.isWindows),
      );

      final fileName = file.path.split(Platform.pathSeparator).last;

      final matrixUrl = await _user.upload(
        bytes: file.openRead(),
        length: await file.length(),
        contentType: lookupMimeType(file.path),
        fileName: fileName,
      );

      final image = decodeImage(file.readAsBytesSync());

      // TODO: Add copyWith
      event = RoomEvent.fromContent(
        ImageMessage(
          url: matrixUrl,
          body: imageEvent.content.body,
          inReplyToId: imageEvent.content.inReplyToId,
          info: ImageInfo(
            width: image.width,
            height: image.height,
          ),
        ),
        eventArgs,
      );
    }

    Map<String, dynamic> body;
    if (event is StateEvent) {
      body = await homeserver.api.rooms.sendState(
        accessToken: _user.accessToken,
        roomId: roomId.toString(),
        eventType: event.type,
        stateKey: stateKey,
        content: event.content.toJson(),
      );
    } else {
      body = await homeserver.api.rooms.send(
        accessToken: _user.accessToken,
        roomId: roomId.toString(),
        eventType: event.type,
        transactionId: transactionId,
        content: event.content.toJson(),
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

    yield await _update(
      _user.delta(
        rooms: [
          currentRoom.delta(
            timeline: currentRoom.timeline.delta(
              events: [sentEvent],
            ),
          ),
        ],
      ),
      (user, delta) => RequestUpdate(
        user,
        delta,
        data: user.rooms[roomId].timeline,
        deltaData: user.rooms[roomId].timeline,
        type: RequestType.sendRoomEvent,
      ),
    );
  }

  Future<RequestUpdate<Timeline>> delete(
    RoomId roomId,
    EventId eventId, {
    String transactionId,
    String reason = 'Deleted by author',
  }) async {
    final currentRoom = _user.rooms
        .firstWhere((element) => element.id == roomId, orElse: () => null);

    if (currentRoom == null) {
      throw ArgumentError('Room not found in users list');
    }

    transactionId ??= randomString();

    await homeserver.api.rooms.redact(
        accessToken: _user.accessToken,
        roomId: roomId.value,
        eventId: eventId.value,
        transactionId: transactionId,
        reason: reason);

    final relevantUpdate = await updates.firstWhere(
            (update) => update.delta.rooms[roomId]?.timeline?.toList()?.any(
                (element) =>
            element is RedactionEvent && element.redacts == eventId),
        orElse: () => null) ??
        await updates.first;

    return _update(
      relevantUpdate.delta,
          (user, delta) => RequestUpdate(
        user,
        delta,
        data: user.rooms[roomId].timeline,
        deltaData: delta.rooms[roomId].timeline,
        type: RequestType.sendRoomEvent,
      ),
    );
  }

  Future<RequestUpdate<ReadReceipts>> markRead({
    @required RoomId roomId,
    @required EventId until,
    bool receipt = true,
  }) async {
    if (receipt) {
      final isReadAlready = _user.rooms[roomId].readReceipts.any(
        (receipt) => receipt.eventId == until && receipt.userId == _user.id,
      );

      if (isReadAlready) {
        return RequestUpdate.fromUpdate(
          await updates.first,
          data: (u) => u.rooms[roomId].readReceipts,
          deltaData: (u) => u.rooms[roomId]?.readReceipts,
          type: RequestType.markRead,
        );
      }
    }

    await homeserver.api.rooms.readMarkers(
      accessToken: _user.accessToken,
      roomId: roomId.toString(),
      fullyRead: until.toString(),
      read: receipt ? until.toString() : null,
    );

    final relevantUpdate = receipt
        ? await updates.firstWhere(
            (update) =>
                update.delta.rooms[roomId]?.readReceipts?.any(
                  (receipt) => receipt.eventId == until,
                ) ??
                false,
          )
        : await updates.first;

    return RequestUpdate.fromUpdate(
      relevantUpdate,
      data: (u) => u.rooms[roomId].readReceipts,
      deltaData: (u) => u.rooms[roomId].readReceipts,
      type: RequestType.markRead,
    );
  }

  Future<RequestUpdate<MyUser>> logout() async {
    await syncer.stop();
    await homeserver.api.logout(accessToken: _user.accessToken);

    final update = await _update(
      _user.delta(isLoggedOut: true),
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

  Future<RequestUpdate<Rooms>> loadRooms(
    Iterable<RoomId> roomIds,
    int timelineLimit,
  ) async {
    final rooms = await _store.getRooms(
      roomIds,
      timelineLimit: timelineLimit,
      context: _user.context,
      memberIds: [_user.id],
    );

    return await _update(
      _user.delta(rooms: rooms),
      (user, delta) => RequestUpdate(
        user,
        delta,
        data: user.rooms,
        deltaData: delta.rooms,
        type: RequestType.loadRooms,
      ),
    );
  }

  Future<RequestUpdate<Timeline>> loadRoomEvents({
    @required RoomId roomId,
    int count = 20,
  }) async {
    final currentRoom = _user.rooms[roomId];

    final messages = await _store.getMessages(
      roomId,
      count: count,
      fromTime: currentRoom.timeline.last.time,
    );

    var timeline = Timeline(
      messages.events,
      context: currentRoom.context,
    );

    var memberTimeline = MemberTimeline(
      messages.state,
      context: currentRoom.context,
    );

    if (timeline.length < count) {
      count -= timeline.length;

      final body = await homeserver.api.rooms.messages(
        accessToken: _user.accessToken,
        roomId: roomId.toString(),
        limit: count,
        from: currentRoom.timeline.previousBatch,
        filter: {
          'lazy_load_members': true,
        },
      );

      timeline = timeline.merge(
        Timeline.fromJson(
          (body['chunk'] as List<dynamic>).cast(),
          context: currentRoom.context,
          previousBatch: body['end'],
          previousBatchSetBySync: false,
        ),
      );

      if (body.containsKey('state')) {
        memberTimeline = memberTimeline.merge(
          MemberTimeline.fromEvents([
            ...timeline,
            ...(body['state'] as List<dynamic>)
                .cast<Map<String, dynamic>>()
                .map((e) => RoomEvent.fromJson(e, roomId: roomId)),
          ]),
        );
      }
    }

    final newRoom = Room(
      context: _user.context,
      id: currentRoom.id,
      timeline: timeline,
      memberTimeline: memberTimeline,
    );

    return await _update(
      _user.delta(rooms: [newRoom]),
      (user, delta) => RequestUpdate(
        user,
        delta,
        data: user.rooms[newRoom.id].timeline,
        deltaData: delta.rooms[newRoom.id].timeline,
        type: RequestType.loadRoomEvents,
      ),
    );
  }

  Future<RequestUpdate<MemberTimeline>> loadMembers({
    @required RoomId roomId,
    int count = 10,
  }) async {
    final currentRoom = _user.rooms[roomId];

    final members = await _store.getMembers(
      roomId,
      fromTime: currentRoom.memberTimeline.last.since,
      count: count,
    );

    var memberTimeline = MemberTimeline(
      members,
      context: currentRoom.context,
    );

    if (count == null || members.length < count) {
      if (count != null) {
        count -= members.length;
      }

      final body = await homeserver.api.rooms.members(
        accessToken: _user.accessToken,
        roomId: roomId.toString(),
        at: currentRoom.timeline.previousBatch,
      );

      final events = (body['chunk'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((e) => RoomEvent.fromJson(e, roomId: roomId));

      memberTimeline = memberTimeline.merge(
        MemberTimeline.fromEvents(events),
      );
    }

    final newRoom = Room(
      context: _user.context,
      id: roomId,
      memberTimeline: memberTimeline,
    );

    return await _update(
      _user.delta(rooms: [newRoom]),
      (user, delta) => RequestUpdate(
        user,
        delta,
        data: user.rooms[newRoom.id].memberTimeline,
        deltaData: user.rooms[newRoom.id].memberTimeline,
        type: RequestType.loadMembers,
      ),
    );
  }

  Future<RequestUpdate<Ephemeral>> setIsTyping({
    @required RoomId roomId,
    @required bool isTyping,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    await homeserver.api.rooms.typing(
      accessToken: _user.accessToken,
      roomId: roomId.toString(),
      userId: _user.id.toString(),
      typing: isTyping,
      timeout: timeout.inMilliseconds,
    );

    return RequestUpdate.fromUpdate(
      await _user.updates.firstWhere((u) {
        final containsMe = u.delta.rooms[roomId]?.ephemeral
            ?.get<TypingEvent>()
            ?.content
            ?.typerIds
            ?.contains(_user.id);

        return containsMe == null
            ? false
            : isTyping
                ? containsMe
                : !containsMe;
      }),
      data: (u) => u.rooms[roomId].ephemeral,
      deltaData: (u) => u.rooms[roomId]?.ephemeral,
      type: RequestType.setIsTyping,
    );
  }

  Future<RequestUpdate<Room>> joinRoom({
    RoomId id,
    RoomAlias alias,
    Uri serverUrl,
  }) async {
    final body = await homeserver.api.join(
      accessToken: _user.accessToken,
      roomIdOrAlias: id?.toString() ?? alias.toString(),
      serverName: serverUrl?.host,
    );

    final roomId = RoomId(body['room_id']);

    return RequestUpdate.fromUpdate(
      await updates.firstWhere(
        (u) => u.user.rooms[roomId]?.me?.membership == Membership.joined,
      ),
      data: (u) => u.rooms[roomId],
      deltaData: (u) => u.rooms[roomId],
      type: RequestType.joinRoom,
    );
  }

  Future<RequestUpdate<Room>> leaveRoom(RoomId id) async {
    await homeserver.api.rooms.leave(
      accessToken: _user.accessToken,
      roomId: id.toString(),
    );

    return RequestUpdate.fromUpdate(
      await updates.firstWhere(
        (u) => u.delta.rooms[id]?.me?.hasLeft,
      ),
      data: (u) => u.rooms[id],
      deltaData: (u) => u.rooms[id],
      type: RequestType.leaveRoom,
    );
  }

  /// Note: Will return RequestUpdate<Pushers> in the future.
  Future<void> setPusher(Map<String, dynamic> pusher) {
    return homeserver.api.pushers.set(
      accessToken: _user.accessToken,
      body: pusher,
    );

    //  RequestUpdate.fromUpdate(
    //   await updates.first,
    //   data: (user) => user,
    //   deltaData: (delta) => delta,
    //   type: RequestType.setPusher,
    // );
  }

  void _addError(dynamic error, [StackTrace stackTrace]) {
    _errorSubject.add(ErrorWithStackTraceString(
      error,
      stackTrace?.toString() ?? "",
    ));
  }

  Future<void> _processSync(Map<String, dynamic> body) async {
    final roomDeltas = await _processRooms(body);

    if (roomDeltas.isNotEmpty) {
      await _update(
        _user.delta(
          syncToken: body['next_batch'],
          rooms: roomDeltas,
          hasSynced: !_user.hasSynced ? true : null,
        ),
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

    Future<List<Room>> process(
      Map<String, dynamic> rooms, {
      @required String type,
    }) async {
      final roomDeltas = <Room>[];

      if (rooms != null) {
        for (final entry in rooms.entries) {
          final roomId = RoomId(entry.key);
          final json = entry.value;

          var currentRoom = _user.rooms[roomId];

          /// Room is from store or newly joined/invited.
          var isNewRoom = false;
          if (currentRoom == null) {
            isNewRoom = true;
            currentRoom = await _store.getRoom(
                  roomId,
                  context: _user.context,
                  memberIds: [_user.id],
                ) ??
                Room.base(
                  context: Context(myId: _user.id),
                  id: roomId,
                );
          }

          var roomDelta = Room.fromJson(json, context: currentRoom.context);

          // Set previous batch to null if it wasn't set by sync before
          if (!(currentRoom.timeline.previousBatchSetBySync ?? true)) {
            roomDelta = roomDelta.copyWith(
              // We can't use copyWith because we're setting previousBatch to
              // null again
              timeline: Timeline(
                roomDelta.timeline,
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
              in currentRoom.timeline.whereType<RedactionEvent>()) {
            final redactedId = event.redacts;

            final original = currentRoom.timeline[redactedId];
            if (original != null && original is! RedactedEvent) {
              final newTimeline = currentRoom.timeline.merge(
                Timeline(
                  [
                    ...currentRoom.timeline.where((e) => e.id != redactedId),
                    RedactedEvent.fromRedaction(
                      redaction: event,
                      original: original,
                    ),
                  ],
                  context: currentRoom.context,
                ),
              );

              roomDelta = roomDelta.copyWith(timeline: newTimeline);
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

    return [
      ...await process(jRooms[join], type: join),
      ...await process(jRooms[invite], type: invite),
      ...await process(jRooms[leave], type: leave),
    ];
  }
}

/// An update to [MyUser], either because of a sync or because of a request.
@immutable
abstract class Update {
  final MyUser user;

  /// The delta [MyUser]. All properties of [delta] are null except
  /// those that are changed with this update. It's `context` and `id` will
  /// also never be null, even if unchanged, which they won't.
  ///
  /// This is useful to find out what changed between an update.
  final MyUser delta;

  Update._(this.user, this.delta);

  MinimizedUpdate minimize();
}

/// An update caused by a sync.
class SyncUpdate extends Update {
  SyncUpdate(
    MyUser user,
    MyUser delta,
  ) : super._(user, delta);

  @override
  MinimizedSyncUpdate minimize() => MinimizedSyncUpdate(delta: delta);
}

extension UpdatesExtension on Stream<Update> {
  Future<Update> get firstSync => firstWhere((u) => u is SyncUpdate);

  Stream<SyncUpdate> get onlySync => where((u) => u is SyncUpdate).cast();
}

/// An update caused by a request, which has the relevant updated [data] at
/// hand for easy access, and also a [deltaData].
class RequestUpdate<T extends Contextual<T>> extends Update {
  final T data;
  final T deltaData;

  /// Type that caused this request.
  final RequestType type;

  /// True if this RequestUpdate was based on another update.
  final bool basedOnUpdate;

  RequestUpdate(
    MyUser user,
    MyUser deltaUser, {
    @required this.data,
    @required this.deltaData,
    @required this.type,
    // Must not be set to true in most cases.
    this.basedOnUpdate = false,
  }) : super._(user, deltaUser);

  /// If this constructor is used, its respective [RequestInstruction] should
  /// have `basedOnSyncUpdate` set to true.
  RequestUpdate.fromUpdate(
    Update update, {
    @required T Function(MyUser user) data,
    @required T Function(MyUser delta) deltaData,
    @required RequestType type,
  }) : this(
          update.user,
          update.delta,
          data: data(update.user),
          deltaData: deltaData(update.delta),
          type: type,
          basedOnUpdate: true,
        );

  @override
  MinimizedRequestUpdate<T> minimize() => MinimizedRequestUpdate<T>(
        delta: delta,
        deltaData: deltaData,
        type: type,
        basedOnUpdate: basedOnUpdate,
      );
}

enum RequestType {
  kick,
  loadRoomEvents,
  loadMembers,
  loadRooms,
  logout,
  markRead,
  sendRoomEvent,
  setIsTyping,
  joinRoom,
  leaveRoom,
  setName,
  setPusher,
}

class Syncer {
  final Updater _updater;

  Homeserver get _homeserver => _updater.homeserver;
  MyUser get _user => _updater.user;

  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  Syncer(this._updater);

  Future<void> _syncFuture;
  CancelableOperation<Map<String, dynamic>> _cancelableSyncOnceResponse;

  /// Syncs data with the user's [_homeserver].
  void start({
    Duration maxRetryAfter = const Duration(seconds: 30),
  }) {
    if (_user.isLoggedOut) {
      throw StateError('The user can not be logged out');
    }

    _syncFuture = _startSync(maxRetryAfter: maxRetryAfter);
  }

  bool _shouldStopSync = false;

  Future<void> _startSync({
    Duration maxRetryAfter,
  }) async {
    maxRetryAfter ??= const Duration(seconds: 30);

    _shouldStopSync = false;
    _isSyncing = true;

    // This var is used to implements exponential backoff
    // until it reaches maxRetryAfter
    var retryAfter = 500;

    while (!_shouldStopSync) {
      final body = await _sync(
        timeout: Duration(seconds: 10),
      );

      if (_shouldStopSync) return;

      if (body == null) {
        await Future.delayed(Duration(milliseconds: retryAfter));

        if (_shouldStopSync) return;

        retryAfter = (retryAfter * 1.5).floor();
        if (retryAfter > maxRetryAfter.inMilliseconds) {
          retryAfter = maxRetryAfter.inMilliseconds;
        }
      } else {
        await _updater._processSync(body);

        // Reset exponential backoff.
        retryAfter = 500;
      }
    }
  }

  Future<Map<String, dynamic>> _sync({
    timeout = Duration.zero,
    bool fullState = false,
  }) async {
    if (_user.isLoggedOut) {
      throw StateError('The user can not be logged out');
    }

    if (_shouldStopSync) return null;

    try {
      final cancelable = CancelableOperation.fromFuture(
        _homeserver.api.sync(
          accessToken: _user.accessToken,
          since: _user.syncToken,
          fullState: fullState,
          filter: {
            'room': {
              'state': {
                'lazy_load_members': true,
              },
              'timeline': {
                'limit': 30,
              },
            },
          },
          timeout: timeout.inMilliseconds,
        ),
      );

      _cancelableSyncOnceResponse = cancelable;

      final body = await cancelable.valueOrCancellation();

      // We're cancelled
      if (body == null) return null;

      if (_shouldStopSync) return null;

      return body;
    } on Exception catch (e) {
      _updater._addError(e, StackTrace.current);

      return null;
    }
  }

  Future<void> stop() async {
    _shouldStopSync = true;
    await _cancelableSyncOnceResponse?.cancel();
    await _syncFuture;
    _isSyncing = false;
  }
}
