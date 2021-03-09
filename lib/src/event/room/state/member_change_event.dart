// Copyright (C) 2019  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:meta/meta.dart';
import 'package:quiver/core.dart';

import '../room_event.dart';
import 'state_event.dart';
import '../../../identifier.dart';
import '../../../util/mxc_url.dart';

import '../../../room/member/membership.dart';
import '../../event.dart';

class MemberChangeEvent extends StateEvent {
  static const matrixType = 'm.room.member';

  @override
  final String type = matrixType;

  @override
  final MemberChange content;

  @override
  final MemberChange previousContent;

  /// The [UserId] of who has joined, left, was banned, etc.
  final UserId subjectId;

  MemberChangeEvent._(
    RoomEventArgs args, {
    @required this.content,
    this.previousContent,
    @required String stateKey,
  })  : subjectId = UserId(stateKey),
        super(args, stateKey: stateKey);

  factory MemberChangeEvent(
    RoomEventArgs args, {
    @required MemberChange content,
    MemberChange previousContent,
    @required String stateKey,
  }) {
    if (content == null) {
      return MemberChangeEvent._(args, content: null, stateKey: stateKey);
    }

    // If someone else sent the leave event, it means they were kicked
    if (content.membership is Left && args.senderId != UserId(stateKey)) {
      content = content.copyWith(
        membership: Membership.kicked,
      );
    }

    if (previousContent?.membership is Joined && content.membership is Joined) {
      if (previousContent.displayName != content.displayName) {
        return DisplayNameChangeEvent._(
          args,
          content: content,
          previousContent: previousContent,
          stateKey: stateKey,
        );
      }

      if (previousContent.avatarUrl != content.avatarUrl) {
        return AvatarChangeEvent._(
          args,
          content: content,
          previousContent: previousContent,
          stateKey: stateKey,
        );
      }
    }

    if (content.membership is Joined) {
      return JoinEvent._(
        args,
        content: content,
        previousContent: previousContent,
        stateKey: stateKey,
      );
    } else if (content.membership is Kicked) {
      return KickEvent._(
        args,
        content: content,
        previousContent: previousContent,
        stateKey: stateKey,
      );
    } else if (content.membership is Left) {
      return LeaveEvent._(
        args,
        content: content,
        previousContent: previousContent,
        stateKey: stateKey,
      );
    } else if (content.membership is Banned) {
      return BanEvent._(
        args,
        content: content,
        previousContent: previousContent,
        stateKey: stateKey,
      );
    } else if (content.membership is Invited) {
      return InviteEvent._(
        args,
        content: content,
        previousContent: previousContent,
        stateKey: stateKey,
      );
    }

    throw UnsupportedError('Unknown m.room.member event');
  }
}

@immutable
class MemberChange extends EventContent {
  final bool isDirect;

  final String displayName;
  final Uri avatarUrl;

  final Membership membership;

  MemberChange({
    @required this.membership,
    @required this.displayName,
    @required this.avatarUrl,
    this.isDirect = false,
  });

  @override
  bool operator ==(dynamic other) =>
      other is MemberChange &&
      isDirect == other.isDirect &&
      displayName == other.displayName &&
      avatarUrl == other.avatarUrl &&
      membership == other.membership;

  @override
  int get hashCode => hashObjects([
        isDirect,
        displayName,
        avatarUrl,
        membership,
      ]);

  factory MemberChange.fromJson(Map<String, dynamic> content) {
    if (content == null) return null;

    var avatarUrl = content['avatar_url'];
    if (avatarUrl != null && avatarUrl is String) {
      avatarUrl = tryParseMxcUrl(avatarUrl);
    }

    final membership = Membership.parse(content['membership']);

    return MemberChange(
      membership: membership,
      displayName: content['displayname'],
      avatarUrl: avatarUrl,
      isDirect: content['is_direct'] ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'membership': membership.value,
      'displayname': displayName,
      'avatar_url': avatarUrl?.toString(),
    });

  MemberChange copyWith({
    Membership membership,
    String displayName,
    String avatarUrl,
    bool isDirect,
  }) {
    return MemberChange(
      membership: membership ?? this.membership,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isDirect: isDirect ?? this.isDirect,
    );
  }
}

class JoinEvent extends MemberChangeEvent {
  JoinEvent._(
    RoomEventArgs args, {
    @required MemberChange content,
    MemberChange previousContent,
    @required String stateKey,
  }) : super._(
          args,
          content: content,
          previousContent: previousContent,
          stateKey: stateKey,
        );
}

class LeaveEvent extends MemberChangeEvent {
  LeaveEvent._(
    RoomEventArgs args, {
    @required MemberChange content,
    MemberChange previousContent,
    @required String stateKey,
  }) : super._(
          args,
          content: content,
          previousContent: previousContent,
          stateKey: stateKey,
        );
}

class KickEvent extends LeaveEvent {
  UserId get kickerId => senderId;
  UserId get kickeeId => subjectId;

  KickEvent._(
    RoomEventArgs args, {
    @required MemberChange content,
    MemberChange previousContent,
    @required String stateKey,
  }) : super._(
          args,
          content: content,
          previousContent: previousContent,
          stateKey: stateKey,
        );
}

class BanEvent extends MemberChangeEvent {
  BanEvent._(
    RoomEventArgs args, {
    @required MemberChange content,
    MemberChange previousContent,
    @required String stateKey,
  }) : super._(
          args,
          content: content,
          previousContent: previousContent,
          stateKey: stateKey,
        );
}

// TODO: Add RoomState
class InviteEvent extends MemberChangeEvent {
  InviteEvent._(
    RoomEventArgs args, {
    @required MemberChange content,
    MemberChange previousContent,
    @required String stateKey,
  }) : super._(
          args,
          content: content,
          previousContent: previousContent,
          stateKey: stateKey,
        );
}

class KnockEvent extends MemberChangeEvent {
  KnockEvent._(
    RoomEventArgs args, {
    @required MemberChange content,
    MemberChange previousContent,
    @required String stateKey,
  }) : super._(
          args,
          content: content,
          previousContent: previousContent,
          stateKey: stateKey,
        );
}

class DisplayNameChangeEvent extends JoinEvent {
  String get oldSubjectName => previousContent.displayName;
  String get newSubjectName => content.displayName;

  DisplayNameChangeEvent._(
    RoomEventArgs args, {
    @required MemberChange content,
    MemberChange previousContent,
    @required String stateKey,
  }) : super._(
          args,
          content: content,
          previousContent: previousContent,
          stateKey: stateKey,
        );
}

class AvatarChangeEvent extends JoinEvent {
  Uri get oldSubjectAvatarUrl => previousContent.avatarUrl;
  Uri get newSubjectAvatarUrl => content.avatarUrl;

  AvatarChangeEvent._(
    RoomEventArgs args, {
    @required MemberChange content,
    MemberChange previousContent,
    @required String stateKey,
  }) : super._(
          args,
          content: content,
          previousContent: previousContent,
          stateKey: stateKey,
        );
}
