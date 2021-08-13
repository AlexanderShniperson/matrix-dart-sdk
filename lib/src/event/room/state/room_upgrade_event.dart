// Copyright (C) 2019  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:meta/meta.dart';
import 'package:quiver/core.dart';

import '../room_event.dart';
import 'state_event.dart';
import '../../../identifier.dart';

import '../../event.dart';

class RoomUpgradeEvent extends StateEvent {
  static const matrixType = 'm.room.tombstone';

  @override
  final String type = matrixType;

  @override
  final RoomUpgrade? content;

  @override
  final RoomUpgrade? previousContent;

  RoomUpgradeEvent(
    RoomEventArgs args, {
     this.content,
    this.previousContent,
  }) : super(args, stateKey: '');
}

@immutable
class RoomUpgrade extends EventContent {
  final String body;

  final RoomId replacementRoomId;

  RoomUpgrade({
    required this.body,
    required this.replacementRoomId,
  });

  @override
  bool operator ==(dynamic other) =>
      other is RoomUpgrade &&
      body == other.body &&
      replacementRoomId == other.replacementRoomId;

  @override
  int get hashCode => hashObjects([body, replacementRoomId]);

  static RoomUpgrade? fromJson(Map<String, dynamic>? content) {
    if (content == null) {
      return null;
    }

    final body = content['body'];
    var replacementRoomId = content['replacement_room'];
    if (replacementRoomId == null) {
      return null;
    }

    replacementRoomId = RoomId(replacementRoomId);

    return RoomUpgrade(
      body: body,
      replacementRoomId: replacementRoomId,
    );
  }

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'body': body,
      'replacement_room': replacementRoomId.toString(),
    });
}
