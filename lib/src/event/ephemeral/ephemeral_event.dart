// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import '../../identifier.dart';
import '../event.dart';

import 'typing_event.dart';
import 'receipt_event.dart';

abstract class EphemeralEvent extends Event {
  final RoomId roomId;

  EphemeralEvent(this.roomId);

  factory EphemeralEvent.fromJson(Map<String, dynamic> json, {RoomId roomId}) {
    roomId ??= RoomId(json['room_id']);

    switch (json['type']) {
      case 'm.typing':
        return TypingEvent(
          roomId: roomId,
          content: Typers.fromJson(json['content']),
        );
      case 'm.receipt':
        return ReceiptEvent(
          roomId: roomId,
          content: Receipts.fromJson(json['content']),
        );
      default:
        // TODO: RawEphemeralEvent
        return null;
    }
  }

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'room_id': roomId?.toString(),
    });
}
