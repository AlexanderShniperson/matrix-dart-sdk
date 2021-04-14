// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'homeserver.dart';
import 'identifier.dart';
import 'my_user.dart';
import 'room/room.dart';
import 'updater/updater.dart';

class PublicRooms extends DelegatingIterable<RoomResult> {
  /// The server these rooms belong to.
  final Homeserver server;

  /// Note that this is an _estimation_ of the amount of total
  /// public rooms.
  ///
  /// Is `null` if [hasLoaded] is false.
  final int totalRoomsCount;

  /// Search term used to find public rooms. Can be null to get all rooms.
  final String searchTerm;

  final String nextBatch;

  /// Returns true if at least once a request has been made using [load] to
  /// get public rooms.
  final bool hasLoaded;

  /// Returns true if there's more to load.
  bool get canLoadMore => !hasLoaded || nextBatch != null;

  PublicRooms._(
    Iterable<RoomResult> iterable, {
    this.server,
    this.totalRoomsCount,
    this.searchTerm,
    this.nextBatch,
    this.hasLoaded,
  }) : super(iterable);

  PublicRooms.of(Homeserver server)
      : this._(
          [],
          server: server,
          hasLoaded: false,
        );

  factory PublicRooms._fromJson(Map<String, dynamic> json) {
    final rooms = (json['chunk'] as List<dynamic>)
        .map((r) => RoomResult.fromJson(r))
        .toList();

    return PublicRooms._(
      rooms,
      totalRoomsCount: json['total_room_count_estimate'],
      nextBatch: json['next_batch'],
    );
  }

  /// Load (more) public rooms, optionally with a [searchTerm].
  ///
  /// The [MyUser] provided will be used to authenticate on their _own_
  /// server, not the homeserver with [server].
  /// This also means that [MyUser] must be logged in.
  ///
  /// The [searchTerm] must be `null` if the `searchTerm` of this instance
  /// is already set. Create a new fresh instance if you want to search
  /// for something  else.
  ///
  /// Returns a new [PublicRooms] with possibly more rooms loaded.
  Future<PublicRooms> load({
    required MyUser as,
    int limit = 30,
    String searchTerm,
  }) async {
    assert(
      !hasLoaded || searchTerm == null || this.searchTerm == searchTerm,
    );

    final body = await as.context.homeserver.api.publicRooms(
      accessToken: as.accessToken,
      server: (server.wellKnownUrl ?? server.url).host,
      since: nextBatch,
      genericSearchTerm: searchTerm,
    );

    var newRooms = PublicRooms._fromJson(body);

    if (!hasLoaded) {
      newRooms = newRooms._copyWith(
        hasLoaded: true,
        searchTerm: searchTerm,
      );
    }

    return _merge(newRooms);
  }

  PublicRooms _copyWith({
    Iterable<RoomResult> rooms,
    Homeserver server,
    int totalRoomsCount,
    String searchTerm,
    String nextBatch,
    bool hasLoaded,
  }) {
    return PublicRooms._(
      rooms ?? this,
      server: server ?? this.server,
      totalRoomsCount: totalRoomsCount ?? this.totalRoomsCount,
      searchTerm: searchTerm ?? this.searchTerm,
      nextBatch: nextBatch ?? this.nextBatch,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }

  PublicRooms _merge(PublicRooms other) {
    if (other == null) {
      return this;
    }

    return _copyWith(
      rooms: other,
      server: other.server,
      totalRoomsCount: other.totalRoomsCount,
      searchTerm: other.searchTerm,
      nextBatch: other.nextBatch,
      hasLoaded: other.hasLoaded,
    );
  }
}

@immutable
class RoomResult with Identifiable<RoomId> {
  @override
  final RoomId id;
  final String name;
  final Uri avatarUrl;
  final String topic;
  final RoomAlias canonicalAlias;
  final Iterable<RoomAlias> aliases;
  final int joinedMembersCount;
  final bool worldReadable;
  final bool guestsCanJoin;

  RoomResult({
    this.id,
    this.name,
    this.avatarUrl,
    this.topic,
    this.canonicalAlias,
    this.aliases,
    this.joinedMembersCount,
    this.worldReadable,
    this.guestsCanJoin,
  });

  factory RoomResult.fromJson(Map<String, dynamic> json) {
    final id = RoomId(json['room_id']);

    final canonicalAlias = json['canonical_alias'] != null
        ? RoomAlias(json['canonical_alias'])
        : null;

    final aliases = json['aliases'] != null
        ? (json['aliases'] as List<dynamic>).map((alias) => RoomAlias(alias))
        : <RoomAlias>[];

    final avatarUrl =
        json['avatar_url'] != null ? Uri.parse(json['avatar_url']) : null;

    return RoomResult(
      id: id,
      name: json['name'],
      avatarUrl: avatarUrl,
      topic: json['topic'],
      canonicalAlias: canonicalAlias,
      aliases: aliases,
      joinedMembersCount: json['num_joined_members'],
      worldReadable: json['world_readable'],
      guestsCanJoin: json['guest_can_join'],
    );
  }

  Future<RequestUpdate<Room>> join({
    required MyUser as,
  }) =>
      as.rooms.enter(id: id);

  @override
  String toString() {
    return '$runtimeType'
        '(id: $id, name: $name, canonicalAlias: $canonicalAlias)';
  }
}
