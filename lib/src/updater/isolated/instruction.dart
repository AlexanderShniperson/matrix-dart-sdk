// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:matrix_sdk/src/event/room/message_event.dart';
import 'package:matrix_sdk/src/model/instruction.dart';
import 'package:matrix_sdk/src/model/request_update.dart';

import '../../event/ephemeral/ephemeral.dart';
import '../../event/event.dart';
import '../../room/room.dart';
import '../../room/rooms.dart';
import '../../room/member/member_timeline.dart';
import '../../room/timeline.dart';
import '../../model/models.dart';
import '../../model/sync_filter.dart';

class StartSyncInstruction extends Instruction<void> {
  @override
  bool get expectsReturnValue => false;

  final Duration maxRetryAfter;
  final int timelineLimit;

  StartSyncInstruction(
    this.maxRetryAfter,
    this.timelineLimit,
  );
}

class StopSyncInstruction extends Instruction<void> {}

class GetRoomIDsInstruction extends Instruction<List<String?>> {}

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
  final Room? room;

  @override
  final bool basedOnUpdate = true;

  LoadRoomEventsInstruction(this.roomId, this.count, this.room);
}

class LoadMembersInstruction extends RequestInstruction<MemberTimeline> {
  final RoomId? roomId;
  final int count;
  final Room? room;

  LoadMembersInstruction(this.roomId, this.count, this.room);
}

class LoadRoomsByIDsInstruction extends RequestInstruction<Rooms> {
  final List<RoomId> roomIds;
  final int timelineLimit;

  LoadRoomsByIDsInstruction(this.roomIds, this.timelineLimit);
}

class LoadRoomsInstruction extends RequestInstruction<Rooms> {
  final int timelineLimit;
  final int limit;
  final int offset;

  LoadRoomsInstruction(this.limit, this.offset, this.timelineLimit);
}

class LogoutInstruction extends RequestInstruction<MyUser> {}

class MarkReadInstruction extends RequestInstruction<ReadReceipts> {
  final RoomId roomId;
  final EventId until;
  final bool receipt;
  final Room? room;

  // ignore: avoid_positional_boolean_parameters
  MarkReadInstruction(this.roomId, this.until, this.receipt, this.room);

  @override
  final bool basedOnUpdate = true;
}

class SendInstruction extends RequestInstruction<Timeline> {
  final RoomId roomId;
  final EventContent content;
  final String? transactionId;
  final String stateKey;
  final String type;
  final Room? room;

  SendInstruction(
    this.roomId,
    this.content,
    this.transactionId,
    this.stateKey,
    this.type,
    this.room,
  );
}

class EditTextEventInstruction extends RequestInstruction<Timeline> {
  final RoomId roomId;
  final TextMessageEvent event;
  final String? transactionId;
  final String newContent;
  final Room? room;

  EditTextEventInstruction(
    this.roomId,
    this.event,
    this.newContent,
    this.transactionId, {
    this.room,
  });

  @override
  final bool basedOnUpdate = true;
}

class DeleteEventInstruction extends RequestInstruction<Timeline> {
  final RoomId roomId;
  final EventId eventId;
  final String? transactionId;
  final String? reason;
  final Room? room;

  DeleteEventInstruction(
      this.roomId, this.eventId, this.transactionId, this.reason, this.room);

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

class RunSyncOnceInstruction extends RequestInstruction<MyUser> {
  final SyncFilter filter;

  RunSyncOnceInstruction(this.filter);

  @override
  final bool basedOnUpdate = true;
}
