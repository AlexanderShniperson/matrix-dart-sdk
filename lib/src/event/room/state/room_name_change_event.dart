// Copyright (C) 2019  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:meta/meta.dart';

import '../../event.dart';
import '../room_event.dart';
import 'state_event.dart';

class RoomNameChangeEvent extends StateEvent {
  static const matrixType = 'm.room.name';

  @override
  final String type = matrixType;

  @override
  final RoomNameChange content;

  @override
  final RoomNameChange previousContent;

  RoomNameChangeEvent(
    RoomEventArgs args, {
    required this.content,
    this.previousContent,
  }) : super(args, stateKey: '');
}

@immutable
class RoomNameChange extends EventContent {
  final String name;

  RoomNameChange({
    required this.name,
  });

  @override
  bool operator ==(dynamic other) =>
      other is RoomNameChange && name == other.name;

  @override
  int get hashCode => name.hashCode;

  factory RoomNameChange.fromJson(Map<String, dynamic> content) {
    if (content == null) return null;

    return RoomNameChange(name: content['name']);
  }

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'name': name,
    });
}
