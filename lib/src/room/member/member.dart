// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:quiver/core.dart';

import '../../event/room/state/member_change_event.dart';

import '../../identifier.dart';
import '../../matrix_user.dart';

import 'membership.dart';

/// A user that's a member of a certain room.
class Member extends MatrixUser {
  /// Event this member's state is based on.
  final MemberChangeEvent event;

  @override
  UserId get id => event.subjectId;

  RoomId? get roomId => event.roomId;
  DateTime? get since => event.time;

  Membership? get membership => event.content?.membership;

  @override
  Uri? get avatarUrl => event.content?.avatarUrl;

  @override
  String get name => event.content?.displayName ?? '';

  bool get hasJoined => membership == Membership.joined;

  bool get isInvited => membership == Membership.invited;

  bool get hasLeft => membership == Membership.left;

  bool get isKicked => membership == Membership.kicked;

  bool get isBanned => membership == Membership.banned;

  bool get hasKnocked => membership == Membership.knocked;

  Member.fromEvent(this.event);

  @override
  bool operator ==(dynamic other) =>
      other is Member && super == other && event == other.event;

  @override
  int get hashCode => hashObjects([super.hashCode, event]);
}
