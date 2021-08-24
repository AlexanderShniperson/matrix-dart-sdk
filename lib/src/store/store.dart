// Copyright (C) 2019  Wilko Manger
// Copyright (C) 2019  Mathieu Velten
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:meta/meta.dart';

import '../model/context.dart';
import '../event/room/room_event.dart';
import '../model/identifier.dart';
import '../room/member/member.dart';
import '../room/room.dart';
import '../homeserver.dart';
import '../updater/updater.dart';
import '../model/my_user.dart';
import 'package:collection/collection.dart';

/// Stores all data (rooms, users, events) somewhere.
abstract class Store {
  bool get isOpen;

  void open();
  Future<void> close();

  /// Gets the currently stored [MyUser].
  ///
  /// If [Homeserver] was not provided on, it will create a new instance and
  /// associate it to the returned [MyUser] via its [Context]
  ///
  /// Returns null if there's no user stored.
  ///
  /// If [roomIds] is null (default), all rooms will be loaded, if it's not
  /// null, only the rooms with those ids will be loaded.
  ///
  /// Use [timelineLimit] to determine how many messages in the room's timeline
  /// should be loaded.
  ///
  /// The [storeLocation] is required because the [Updater] will recreate
  /// the store.
  Future<MyUser?> getMyUser(
    String userID, {
    Iterable<RoomId>? roomIds,
    int timelineLimit = 15,
    bool isolated = false,
  });

  /// Save [MyUser] and all it's data completely.
  Future<void> setMyUserDelta(MyUser myUser);

  /// If [memberIds] is not null, the states of the users with those ids will
  /// always be included, if they're in the room.
  Future<Iterable<Room>> getRooms(
    Iterable<RoomId>? roomIds, {
    Context? context,
    required int timelineLimit,
    Iterable<UserId>? memberIds,
  });

  Future<Room?> getRoom(
    RoomId id, {
    int timelineLimit = 15,
    required Context context,
    required Iterable<UserId> memberIds,
  }) =>
      getRooms(
        [id],
        timelineLimit: timelineLimit,
        context: context,
        memberIds: memberIds,
      ).then(
        (rooms) => rooms.firstWhereOrNull((r) => r.id == id),
      );

  /// Returned sorted based on [RoomEvent.time], newest first.
  ///
  /// Will also return a list of MemberChangeEvents needed to render the
  /// returned timeline events.
  ///
  /// If [fromTime] is provided, will skip all events with a time greater
  /// than [fromTime].
  ///
  /// If [memberIds] is not null, the states of those user ids will always be
  /// included.
  Future<Messages> getMessages(
    RoomId roomId, {
    int count = 20,
    DateTime? fromTime,
    Iterable<UserId>? memberIds,
  });

  Future<Iterable<RoomEvent>> getUnsentEvents();

  /// Returned sorted based on since.
  ///
  /// See [Members].
  Future<Iterable<Member>> getMembers(
    RoomId roomId, {
    int count = 20,
    DateTime? fromTime,
  });
}

/// Points to a location of a certain [Store].
///
/// Can create a [Store] instance based on the location.
@immutable
// ignore: one_member_abstracts
abstract class StoreLocation<T extends Store> {
  T create();
}

/// Combination of RoomEvents and MemberChangeEvents needed to render
/// them. Named after the API.
@immutable
class Messages {
  final Iterable<RoomEvent> events;
  final Iterable<Member> state;

  Messages(this.events, this.state);
}
