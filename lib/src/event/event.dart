// Copyright (C) 2019  Wilko Manger
// Copyright (C) 2019  Mathieu Velten
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:meta/meta.dart';
import 'package:quiver/core.dart';

import 'room/message_event.dart';

import 'room/redaction_event.dart';
import 'room/state/join_rules_change_event.dart';
import 'room/state/member_change_event.dart';
import 'room/state/power_levels_change_event.dart';
import 'room/state/room_avatar_change_event.dart';
import 'room/state/room_creation_event.dart';
import 'room/state/room_name_change_event.dart';
import 'room/state/room_upgrade_event.dart';
import 'room/state/topic_change_event.dart';
import 'room/state/canonical_alias_change_event.dart';

import 'ephemeral/receipt_event.dart';
import 'ephemeral/typing_event.dart';

@immutable
abstract class Event {
  String get type;

  EventContent get content;

  Event();

  @override
  bool operator ==(dynamic other) =>
      other is Event && type == other.type && content == other.content;

  @override
  int get hashCode => hashObjects([type, content]);

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'content': content?.toJson(),
    };
  }

  @override
  String toString() => toJson().toString();

  // Matrix type handling
  static const Map<Type, String> _matrixTypes = {
    MessageEvent: MessageEvent.matrixType,
    MemberChangeEvent: MemberChangeEvent.matrixType,
    RedactionEvent: RedactionEvent.matrixType,
    RoomAvatarChangeEvent: RoomAvatarChangeEvent.matrixType,
    RoomNameChangeEvent: RoomNameChangeEvent.matrixType,
    RoomCreationEvent: RoomCreationEvent.matrixType,
    RoomUpgradeEvent: RoomUpgradeEvent.matrixType,
    TopicChangeEvent: TopicChangeEvent.matrixType,
    PowerLevelsChangeEvent: PowerLevelsChangeEvent.matrixType,
    JoinRulesChangeEvent: JoinRulesChangeEvent.matrixType,
    CanonicalAliasChangeEvent: CanonicalAliasChangeEvent.matrixType,
    ReceiptEvent: ReceiptEvent.matrixType,
    TypingEvent: TypingEvent.matrixType,
  };

  /// Get the type name as used by Matrix for an [Event]'s [Type], or of
  /// an [Event] instance, for example: `m.room.message`.
  static String matrixTypeOf(Type type) => _matrixTypes[type];

  /// Get the base [Type] of an [Event] associated by the given [matrixType].
  static Type typeOf(String matrixType) => _matrixTypes.entries
      .firstWhere((entry) => entry.value == matrixType, orElse: () => null)
      ?.key;
}

enum SentState { unsent, sent }

@immutable
abstract class EventContent {
  Map<String, dynamic> toJson() => {};
}
