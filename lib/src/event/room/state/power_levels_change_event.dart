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

class PowerLevelsChangeEvent extends StateEvent implements HasDiff {
  static const matrixType = 'm.room.power_levels';

  @override
  final String type = matrixType;

  @override
  final PowerLevelsChange? content;
  @override
  final PowerLevelsChange? previousContent;

  @override
  final PowerLevelsChangeDiff diff;

  PowerLevelsChangeEvent._(
    RoomEventArgs args,
    this.content,
    this.previousContent,
    this.diff,
  ) : super(args, stateKey: '');

  static PowerLevelsChangeEvent? instance(
    RoomEventArgs args, {
    PowerLevelsChange? content,
    PowerLevelsChange? previousContent,
  }) {
    final diff = PowerLevelsChangeDiff(previousContent, content);
    final changes = diff.changes;

    // If there's only 1 change, it's a specific change event
    if (changes.length == 1) {
      final change = changes.first;

      if (change == diff.banLevel) {
        return BanLevelChangeEvent._(args, content, previousContent, diff);
      } else if (change == diff.inviteLevel) {
        return InviteLevelChangeEvent._(args, content, previousContent, diff);
      } else if (change == diff.kickLevel) {
        return KickLevelChangeEvent._(args, content, previousContent, diff);
      } else if (change == diff.redactLevel) {
        return RedactLevelChangeEvent._(args, content, previousContent, diff);
      } else if (change == diff.stateEventsDefaultLevel) {
        return StateEventsDefaultLevelChangeEvent._(
          args,
          content,
          previousContent,
          diff,
        );
      } else if (change == diff.eventsDefaultLevel) {
        return EventsDefaultLevelChangeEvent._(
          args,
          content,
          previousContent,
          diff,
        );
      } else if (change.runtimeType == diff.eventLevels.runtimeType &&
          diff.eventLevels?.values.whereType<Edited>().length == 1) {
        return EventLevelChangeEvent._(args, content, previousContent, diff);
      } else if (change == diff.userDefaultLevel) {
        return UserDefaultLevelChangeEvent._(
          args,
          content,
          previousContent,
          diff,
        );
        // Just check the type for maps
      } else if (change.runtimeType == diff.userLevels.runtimeType &&
          diff.userLevels?.values.whereType<Edited>().length == 1) {
        return UserLevelChangeEvent._(args, content, previousContent, diff);
      } else if (change == diff.roomNotificationLevel) {
        return RoomNotificationLevelChangeEvent._(
          args,
          content,
          previousContent,
          diff,
        );
      } else {
        return PowerLevelsChangeEvent._(args, content, previousContent, diff);
      }
    } else {
      return PowerLevelsChangeEvent._(args, content, previousContent, diff);
    }
  }
}

@immutable
class PowerLevelsChange extends EventContent {
  final int banLevel;
  final int inviteLevel;
  final int kickLevel;
  final int redactLevel;

  final int stateEventsDefaultLevel;
  final int eventsDefaultLevel;
  final Map<Type, int>? eventLevels;

  final int userDefaultLevel;
  final Map<UserId, int>? userLevels;

  final int roomNotificationLevel;

  PowerLevelsChange({
    this.banLevel = 50,
    this.inviteLevel = 50,
    this.kickLevel = 50,
    this.redactLevel = 50,
    this.stateEventsDefaultLevel = 50,
    this.eventsDefaultLevel = 0,
    this.eventLevels,
    this.userDefaultLevel = 0,
    this.userLevels,
    this.roomNotificationLevel = 50,
  });

  @override
  bool operator ==(dynamic other) =>
      other is PowerLevelsChange &&
      banLevel == other.banLevel &&
      inviteLevel == other.inviteLevel &&
      kickLevel == other.kickLevel &&
      redactLevel == other.redactLevel &&
      stateEventsDefaultLevel == other.stateEventsDefaultLevel &&
      eventsDefaultLevel == other.eventsDefaultLevel &&
      eventLevels == other.eventLevels &&
      userLevels == other.userLevels;

  @override
  int get hashCode => hashObjects([
        banLevel,
        inviteLevel,
        kickLevel,
        redactLevel,
        stateEventsDefaultLevel,
        eventsDefaultLevel,
        eventLevels,
        userLevels,
        roomNotificationLevel,
      ]);

  static PowerLevelsChange? fromJson(Map<String, dynamic>? content) {
    if (content == null) {
      return null;
    }

    final int ban = content['ban'] ?? 50;
    final int invite = content['invite'] ?? 50;
    final int kick = content['kick'] ?? 50;
    final int redact = content['redact'] ?? 50;

    final int eventsDefault = content['events_default'] ?? 0;
    final jsonEvents = content['events'];

    Map<Type, int>? events;

    if (jsonEvents != null) {
      jsonEvents.removeWhere((type, powerLevel) => Event.typeOf(type) == null);

      events = jsonEvents?.map((eventType, powerLevel) {
        powerLevel = powerLevel is String ? int.parse(powerLevel) : powerLevel;
        return MapEntry<Type, int>(Event.typeOf(eventType)!, powerLevel);
      })?.cast<Type, int>();
    }

    final int stateDefault = content['state_default'] ?? 50;

    final int userDefault = content['users_default'] ?? 0;
    final Map<UserId, int>? users = content['users'].map((userId, powerLevel) {
      powerLevel = powerLevel is String ? int.parse(powerLevel) : powerLevel;
      return MapEntry(UserId(userId), powerLevel);
    }).cast<UserId, int>();

    final int roomNotifications = content.containsKey('notifications')
        ? content['notifications']['room']?.round() ?? 50
        : 50;

    return PowerLevelsChange(
      banLevel: ban,
      inviteLevel: invite,
      kickLevel: kick,
      redactLevel: redact,
      stateEventsDefaultLevel: stateDefault,
      eventsDefaultLevel: eventsDefault,
      eventLevels: events ?? {},
      userDefaultLevel: userDefault,
      userLevels: users ?? {},
      roomNotificationLevel: roomNotifications,
    );
  }

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'ban': banLevel,
      'invite': inviteLevel,
      'kick': kickLevel,
      'redact': redactLevel,
      'state_default': stateEventsDefaultLevel,
      'events_default': eventsDefaultLevel,
      'events': eventLevels
          ?.map((type, power) => MapEntry(Event.matrixTypeOf(type), power)),
      'users_default': userDefaultLevel,
      'users':
          userLevels?.map((userId, power) => MapEntry(userId.toString(), power)),
      'notifications': {
        'room': roomNotificationLevel,
      },
    });

  PowerLevelsChange copyWith({
    int? banLevel,
    int? inviteLevel,
    int? kickLevel,
    int? redactLevel,
    int? stateEventsDefaultLevel,
    int? eventsDefaultLevel,
    Map<Type, int>? eventLevels,
    int? userDefaultLevel,
    Map<UserId, int>? userLevels,
    int? roomNotificationLevel,
  }) {
    return PowerLevelsChange(
      banLevel: banLevel ?? this.banLevel,
      inviteLevel: inviteLevel ?? this.inviteLevel,
      kickLevel: kickLevel ?? this.kickLevel,
      redactLevel: redactLevel ?? this.redactLevel,
      stateEventsDefaultLevel:
          stateEventsDefaultLevel ?? this.stateEventsDefaultLevel,
      eventsDefaultLevel: eventsDefaultLevel ?? this.eventsDefaultLevel,
      eventLevels: eventLevels ?? this.eventLevels,
      userDefaultLevel: userDefaultLevel ?? this.userDefaultLevel,
      userLevels: userLevels ?? this.userLevels,
      roomNotificationLevel:
          roomNotificationLevel ?? this.roomNotificationLevel,
    );
  }
}

class PowerLevelsChangeDiff extends Diff {
  final PowerLevelsChange? _previous;
  final PowerLevelsChange? _current;

  @override
  List get props => [
        banLevel,
        inviteLevel,
        kickLevel,
        redactLevel,
        stateEventsDefaultLevel,
        eventsDefaultLevel,
        eventLevels,
        userDefaultLevel,
        userLevels,
        roomNotificationLevel,
      ];

  PowerLevelsChangeDiff(this._previous, this._current);

  Change<int> get banLevel => Change(_previous?.banLevel, _current?.banLevel);

  Change<int> get inviteLevel =>
      Change(_previous?.inviteLevel, _current?.inviteLevel);

  Change<int> get kickLevel =>
      Change(_previous?.kickLevel, _current?.kickLevel);

  Change<int> get redactLevel =>
      Change(_previous?.redactLevel, _current?.redactLevel);

  Change<int> get stateEventsDefaultLevel => Change(
        _previous?.stateEventsDefaultLevel,
        _current?.stateEventsDefaultLevel,
      );

  Change<int> get eventsDefaultLevel =>
      Change(_previous?.eventsDefaultLevel, _current?.eventsDefaultLevel);

  Map<Type, Change<int>>? get eventLevels =>
      Change.map(_previous?.eventLevels, _current?.eventLevels)
          ?.toEdited(defaultValue: _current?.eventsDefaultLevel);

  Change<int> get userDefaultLevel =>
      Change(_previous?.userDefaultLevel, _current?.userDefaultLevel);

  Map<UserId, Change<int>>? get userLevels =>
      Change.map(_previous?.userLevels, _current?.userLevels)
          ?.toEdited(defaultValue: _current?.userDefaultLevel);

  Change<int> get roomNotificationLevel =>
      Change(_previous?.roomNotificationLevel, _current?.roomNotificationLevel);
}

extension _ChangeMapExtension<K, V> on Map<K, Change<V>> {
  /// Handle removals and additions as changes to or from a [defaultValue].
  Map<K, Change<V>> toEdited({V? defaultValue}) {
    return map((key, change) => change is Removed
        ? MapEntry(key, Edited(change.value, defaultValue))
        : change is Added
            ? MapEntry(key, Edited(defaultValue, change.value))
            : MapEntry(key, change));
  }
}

class BanLevelChangeEvent extends PowerLevelsChangeEvent {
  Change<int>? get change => diff.banLevel;

  BanLevelChangeEvent._(
    RoomEventArgs args,
    PowerLevelsChange? content,
    PowerLevelsChange? previousContent,
    PowerLevelsChangeDiff diff,
  ) : super._(args, content, previousContent, diff);
}

class InviteLevelChangeEvent extends PowerLevelsChangeEvent {
  Change<int> get change => diff.inviteLevel;

  InviteLevelChangeEvent._(
    RoomEventArgs args,
    PowerLevelsChange? content,
    PowerLevelsChange? previousContent,
    PowerLevelsChangeDiff diff,
  ) : super._(args, content, previousContent, diff);
}

class KickLevelChangeEvent extends PowerLevelsChangeEvent {
  Change<int> get change => diff.kickLevel;

  KickLevelChangeEvent._(
    RoomEventArgs args,
    PowerLevelsChange? content,
    PowerLevelsChange? previousContent,
    PowerLevelsChangeDiff diff,
  ) : super._(args, content, previousContent, diff);
}

class RedactLevelChangeEvent extends PowerLevelsChangeEvent {
  Change<int> get change => diff.redactLevel;

  RedactLevelChangeEvent._(
    RoomEventArgs args,
    PowerLevelsChange? content,
    PowerLevelsChange? previousContent,
    PowerLevelsChangeDiff diff,
  ) : super._(args, content, previousContent, diff);
}

class StateEventsDefaultLevelChangeEvent extends PowerLevelsChangeEvent {
  Change<int> get change => diff.stateEventsDefaultLevel;

  StateEventsDefaultLevelChangeEvent._(
    RoomEventArgs args,
    PowerLevelsChange? content,
    PowerLevelsChange? previousContent,
    PowerLevelsChangeDiff diff,
  ) : super._(args, content, previousContent, diff);
}

class EventsDefaultLevelChangeEvent extends PowerLevelsChangeEvent {
  Change<int> get change => diff.eventsDefaultLevel;

  EventsDefaultLevelChangeEvent._(
    RoomEventArgs args,
    PowerLevelsChange? content,
    PowerLevelsChange? previousContent,
    PowerLevelsChangeDiff diff,
  ) : super._(args, content, previousContent, diff);
}

class EventLevelChangeEvent extends PowerLevelsChangeEvent {
  EventLevelChange? get change => diff.eventLevels?.entries
      .where((e) => e.value is Edited<int>)
      .map((e) => EventLevelChange._(e.key, e.value as Edited<int>))
      .first;

  EventLevelChangeEvent._(
    RoomEventArgs args,
    PowerLevelsChange? content,
    PowerLevelsChange? previousContent,
    PowerLevelsChangeDiff diff,
  ) : super._(args, content, previousContent, diff);
}

class EventLevelChange extends Edited<int> {
  final Type type;

  EventLevelChange._(this.type, Edited<int> original)
      : super(original.previousValue, original.value);
}

class UserDefaultLevelChangeEvent extends PowerLevelsChangeEvent {
  Change<int> get change => diff.userDefaultLevel;

  UserDefaultLevelChangeEvent._(
    RoomEventArgs args,
    PowerLevelsChange? content,
    PowerLevelsChange? previousContent,
    PowerLevelsChangeDiff diff,
  ) : super._(args, content, previousContent, diff);
}

class UserLevelChangeEvent extends PowerLevelsChangeEvent {
  UserLevelChange? get change => diff.userLevels?.entries
      .where((e) => e.value is Edited<int>)
      .map((e) => UserLevelChange._(e.key, e.value as Edited<int>))
      .first;

  UserLevelChangeEvent._(
    RoomEventArgs args,
    PowerLevelsChange? content,
    PowerLevelsChange? previousContent,
    PowerLevelsChangeDiff diff,
  ) : super._(args, content, previousContent, diff);
}

class UserLevelChange extends Edited<int> {
  final UserId userId;

  UserLevelChange._(this.userId, Edited<int> original)
      : super(original.previousValue, original.value);
}

class RoomNotificationLevelChangeEvent extends PowerLevelsChangeEvent {
  Change<int> get change => diff.roomNotificationLevel;

  RoomNotificationLevelChangeEvent._(
    RoomEventArgs args,
    PowerLevelsChange? content,
    PowerLevelsChange? previousContent,
    PowerLevelsChangeDiff diff,
  ) : super._(args, content, previousContent, diff);
}
