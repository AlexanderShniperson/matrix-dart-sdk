// Copyright (C) 2019  Wilko Manger
// Copyright (C) 2019  Mathieu Velten
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:quiver/core.dart';

import '../event.dart';
import 'message_event.dart';
import 'redaction_event.dart';

import 'state/room_avatar_change_event.dart';
import 'state/member_change_event.dart';
import 'state/room_name_change_event.dart';
import 'state/room_creation_event.dart';
import 'state/join_rules_change_event.dart';
import 'state/power_levels_change_event.dart';
import 'state/room_upgrade_event.dart';
import 'state/topic_change_event.dart';
import 'state/canonical_alias_change_event.dart';

import 'raw_room_event.dart';

import '../../identifier.dart';

import '../../util/map.dart';

abstract class RoomEvent extends Event with Identifiable<EventId> {
  @override
  final EventId id;

  final RoomId? roomId;
  final UserId senderId;
  final DateTime? time;

  final SentState? sentState;

  final String? transactionId;

  RoomEvent(RoomEventArgs args)
      : id = args.id,
        roomId = args.roomId,
        senderId = args.senderId,
        time = args.time,
        sentState = args.sentState,
        transactionId = args.transactionId;

  @override
  bool operator ==(dynamic other) =>
      other is RoomEvent &&
      super == other &&
      roomId == other.roomId &&
      senderId == other.senderId &&
      time == other.time &&
      transactionId == other.transactionId;

  @override
  int get hashCode => hashObjects([
        super.hashCode,
        roomId,
        senderId,
        time,
        transactionId,
      ]);

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'event_id': id.toJson(),
      'sender': senderId.toString(),
      'origin_server_ts': time?.millisecondsSinceEpoch,
      'unsigned': transactionId != null ? {'transaction_id': transactionId} : {}
    });

  /// Create event from the given [json].
  static RoomEvent? fromJson(Map<String, dynamic> json, {RoomId? roomId}) {
    final type = Event.typeOf(json['type']);

    if (!json.containsKey('event_id') || json["event_id"] == null) {
      return null;
    }

    final args = RoomEventArgs.fromJson(json).copyWith(
      roomId: roomId,
    );

    RoomEvent? event;

    // Only process state events if a state_key is present
    final stateKey = json['state_key'];
    if (stateKey != null) {
      final prevContent = json.get(['unsigned', 'prev_content']);

      switch (type) {
        case RoomNameChangeEvent:
          event = RoomNameChangeEvent(
            args,
            content: RoomNameChange.fromJson(json['content']),
            previousContent: RoomNameChange.fromJson(prevContent),
          );
          break;
        case RoomAvatarChangeEvent:
          event = RoomAvatarChangeEvent(
            args,
            content: RoomAvatarChange.fromJson(json['content']),
            previousContent: RoomAvatarChange.fromJson(prevContent),
          );
          break;
        case MemberChangeEvent:
          event = MemberChangeEvent(
            args,
            content: MemberChange.fromJson(json['content']),
            previousContent: MemberChange.fromJson(prevContent),
            stateKey: stateKey,
          );
          break;
        case RoomCreationEvent:
          event = RoomCreationEvent(
            args,
            content: RoomCreation.fromJson(json['content']),
            previousContent: RoomCreation.fromJson(prevContent),
          );
          break;
        case RoomUpgradeEvent:
          event = RoomUpgradeEvent(
            args,
            content: RoomUpgrade.fromJson(json['content']),
            previousContent: RoomUpgrade.fromJson(prevContent),
          );
          break;
        case TopicChangeEvent:
          event = TopicChangeEvent(
            args,
            content: TopicChange.fromJson(json['content']),
            previousContent: TopicChange.fromJson(prevContent),
          );
          break;
        case PowerLevelsChangeEvent:
          event = PowerLevelsChangeEvent.instance(
            args,
            content: PowerLevelsChange.fromJson(json['content']),
            previousContent: PowerLevelsChange.fromJson(prevContent),
          );
          break;
        case JoinRulesChangeEvent:
          event = JoinRulesChangeEvent(
            args,
            content: JoinRules.fromJson(json['content']),
            previousContent: JoinRules.fromJson(prevContent),
          );
          break;
        case CanonicalAliasChangeEvent:
          event = CanonicalAliasChangeEvent(
            args,
            content: CanonicalAliasChange.fromJson(json['content']),
            previousContent: CanonicalAliasChange.fromJson(prevContent),
          );
          break;
        default:
          event = RawStateEvent.fromJson(args, json);
          break;
      }
    } else {
      switch (type) {
        case MessageEvent:
          event = MessageEvent.instance(
            args,
            content: MessageEventContent.fromJson(json['content']),
          );
          break;
        case RedactionEvent:
          event = RedactionEvent.fromJson(args, json);
          break;
        default:
          event = RawRoomEvent.fromJson(args, json);
          break;
      }
    }

    if (event != null &&
        json.containsKey('unsigned') &&
        json['unsigned']?.containsKey('redacted_because') == true) {
      final redactedBecause = json['unsigned']['redacted_because'];
      if (redactedBecause != null) {
        final redaction = RedactionEvent.fromJson(
          args.merge(RoomEventArgs.fromJson(redactedBecause)),
          redactedBecause,
        );

        final redacted = RedactedEvent.fromRedaction(
          redaction: redaction,
          original: event,
        );

        event = redacted;
      }
    }

    return event;
  }

  /// [type] and [isState] must not be null if the [content] is a
  /// [RawEventContent].
  static RoomEvent? fromContent(
    EventContent content,
    RoomEventArgs args, {
    String type = '',
    bool isState = false,
  }) {
    if (content is TextMessage) {
      return TextMessageEvent(args, content: content);
    } else if (content is ImageMessage) {
      return ImageMessageEvent(args, content: content);
    } else if (content is AudioMessage) {
      return AudioMessageEvent(args, content: content);
    } else if (content is TopicChange) {
      return TopicChangeEvent(args, content: content);
    } else if (content is RoomNameChange) {
      return RoomNameChangeEvent(args, content: content);
    } else if (content is RoomAvatarChangeEvent) {
      return RoomAvatarChangeEvent(args,
          content: (content as RoomAvatarChangeEvent).content);
    } else if (content is RoomUpgrade) {
      return RoomUpgradeEvent(args, content: content);
    } else if (content is PowerLevelsChange) {
      return PowerLevelsChangeEvent.instance(args, content: content);
    } else if (content is RoomCreation) {
      return RoomCreationEvent(args, content: content);
      // TODO: Handle MemberChangeEvent
    } else {
      return isState
          ? RawStateEvent(args, type: type, content: content as RawEventContent)
          : RawRoomEvent(args, type: type, content: content as RawEventContent);
    }
  }

  /// Returns true if the given [type] is a [StateEvent].
  static bool isState(Type type) {
    return [
      MemberChangeEvent,
      RedactionEvent,
      RoomAvatarChangeEvent,
      RoomNameChangeEvent,
      RoomCreationEvent,
      RoomUpgradeEvent,
      TopicChangeEvent,
      PowerLevelsChangeEvent,
      RawStateEvent,
    ].contains(type);
  }
}

class RoomEventArgs {
  final EventId id;
  final RoomId? roomId;
  final UserId senderId;
  final DateTime? time;
  final SentState? sentState;
  final String? transactionId;

  RoomEventArgs({
    required this.id,
    this.roomId,
    required this.senderId,
    this.time,
    this.transactionId,
    this.sentState,
  });

  factory RoomEventArgs.fromEvent(RoomEvent event) {
    return RoomEventArgs(
      id: event.id,
      roomId: event.roomId,
      senderId: event.senderId,
      time: event.time,
      transactionId: event.transactionId,
      sentState: event.sentState,
    );
  }

  factory RoomEventArgs.fromJson(Map<String, dynamic> json) {
    var id = json['event_id'];

    if (id != null) {
      id = EventId(id);
    }

    var senderId = json['sender'];
    if (senderId != null) {
      senderId = UserId(senderId);
    }

    late DateTime time;
    final originServerTs = json['origin_server_ts'];
    if (originServerTs != null) {
      time = DateTime.fromMillisecondsSinceEpoch(originServerTs);
    }

    String? transactionId;
    final unsignedJson = json['unsigned'];
    if (unsignedJson != null) {
      transactionId = json['unsigned']['transaction_id'];
    }

    return RoomEventArgs(
      id: id,
      senderId: senderId,
      time: time,
      transactionId: transactionId,
    );
  }

  RoomEventArgs copyWith({
    EventId? id,
    RoomId? roomId,
    UserId? senderId,
    DateTime? time,
    SentState? sentState,
    String? transactionId,
  }) {
    return RoomEventArgs(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      time: time ?? this.time,
      transactionId: transactionId ?? this.transactionId,
      sentState: sentState ?? this.sentState,
    );
  }

  RoomEventArgs merge(RoomEventArgs? other) {
    if (other == null) {
      return this;
    }

    return copyWith(
      id: other.id,
      roomId: other.roomId,
      senderId: other.senderId,
      time: other.time,
      sentState: other.sentState,
      transactionId: other.transactionId,
    );
  }
}
