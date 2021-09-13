import 'dart:async';

import 'package:matrix_sdk/matrix_sdk.dart';
import 'package:matrix_sdk/src/updater/isolated/isolated_updater.dart';
import 'package:matrix_sdk/src/model/sync_filter.dart';
import 'package:matrix_sdk/src/updater/one_room_syncer.dart';
import 'model/api_call_statistics.dart';
import 'model/request_update.dart';
import 'model/update.dart';

class MatrixClient {
  final bool isIsolated;
  final Uri serverUri;
  final Homeserver _homeServer;
  final StoreLocation _storeLocation;
  final List<StreamSubscription> _streamSubscription = [];
  OneRoomSyncer? _oneRoomSyncer;

  // ignore: close_sinks
  final _apiCallStatsSubject = StreamController<ApiCallStatistics>.broadcast();
  Stream<ApiCallStatistics> get outApiCallStatistics =>
      _apiCallStatsSubject.stream;

  // ignore: close_sinks
  final _errorSubject = StreamController<ErrorWithStackTraceString>.broadcast();
  Stream<ErrorWithStackTraceString> get outError => _errorSubject.stream;

  // ignore: close_sinks
  final _updatesSubject = StreamController<Update>.broadcast();
  Stream<Update> get outUpdates => _updatesSubject.stream;

  Updater? _updater;

  MatrixClient({
    this.isIsolated = true,
    required this.serverUri,
    required StoreLocation storeLocation,
  })  : _homeServer = Homeserver(serverUri),
        _storeLocation = storeLocation;

  Homeserver get homeServer => _homeServer;

  /// Get all invites for this user. Note that for now this will load
  /// all rooms to memory.
  /*Future<List<Invite>> get invites async =>
      (await _rooms.get(where: (r) => r is InvitedRoom))
          .map((r) => Invite._(scope, r))
          .toList(growable: false);*/

  Future<MyUser> login(
    UserIdentifier user,
    String password, {
    Device? device,
  }) async {
    _streamSubscription
        .add(_homeServer.outApiCallStats.listen(_apiCallStatsSubject.add));
    final result = await _homeServer.login(
      user,
      password,
      device: device,
    );

    if (isIsolated) {
      _updater = await IsolatedUpdater.create(
        result,
        _homeServer,
        _storeLocation,
      );
    } else {
      _updater = Updater(
        result,
        _homeServer,
        _storeLocation,
      );
    }

    if (_updater != null) {
      _streamSubscription.add(_updater!.updates.listen(_updatesSubject.add));
      _streamSubscription
          .add(_updater!.outApiCallStatistics.listen(_apiCallStatsSubject.add));
      _streamSubscription.add(_updater!.outError.listen(_errorSubject.add));
    }

    return result;
  }

  /// Invalidates the access token of the user. Makes all
  /// [MyUser] calls unusable.
  ///
  /// Returns the [Update] where [MyUser] has logged out, if successful.
  Future<RequestUpdate<MyUser>?> logout(MyUser user) async {
    final result = user.context?.updater?.logout();
    await stopSync(user);
    return result ?? Future.value(null);
  }

  /// Send all unsent messages still in the [Store].
  /*Future<void> sendAllUnsent() async {
    for (Room room in await rooms.get()) {
      if (room is JoinedRoom) {
        for (RoomEvent event in await _store.getUnsentEvents(room)) {
          await for (final _ in room.send(
            event.content,
            transactionId: event.transactionId,
          )) {}
        }
      }
    }
  }*/

  bool isSyncing(MyUser user) =>
      user.context?.updater?.syncer.isSyncing ?? false;

  void startSync(
    MyUser user, {
    Duration maxRetryAfter = const Duration(seconds: 30),
    int timelineLimit = 30,
  }) {
    user.context?.updater?.startSync(
      maxRetryAfter: maxRetryAfter,
      timelineLimit: timelineLimit,
    );
  }

  Future<void> stopSync(MyUser user) {
    _streamSubscription.forEach((e) {
      e.cancel();
    });
    _streamSubscription.clear();
    final result = user.context?.updater?.syncer.stop();
    return result ?? Future.value();
  }

  Future<Room?> getRoom({
    required String roomID,
    int limit = 20,
  }) async {
    if (_updater == null) {
      return Future.value(null);
    }
    final update = await _updater!.loadRoomsByIDs([RoomId(roomID)], limit);
    return update?.data?.firstWhere((e) => e.id.value == roomID);
  }

  Future<List<Room>> getRooms({
    int limit = 50,
    int offset = 0,
    int timelineLimit = 20,
  }) async {
    if (_updater == null) {
      return Future.value([]);
    }
    final update = await _updater!.loadRooms(limit, offset, timelineLimit);
    return update?.deltaData?.toList() ?? [];
  }

  Future<List<Room?>> getRoomsByIDs({
    required Iterable<RoomId> roomIDs,
    int limit = 40,
    int offset = 0,
    int timelineLimit = 20,
  }) async {
    if (_updater == null) {
      return Future.value([]);
    }
    final update = await _updater!.loadRoomsByIDs(roomIDs, timelineLimit);
    return update?.data?.toList() ?? [];
  }

  Future<Room?> loadRoomEvents({
    required Room room,
    int limit = 20,
  }) async {
    if (_updater == null || room.timeline == null) {
      return Future.value(null);
    }

    final body = await homeServer.api.rooms.messages(
      accessToken: _updater!.user.accessToken ?? '',
      roomId: room.id.toString(),
      limit: limit,
      from: '',
      filter: {
        'lazy_load_members': true,
      },
    );

    final receivedTimeline = Timeline.fromJson(
      (body['chunk'] as List<dynamic>).cast(),
      context: room.context,
      previousBatch: body['end'],
      previousBatchSetBySync: false,
    );

    final newRoom = Room(
      context: _updater!.user.context!,
      id: room.id,
      timeline: receivedTimeline,
      memberTimeline: MemberTimeline.fromEvents([
        ...receivedTimeline,
        ...(body['state'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map((e) => RoomEvent.fromJson(e, roomId: room.id)!),
      ]),
    );

    return newRoom;
  }

  //sync data is send to updater's 'updates' stream
  Future<void> runSyncOnce({
    required SyncFilter filter
  }) async {
    if (_updater == null) {
      return Future.value(null);
    }
    final token = await _updater!.syncer.runSyncOnce(filter: filter);
    return token;
  }

  Stream<Update>? get outOneRoomUpdates => _oneRoomSyncer?.outUpdates;

  void startOneRoomSyncer(String roomID, Room? room) {
    if (_updater == null) {
      return;
    }

    if (_oneRoomSyncer != null) {
      stopOneRoomSyncer();
    }

    _oneRoomSyncer = OneRoomSyncer(_homeServer, _updater!.user.copyWith(), roomID, room);
    _oneRoomSyncer?.start();
  }

  void stopOneRoomSyncer() {
    _oneRoomSyncer?.stop();
    _oneRoomSyncer?.clear();
    _oneRoomSyncer = null;
  }
}
