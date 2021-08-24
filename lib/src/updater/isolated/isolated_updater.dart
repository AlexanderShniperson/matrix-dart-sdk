// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'dart:isolate';

import 'package:matrix_sdk/src/event/room/message_event.dart';
import 'package:matrix_sdk/src/model/api_call_statistics.dart';
import 'package:matrix_sdk/src/model/instruction.dart';
import 'package:matrix_sdk/src/model/minimized_update.dart';
import 'package:matrix_sdk/src/model/request_update.dart';
import 'package:matrix_sdk/src/model/update.dart';

import '../../event/ephemeral/ephemeral.dart';
import '../../event/event.dart';
import '../../homeserver.dart';
import '../../model/identifier.dart';
import '../../room/member/member_timeline.dart';
import '../../model/my_user.dart';
import '../../room/room.dart';
import '../../room/rooms.dart';
import '../../store/store.dart';
import '../../room/timeline.dart';
import '../../model/error_with_stacktrace.dart';

import '../updater.dart';
import 'instruction.dart';
import 'isolate_runner.dart';

/// Manages updates to [MyUser] in a different [Isolate].
class IsolatedUpdater implements Updater {
  static Future<IsolatedUpdater> create(
    MyUser myUser,
    Homeserver homeServer,
    StoreLocation storeLocation, {
    bool saveMyUserToStore = false,
  }) async {
    final updater = IsolatedUpdater._(
      myUser,
      homeServer,
      storeLocation,
      saveMyUserToStore: saveMyUserToStore,
    );

    await updater._initialized;

    return updater;
  }

  IsolatedUpdater._(
    this._user,
    this._homeServer,
    StoreLocation storeLocation, {
    bool saveMyUserToStore = false,
  }) {
    Updater.register(_user.id, this);

    _messageStream.listen((message) async {
      if (message is MinimizedUpdate) {
        final minimizedUpdate = message;
        _user = _user.merge(minimizedUpdate.delta);

        final update = minimizedUpdate.deminimize(_user);

        if (update is RequestUpdate && update.basedOnUpdate) {
          _requestUpdatesBasedOnOthers.add(update);
        } else {
          _controller.add(update);
        }

        return;
      }

      if (message is SendPort) {
        _sendPort = message;

        _sendPort?.send(
          UpdaterArgs(
            myUser: _user,
            homeserverUrl: _homeServer.url,
            storeLocation: storeLocation,
            saveMyUserToStore: saveMyUserToStore,
          ),
        );
      }

      if (message is IsolateInitialized) {
        _initializedCompleter.complete();
      }

      if (message is ApiCallStatistics) {
        _apiCallStatsSubject.add(message);
      }

      if (message is ErrorWithStackTraceString) {
        _errorSubject.add(message);
      }
    });

    Isolate.spawn(IsolateRunner.run, _receivePort.sendPort);
  }

  SendPort? _sendPort;

  @override
  bool get isReady => _sendPort != null;

  final _receivePort = ReceivePort();

  late final Stream<dynamic> __messageStream = _receivePort.asBroadcastStream();
  Stream<dynamic> get _messageStream => __messageStream;

  final _errorSubject = StreamController<ErrorWithStackTraceString>.broadcast();
  @override
  Stream<ErrorWithStackTraceString> get outError => _errorSubject.stream;

  // ignore: close_sinks
  final _apiCallStatsSubject = StreamController<ApiCallStatistics>.broadcast();
  @override
  Stream<ApiCallStatistics> get outApiCallStatistics =>
      _apiCallStatsSubject.stream;

  final _requestUpdatesBasedOnOthers =
      StreamController<RequestUpdate>.broadcast();

  final _initializedCompleter = Completer<void>();
  Future<void> get _initialized => _initializedCompleter.future;

  MyUser _user;

  @override
  MyUser get user => _user;

  final Homeserver _homeServer;

  @override
  Homeserver get homeServer => _homeServer;

  late final IsolatedSyncer _syncer = IsolatedSyncer(this);

  @override
  IsolatedSyncer get syncer => _syncer;

  // ignore: close_sinks
  late final StreamController<Update> __controller =
      StreamController<Update>.broadcast();
  StreamController<Update> get _controller => __controller;

  @override
  Stream<Update> get updates => _controller.stream;

  /// Sends an instruction to the isolate, possibly with a return value.
  Future<T?> _execute<T>(Instruction<T> instruction) async {
    _sendPort?.send(instruction);

    if (instruction.expectsReturnValue) {
      final stream = instruction is RequestInstruction
          ? (instruction as RequestInstruction).basedOnUpdate
              ? _requestUpdatesBasedOnOthers.stream
              : updates
          : _messageStream;

      return await stream.firstWhere(
        (event) => event is T?,
      ) as T?;
    }

    return null;
  }

  Stream<T> _executeStream<T>(
    Instruction<T> instruction, {
    required updateCount,
  }) {
    _sendPort?.send(instruction);

    final stream = instruction is RequestInstruction
        ? (instruction as RequestInstruction).basedOnUpdate
            ? _requestUpdatesBasedOnOthers.stream
            : updates
        : _messageStream;

    return stream
        .where((msg) => msg is T)
        .map((msg) => msg as T)
        .take(updateCount);
  }

  @override
  Future<RequestUpdate<MemberTimeline>?> kick(
    UserId id, {
    RoomId? from,
  }) =>
      _execute(KickInstruction(id, from));

  @override
  Future<RequestUpdate<Timeline>?> loadRoomEvents({
    RoomId? roomId,
    int count = 20,
  }) =>
      _execute(LoadRoomEventsInstruction(roomId, count));

  @override
  Future<RequestUpdate<MemberTimeline>?> loadMembers({
    RoomId? roomId,
    int count = 10,
  }) =>
      _execute(LoadMembersInstruction(roomId, count));

  @override
  Future<RequestUpdate<Rooms>?> loadRooms(
    Iterable<RoomId> roomIds,
    int timelineLimit,
  ) =>
      _execute(LoadRoomsInstruction(roomIds.toList(), timelineLimit));

  @override
  Future<RequestUpdate<MyUser>?> logout() => _execute(LogoutInstruction());

  @override
  Future<RequestUpdate<ReadReceipts>?> markRead({
    required RoomId roomId,
    required EventId until,
    bool receipt = true,
  }) =>
      _execute(MarkReadInstruction(roomId, until, receipt));

  @override
  Stream<RequestUpdate<Timeline>?> send(
    RoomId roomId,
    EventContent content, {
    Room? room,
    String? transactionId,
    String stateKey = '',
    String type = '',
  }) =>
      _executeStream(
        SendInstruction(
          roomId,
          content,
          transactionId,
          stateKey,
          type,
          room,
        ),
        // 2 updates are sent, one for local echo and one for being sent.
        updateCount: 2,
      );

  @override
  Future<RequestUpdate<Ephemeral>?> setIsTyping({
    required RoomId roomId,
    bool isTyping = false,
    Duration timeout = const Duration(seconds: 30),
  }) =>
      _execute(SetIsTypingInstruction(roomId, isTyping, timeout));

  @override
  Future<RequestUpdate<Room>?> joinRoom({
    RoomId? id,
    RoomAlias? alias,
    required Uri serverUrl,
  }) =>
      _execute(JoinRoomInstruction(id, alias, serverUrl));

  @override
  Future<RequestUpdate<Room>?> leaveRoom(RoomId id) =>
      _execute(LeaveRoomInstruction(id));

  @override
  Future<RequestUpdate<MyUser>?> setDisplayName({
    required String name,
  }) =>
      _execute(SetNameInstruction(name));

  @override
  Future<void> setPusher(Map<String, dynamic> pusher) =>
      _execute(SetPusherInstruction(pusher));

  @override
  Future<RequestUpdate<Timeline>?> edit(
    RoomId roomId,
    TextMessageEvent event,
    String newContent, {
    String? transactionId,
  }) async {
    return _execute(EditTextEventInstruction(
      roomId,
      event,
      newContent,
      transactionId,
    ));
  }

  @override
  Future<RequestUpdate<Timeline>?> delete(
    RoomId roomId,
    EventId eventId, {
    String? transactionId,
    String? reason,
  }) async {
    return _execute(
        DeleteEventInstruction(roomId, eventId, transactionId, reason));
  }

  @override
  Future<void> startSync(
      {Duration maxRetryAfter = const Duration(seconds: 30),
      int timelineLimit = 30,
      String? token}) {
    return _execute(
        StartSyncInstruction(maxRetryAfter, timelineLimit, token));
  }
}

class IsolatedSyncer implements Syncer {
  final IsolatedUpdater _updater;

  IsolatedSyncer(this._updater);

  bool _isSyncing = false;

  @override
  bool get isSyncing => _isSyncing;

  @override
  void start(
      {Duration maxRetryAfter = const Duration(seconds: 30),
      int timelineLimit = 30,
      String? syncToken}) {
    _updater._execute(
      StartSyncInstruction(maxRetryAfter, timelineLimit, syncToken),
    );
    _isSyncing = true;
  }

  @override
  Future<void> stop() async {
    await _updater._execute(StopSyncInstruction());
    _isSyncing = false;
  }
}
