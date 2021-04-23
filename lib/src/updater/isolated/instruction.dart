// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import '../../context.dart';
import '../../event/ephemeral/ephemeral.dart';
import 'package:meta/meta.dart';

import '../../event/event.dart';
import '../../room/room.dart';
import '../../room/rooms.dart';
import '../../room/member/member_timeline.dart';
import '../../room/timeline.dart';
import '../../identifier.dart';
import '../../my_user.dart';
import '../updater.dart';

@immutable
abstract class Instruction<T> {
  /// Whether the instruction expects a return value. Can also be true if
  /// it needs to await on a Future, even though it returns nothing (void).
  bool get expectsReturnValue => true;
}

class StartSyncInstruction extends Instruction<void> {
  @override
  bool get expectsReturnValue => false;

  final Duration maxRetryAfter;

  StartSyncInstruction(this.maxRetryAfter);
}

class StopSyncInstruction extends Instruction<void> {}

abstract class RequestInstruction<T extends Contextual<T>>
    extends Instruction<RequestUpdate<T>> {
  /// Some [RequestUpdate]s are wrapped [SyncUpdate]s, we should not send
  /// those through the `updates` `Stream`.
  final bool basedOnUpdate = false;
}

class KickInstruction extends RequestInstruction<MemberTimeline> {
  final UserId id;
  final RoomId? from;

  KickInstruction(this.id, this.from);

  @override
  final bool basedOnUpdate = true;
}

class LoadRoomEventsInstruction extends RequestInstruction<Timeline> {
  final RoomId? roomId;
  final int count;

  LoadRoomEventsInstruction(this.roomId, this.count);
}

class LoadMembersInstruction extends RequestInstruction<MemberTimeline> {
  final RoomId? roomId;
  final int count;

  LoadMembersInstruction(this.roomId, this.count);
}

class LoadRoomsInstruction extends RequestInstruction<Rooms> {
  final List<RoomId> roomIds;
  final int timelineLimit;

  LoadRoomsInstruction(this.roomIds, this.timelineLimit);
}

class LogoutInstruction extends RequestInstruction<MyUser> {}

class MarkReadInstruction extends RequestInstruction<ReadReceipts> {
  final RoomId roomId;
  final EventId until;
  final bool receipt;

  // ignore: avoid_positional_boolean_parameters
  MarkReadInstruction(this.roomId, this.until, this.receipt);

  @override
  final bool basedOnUpdate = true;
}

class SendInstruction extends RequestInstruction<Timeline> {
  final RoomId roomId;
  final EventContent content;
  final String? transactionId;
  final String stateKey;
  final String type;

  SendInstruction(
    this.roomId,
    this.content,
    this.transactionId,
    this.stateKey,
    this.type,
  );
}

class DeleteEventInstruction extends RequestInstruction<Timeline> {
  final RoomId roomId;
  final EventId eventId;
  final String? transactionId;
  final String reason;

  DeleteEventInstruction(
    this.roomId,
    this.eventId,
    this.transactionId,
    this.reason,
  );

  @override
  final bool basedOnUpdate = true;
}

class SetIsTypingInstruction extends RequestInstruction<Ephemeral> {
  final RoomId? roomId;
  final bool isTyping;
  final Duration timeout;

  // ignore: avoid_positional_boolean_parameters
  SetIsTypingInstruction(this.roomId, this.isTyping, this.timeout);

  @override
  final bool basedOnUpdate = true;
}

class JoinRoomInstruction extends RequestInstruction<Room> {
  final RoomId? id;
  final RoomAlias? alias;
  final Uri serverUrl;

  JoinRoomInstruction(this.id, this.alias, this.serverUrl);

  @override
  final bool basedOnUpdate = true;
}

class LeaveRoomInstruction extends RequestInstruction<Room> {
  final RoomId id;

  LeaveRoomInstruction(this.id);

  @override
  final bool basedOnUpdate = true;
}

class SetNameInstruction extends RequestInstruction<MyUser> {
  final String name;

  SetNameInstruction(this.name);
}

class SetPusherInstruction extends RequestInstruction<MyUser> {
  final Map<String, dynamic> pusher;

  SetPusherInstruction(this.pusher);

  @override
  final bool basedOnUpdate = true;
}
