// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'dart:isolate';

import 'package:matrix_sdk/src/event/room/message_event.dart';
import 'package:meta/meta.dart';

import '../../context.dart';
import '../../event/ephemeral/ephemeral.dart';
import '../../event/event.dart';
import '../../homeserver.dart';
import '../../identifier.dart';
import '../../room/member/member_timeline.dart';
import '../../my_user.dart';
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
    Homeserver homeserver,
    StoreLocation storeLocation, {
    bool saveMyUserToStore = false,
  }) async {
    final updater = IsolatedUpdater._(
      myUser,
      homeserver,
      storeLocation,
      saveMyUserToStore: saveMyUserToStore,
    );

    await updater._initialized;

    return updater;
  }

  IsolatedUpdater._(
    this._user,
    this.homeserver,
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

        _sendPort.send(
          UpdaterArgs(
            myUser: _user,
            homeserverUrl: homeserver.url,
            storeLocation: storeLocation,
            saveMyUserToStore: saveMyUserToStore,
          ),
        );
      }

      if (message is IsolateInitialized) {
        _initializedCompleter.complete();
      }

      if (message is ErrorWithStackTraceString) {
        _errorSubject.add(message);
      }
    });

    Isolate.spawn(IsolateRunner.run, _receivePort.sendPort);
  }

  SendPort _sendPort;

  @override
  bool get isReady => _sendPort != null;

  final _receivePort = ReceivePort();

  Stream<dynamic> __messageStream;
  Stream<dynamic> get _messageStream =>
      __messageStream ??= _receivePort.asBroadcastStream();

  final _errorSubject = StreamController<ErrorWithStackTraceString>.broadcast();
  @override
  Stream<ErrorWithStackTraceString> get outError => _errorSubject.stream;

  final _requestUpdatesBasedOnOthers =
      StreamController<RequestUpdate>.broadcast();

  final _initializedCompleter = Completer<void>();
  Future<void> get _initialized => _initializedCompleter.future;

  MyUser _user;
  @override
  MyUser get user => _user;

  @override
  final Homeserver homeserver;

  IsolatedSyncer _syncer;

  @override
  IsolatedSyncer get syncer => _syncer ??= IsolatedSyncer(this);

  bool _hasListeners = false;

  // ignore: close_sinks
  StreamController<Update> __controller;
  StreamController<Update> get _controller =>
      __controller ??= StreamController<Update>.broadcast(
        onListen: () => _hasListeners = true,
      );

  @override
  Stream<Update> get updates => _controller.stream;

  /// Sends an instruction to the isolate, possibly with a return value.
  Future<T> _execute<T>(Instruction<T> instruction) async {
    _sendPort.send(instruction);

    if (instruction.expectsReturnValue) {
      final stream = instruction is RequestInstruction
          ? (instruction as RequestInstruction).basedOnUpdate
              ? _requestUpdatesBasedOnOthers.stream
              : updates
          : _messageStream;

      return (await stream.firstWhere((event) => event is T,
          orElse: () => null)) as T;
    }

    return null;
  }

  Stream<T> _executeStream<T>(
    Instruction<T> instruction, {
    @required updateCount,
  }) {
    _sendPort.send(instruction);

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
  Future<RequestUpdate<MemberTimeline>> kick(UserId id, {RoomId from}) =>
      _execute(KickInstruction(id, from));

  @override
  Future<RequestUpdate<Timeline>> loadRoomEvents({
    RoomId roomId,
    int count = 20,
  }) =>
      _execute(LoadRoomEventsInstruction(roomId, count));

  @override
  Future<RequestUpdate<MemberTimeline>> loadMembers({
    RoomId roomId,
    int count = 10,
  }) =>
      _execute(LoadMembersInstruction(roomId, count));

  @override
  Future<RequestUpdate<Rooms>> loadRooms(
    Iterable<RoomId> roomIds,
    int timelineLimit,
  ) =>
      _execute(LoadRoomsInstruction(roomIds.toList(), timelineLimit));

  @override
  Future<RequestUpdate<MyUser>> logout() => _execute(LogoutInstruction());

  @override
  Future<RequestUpdate<ReadReceipts>> markRead({
    RoomId roomId,
    EventId until,
    bool receipt = true,
  }) =>
      _execute(MarkReadInstruction(roomId, until, receipt));

  @override
  Stream<RequestUpdate<Timeline>> send(
    RoomId roomId,
    EventContent content, {
    String transactionId,
    String stateKey = '',
    String type,
  }) =>
      _executeStream(
        SendInstruction(
          roomId,
          content,
          transactionId,
          stateKey,
          type,
        ),
        // 2 updates are sent, one for local echo and one for being sent.
        updateCount: 2,
      );

  @override
  Future<RequestUpdate<Ephemeral>> setIsTyping({
    RoomId roomId,
    bool isTyping,
    Duration timeout = const Duration(seconds: 30),
  }) =>
      _execute(SetIsTypingInstruction(roomId, isTyping, timeout));

  @override
  Future<RequestUpdate<Room>> joinRoom({
    RoomId id,
    RoomAlias alias,
    Uri serverUrl,
  }) =>
      _execute(JoinRoomInstruction(id, alias, serverUrl));

  @override
  Future<RequestUpdate<Room>> leaveRoom(RoomId id) =>
      _execute(LeaveRoomInstruction(id));

  @override
  Future<RequestUpdate<MyUser>> setName({String name}) =>
      _execute(SetNameInstruction(name));

  @override
  Future<RequestUpdate<MyUser>> setPusher(Map<String, dynamic> pusher) =>
      _execute(SetPusherInstruction(pusher));

  @override
  Future<RequestUpdate<Timeline>> edit(
    RoomId roomId,
    TextMessageEvent event,
    String newContent, {
    String transactionId,
  }) async {
    return _execute(
        EditTextEventInstruction(roomId, event, newContent, transactionId));
  }

  @override
  Future<RequestUpdate<Timeline>> delete(
    RoomId roomId,
    EventId eventId, {
    String transactionId,
    String reason = 'Deleted by author',
  }) async {
    return _execute(
        DeleteEventInstruction(roomId, eventId, transactionId, reason));
  }
}

class IsolatedSyncer implements Syncer {
  final IsolatedUpdater _updater;

  IsolatedSyncer(this._updater);

  bool _isSyncing = false;

  @override
  bool get isSyncing => _isSyncing;

  @override
  void start({Duration maxRetryAfter = const Duration(seconds: 30)}) {
    _updater._execute(
      StartSyncInstruction(maxRetryAfter),
    );
    _isSyncing = true;
  }

  @override
  Future<void> stop() async {
    await _updater._execute(StopSyncInstruction());
    _isSyncing = false;
  }
}

@immutable
abstract class MinimizedUpdate<T extends Update> {
  final MyUser delta;

  MinimizedUpdate(this.delta);

  T deminimize(MyUser user);
}

class MinimizedSyncUpdate extends MinimizedUpdate<SyncUpdate> {
  MinimizedSyncUpdate({@required MyUser delta}) : super(delta);

  @override
  SyncUpdate deminimize(MyUser user) => SyncUpdate(user, delta);
}

class MinimizedRequestUpdate<T extends Contextual<T>>
    extends MinimizedUpdate<RequestUpdate<T>> {
  final T deltaData;
  final RequestType type;
  final bool basedOnUpdate;

  MinimizedRequestUpdate({
    @required MyUser delta,
    @required this.deltaData,
    @required this.type,
    @required this.basedOnUpdate,
  }) : super(delta);

  @override
  RequestUpdate<T> deminimize(MyUser user) {
    final deltaData = this.deltaData;

    return RequestUpdate<T>(
      user,
      delta,
      data: deltaData is Contextual<T> ? deltaData.propertyOf(user) : null,
      deltaData: deltaData,
      type: type,
      basedOnUpdate: basedOnUpdate,
    );
  }
}
