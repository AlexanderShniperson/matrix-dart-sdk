// Copyright (C) 2019  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:collection/collection.dart';
import 'package:matrix_sdk/src/model/request_update.dart';
import '../model/context.dart';
import '../homeserver.dart';
import '../model/identifier.dart';
import '../model/my_user.dart';
import 'room.dart';

class Rooms extends DelegatingIterable<Room> implements Contextual<Rooms> {
  @override
  final Context? context;

  Rooms(
    Iterable<Room> iterable, {
    this.context,
  }) : super(iterable.toList());

  Rooms.empty({
    this.context,
  }) : super([]);

  Room? operator [](RoomId id) => firstWhereOrNull((s) => s.id == id);

  bool containsWithId(RoomId id) => any((r) => r.id == id);

  /// Load more rooms, returning the [Update] where [MyUser] has more rooms.
  Future<RequestUpdate<Rooms>?> load({
    required Iterable<RoomId> roomIds,
    int timelineLimit = 10,
  }) {
    final result = context?.updater?.loadRoomsByIDs(roomIds, timelineLimit);
    return result ?? Future.value(null);
  }

  Rooms copyWith({
    Iterable<Room>? rooms,
    Context? context,
  }) {
    rooms ??= this;

    // Make sure all contexts are changed
    if (context != null && context != this.context) {
      rooms = rooms.map((r) => r.copyWith(context: context));
    }

    return Rooms(
      rooms,
      context: context ?? this.context,
    );
  }

  Rooms merge(Rooms? other) {
    if (other == null) {
      return this;
    }

    return copyWith(
      rooms: List.of([
        // Merge all rooms that are present in this as well as in other
        ...map((room) {
          Room? otherRoom;

          final otherRooms = other.where(
            (otherRoom) => otherRoom.equals(room),
          );

          if (otherRooms.isEmpty) {
            return room;
          } else if (otherRooms.length == 1) {
            otherRoom = otherRooms.first;
          } else {
            for (final anotherRoom in otherRooms) {
              otherRoom = otherRoom?.merge(anotherRoom) ?? anotherRoom;
            }
          }

          return room.merge(otherRoom!);
        }),
        // All other rooms that were not merged, they're new
        ...other.where(
          (otherRoom) => !any((room) => otherRoom.equals(room)),
        ),
      ], growable: false),
      context: other.context,
    );
  }

  @override
  Rooms? delta({Iterable<Room>? rooms}) {
    if (rooms == null) {
      return null;
    }

    return Rooms(
      rooms,
      context: context,
    );
  }

  @override
  Rooms? propertyOf(MyUser user) => user.rooms;

  /// Join a room with the given [id] or [alias].
  ///
  /// Either [id] or [alias] must not be null, and they can't be both
  /// non-null.
  ///
  /// Returns a RequestUpdate with the [Room] that has been joined.
  ///
  /// Note that this method is called `enter` because otherwise it would
  /// conflict with [Iterable.join].
  ///
  /// [through] is the server which will be used to join through. Can be
  /// left `null`.
  Future<RequestUpdate<Room>?> enter({
    RoomId? id,
    RoomAlias? alias,
    Homeserver? through,
  }) {
    assert((id != null && alias == null) || (id == null && alias != null));
    final result = context?.updater?.joinRoom(
      id: id,
      alias: alias,
      serverUrl: through?.wellKnownUrl ?? through?.url ?? Uri(),
    );
    return result ?? Future.value(null);
  }
}
