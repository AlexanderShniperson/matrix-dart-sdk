// Copyright (C) 2019  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:meta/meta.dart';
import 'package:quiver/core.dart';

import '../../event.dart';
import '../room_event.dart';
import 'state_event.dart';
import '../../../identifier.dart';

class RoomCreationEvent extends StateEvent {
  static const matrixType = 'm.room.create';

  @override
  final String type = matrixType;

  @override
  final RoomCreation content;

  @override
  final RoomCreation previousContent;

  UserId get creatorId => senderId;

  RoomCreationEvent(
    RoomEventArgs args, {
    @required this.content,
    this.previousContent,
  }) : super(args, stateKey: '');
}

@immutable
class RoomCreation extends EventContent {
  /// Whether the created room is federated.
  final bool federate;

  final String roomVersion;

  final RoomId previousRoomId;
  final EventId previousRoomLastEventId;

  RoomCreation({
    @required this.federate,
    @required this.roomVersion,
    @required this.previousRoomId,
    @required this.previousRoomLastEventId,
  });

  @override
  bool operator ==(dynamic other) =>
      other is RoomCreation &&
      federate == other.federate &&
      roomVersion == other.roomVersion &&
      previousRoomId == other.previousRoomId &&
      previousRoomLastEventId == other.previousRoomLastEventId;

  @override
  int get hashCode => hashObjects([
        federate,
        roomVersion,
        previousRoomId,
        previousRoomLastEventId,
      ]);

  factory RoomCreation.fromJson(Map<String, dynamic> content) {
    if (content == null) return null;

    final federate = content['m.federate'] ?? true;
    final roomVersion = content['room_version'] ?? '1';

    dynamic previousRoomId, previousRoomEventId;

    final predecessor = content['predecessor'];
    if (predecessor != null) {
      previousRoomId = predecessor['room_id'];
      if (previousRoomId != null) {
        previousRoomId = RoomId(previousRoomId);
      }

      previousRoomEventId = predecessor['event_id'];
      if (previousRoomEventId != null) {
        previousRoomEventId = EventId(previousRoomEventId);
      }
    }

    return RoomCreation(
      federate: federate,
      roomVersion: roomVersion,
      previousRoomId: previousRoomId,
      previousRoomLastEventId: previousRoomEventId,
    );
  }

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'm.federate': federate,
      'room_version': roomVersion,
      'predecessor': {
        'room_id': previousRoomId?.toString(),
        'event_id': previousRoomLastEventId?.toString(),
      },
    });
}
