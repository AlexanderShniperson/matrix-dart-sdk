// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:collection/collection.dart';

import '../../my_user.dart';
import '../../context.dart';
import 'ephemeral_event.dart';
import '../../room/room.dart';

import 'receipt_event.dart';
import 'typing_event.dart';
import '../../util/nullable_extension.dart';

class Ephemeral extends DelegatingIterable<EphemeralEvent>
    implements Contextual<Ephemeral> {
  @override
  final RoomContext? context;

  final Map<Type, EphemeralEvent> _map;

  Ephemeral(
    Iterable<EphemeralEvent> events, {
    this.context,
  })  : _map = {for (final event in events) event.runtimeType: event},
        super(events.toList());

  /// Either [context] or [roomId] is required.
  factory Ephemeral.fromJson(
    Map<String, dynamic> json, {
    RoomContext? context,
  }) {
    if (json['events'] == null) {
      return Ephemeral([]);
    }

    final ephemeralEvents = json['events'] as List<dynamic>;
    final List<EphemeralEvent> events =
        ephemeralEvents.fold(<EphemeralEvent>[], (previousValue, e) {
      final result = EphemeralEvent.fromJson(e, roomId: context?.roomId);
      if (result == null) {
        return previousValue;
      } else {
        return previousValue..add(result);
      }
    });
    return Ephemeral(
      events,
      context: context,
    );
  }

  EphemeralEvent? operator [](Type type) => _map[type];

  T get<T extends EphemeralEvent>() => this as T;

  bool containsType<T extends EphemeralEvent>() => any((e) => e is T);

  ReceiptEvent? get receiptEvent =>
      _map[ReceiptEvent] != null ? (_map[ReceiptEvent] as ReceiptEvent) : null;

  TypingEvent? get typingEvent =>
      _map[TypingEvent] != null ? (_map[TypingEvent] as TypingEvent) : null;

  Ephemeral copyWith({
    Iterable<EphemeralEvent>? events,
    RoomContext? context,
  }) {
    return Ephemeral(
      events ?? _map.values,
      context: context ?? this.context,
    );
  }

  Ephemeral? merge(Ephemeral? other) {
    if (other == null) {
      return this;
    }

    return copyWith(
      events: mergeMaps<Type, EphemeralEvent>(
        _map,
        other._map,
        value: (thisEvent, otherEvent) =>
            thisEvent is ReceiptEvent && otherEvent is ReceiptEvent
                ? thisEvent.merge(otherEvent)!
                : otherEvent,
      ).values,
      context: other.context,
    );
  }

  @override
  Ephemeral? delta({
    Iterable<EphemeralEvent>? events,
  }) {
    if (events == null) {
      return null;
    }

    return Ephemeral(
      events,
      context: context,
    );
  }

  @override
  Ephemeral? propertyOf(MyUser user) {
    return context?.roomId.let((value) => user.rooms?[value]?.ephemeral);
  }
}
