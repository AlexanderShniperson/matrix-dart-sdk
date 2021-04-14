// Copyright (C) 2019  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:collection/collection.dart';

import 'package:meta/meta.dart';

import '../context.dart';
import '../event/room/room_event.dart';
import '../identifier.dart';
import 'room.dart';
import '../my_user.dart';
import '../updater/updater.dart';
import '../event/event.dart';
import '../event/room/raw_room_event.dart';

class Timeline extends DelegatingIterable<RoomEvent>
    implements Contextual<Timeline> {
  @override
  final RoomContext context;

  final String previousBatch;

  final bool previousBatchSetBySync;

  Timeline(
    Iterable<RoomEvent> iterable, {
    required this.context,
    this.previousBatch,
    this.previousBatchSetBySync,
  }) : super(
          // TODO: Assume sorted
          iterable.toList(growable: false)
            ..sort(
              (a, b) => -a.time.compareTo(b.time),
            ),
        );

  Timeline.empty({
    required this.context,
  })   : previousBatch = null,
        previousBatchSetBySync = null,
        super([]);

  /// Create a timeline from json received from a homeserver.
  ///
  /// If [context] is provided, [roomId] doesn't have to be.
  /// Otherwise [roomId] must be provided.
  factory Timeline.fromJson(
    List<Map<String, dynamic>> json, {
    required RoomContext context,
    String previousBatch,
    bool previousBatchSetBySync,
  }) {
    final events = json
        .map((e) => RoomEvent.fromJson(e, roomId: context.roomId))
        .where((e) => e != null)
        .toList(growable: false);

    return Timeline(
      List.of(
        events,
        growable: false,
      ),
      context: context,
      previousBatch: previousBatch,
      previousBatchSetBySync: previousBatchSetBySync,
    );
  }

  RoomEvent operator [](EventId id) =>
      firstWhere((s) => s.id == id, orElse: () => null);

  /// Load more events, returning the [Update] where [MyUser] has a room
  /// with a timeline containing more events.
  Future<RequestUpdate<Timeline>> load({
    int count = 20,
  }) =>
      context.updater.loadRoomEvents(
        roomId: context.roomId,
        count: count,
      );

  Iterable<RoomEvent> get reversed => List.of(this).reversed;

  Timeline copyWith({
    Iterable<RoomEvent> events,
    RoomContext context,
    String previousBatch,
    bool previousBatchSetBySync,
  }) {
    return Timeline(
      events ?? this,
      context: context ?? this.context,
      previousBatch: previousBatch ?? this.previousBatch,
      previousBatchSetBySync:
          previousBatchSetBySync ?? this.previousBatchSetBySync,
    );
  }

  Timeline merge(Timeline other) {
    if (other == null) return this;

    return copyWith(
      events: [
        ...where(
          (event) => !other.any(
            (otherEvent) =>
                otherEvent.equals(event) ||
                (event.transactionId != null &&
                    otherEvent.transactionId != null &&
                    event.transactionId == otherEvent.transactionId),
          ),
        ),
        ...other,
      ],
      context: other.context,
      previousBatch: other.previousBatch,
      previousBatchSetBySync: other.previousBatchSetBySync,
    );
  }

  @override
  Timeline delta({
    Iterable<RoomEvent> events,
    String previousBatch,
    bool previousBatchSetBySync,
  }) {
    if (events == null &&
        previousBatch == null &&
        previousBatchSetBySync == null) {
      return null;
    }

    return Timeline(
      events ?? [],
      context: context,
      previousBatch: previousBatch,
      previousBatchSetBySync: previousBatchSetBySync,
    );
  }

  @override
  Timeline propertyOf(MyUser user) => user.rooms[context.roomId]?.timeline;
}

extension TimelineExtension on Iterable<RoomEvent> {
  /// Returns [RawRoomEvent]s with the given Matrix type.
  ///
  /// **Should not be any type supported by the SDK.**
  Iterable<RawRoomEvent> withCustomType(String type) {
    assert(Event.typeOf(type) == null);

    return where((e) => e.type == type).cast();
  }

  /// Returns the first [RawRoomEvent] with the given Matrix type.
  ///
  /// **Should not be any type supported by the SDK.**
  RawRoomEvent firstWithCustomType(
    String type, {
    RawRoomEvent Function() orElse,
  }) {
    assert(Event.typeOf(type) == null);

    return firstWhere(
      (e) => e.type == type,
      orElse: orElse,
    ) as RawRoomEvent;
  }
}
