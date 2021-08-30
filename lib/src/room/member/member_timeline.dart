// Copyright (C) 2019  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:collection/collection.dart';
import 'package:matrix_sdk/src/model/request_update.dart';
import '../../model/my_user.dart';
import '../../model/context.dart';
import '../../event/room/room_event.dart';
import '../../event/room/state/member_change_event.dart';
import '../../model/identifier.dart';
import 'member.dart';
import 'membership.dart';
import '../room.dart';

/// Collection of present or past user states ([Member]s) of a room.
class MemberTimeline extends DelegatingIterable<Member>
    implements Contextual<MemberTimeline> {
  @override
  final RoomContext? context;

  MemberTimeline(
    Iterable<Member> iterable, {
    this.context,
  }) : super(iterable.toList());

  MemberTimeline.empty({
    this.context,
  }) : super([]);

  /// Create a member list from events received from a homeserver.
  ///
  /// If [base] is provided, will append to [base] and return a combination
  /// of both member lists. If [base] is provided, [context] doesn't have to be.
  /// Other wise [context] must be provided.
  factory MemberTimeline.fromEvents(
    Iterable<RoomEvent>? events, {
    RoomContext? context,
  }) {
    events ??= [];

    final members = events
        .whereType<MemberChangeEvent>()
        .where((e) => e.content != null)
        .map(
          (e) => Member.fromEvent(e),
        )
        .toList(growable: false);

    return MemberTimeline(
      List.of(
        members,
        growable: false,
      ),
      context: context,
    );
  }

  /// Load more members, returning the [Update] where [MyUser] has a room
  /// with a member timeline containing more members.
  Future<RequestUpdate<MemberTimeline>?> load({
    int count = 20,
    Room? room,
  }) async {
    final result = context?.updater?.loadMembers(
      roomId: context!.roomId,
      count: count,
      room: room,
    );
    return result ?? Future.value(null);
  }

  Iterable<Member> get reversed => List.of(this).reversed;

  MemberTimeline copyWith({
    Iterable<Member>? members,
    RoomContext? context,
  }) {
    return MemberTimeline(
      members ?? this,
      context: context ?? this.context,
    );
  }

  MemberTimeline merge(MemberTimeline? other) {
    if (other == null) {
      return this;
    }

    return copyWith(
      members: List.of([
        ...where((v) => !other.any((r) => r.equals(v))),
        ...other,
      ], growable: false),
      context: other.context,
    );
  }

  @override
  MemberTimeline? delta({
    Iterable<Member>? members,
  }) {
    if (members == null) {
      return null;
    }

    return MemberTimeline(
      members,
      context: context,
    );
  }

  @override
  MemberTimeline? propertyOf(MyUser user) =>
      user.rooms?[context!.roomId]?.memberTimeline;
}

extension MembersExtension on Iterable<Member?> {
  Member? operator [](UserId id) => get(id);

  Iterable<Member> get joined =>
      where((m) => m?.membership is Joined).whereNotNull();

  /// Includes users that were kicked.
  Iterable<Member> get left =>
      where((m) => m?.membership is Left).whereNotNull();

  Iterable<Member> get invited =>
      where((m) => m?.membership is Invited).whereNotNull();

  Iterable<Member> get kicked =>
      where((m) => m?.membership is Kicked).whereNotNull();

  Iterable<Member> get banned =>
      where((m) => m?.membership is Banned).whereNotNull();

  /// Get the most recent user states.
  Iterable<Member?> get current => map((m) => m?.id).toSet().map(get);

  /// Returns a [Member] with a certain [id] at a specified time ([at]).
  ///
  /// If [at] is `null` (default), the most recent state is returned.
  Member? get(UserId? id, {DateTime? at}) {
    final members = where((member) => member?.id == id).toList(growable: false);
    // First is the oldest
    members.sort((a, b) {
      if (a?.since != null && b?.since != null) {
        return a!.since!.compareTo(b!.since!);
      } else if (a?.since != null && b?.since == null) {
        return 1;
      } else if (a?.since == null && b?.since != null) {
        return -1;
      } else {
        return 0;
      }
    });

    if (at == null) {
      return members.isNotEmpty == true ? members.last : null;
    }

    for (var i = 0; i < members.length; i++) {
      final current = members[i];
      final next = i + 1 < members.length ? members[i + 1] : null;

      if (next == null) {
        return current;
      } else {
        if (current?.since?.isBefore(at) == true &&
            next.since?.isAfter(at) == true) {
          return current;
        }
      }
    }

    return members.first;
  }
}
