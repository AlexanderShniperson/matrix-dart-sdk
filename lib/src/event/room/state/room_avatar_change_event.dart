// Copyright (C) 2019  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:meta/meta.dart';

import '../../event.dart';
import '../room_event.dart';
import 'state_event.dart';

import '../../../util/mxc_url.dart';

class RoomAvatarChangeEvent extends StateEvent {
  static const matrixType = 'm.room.avatar';

  @override
  final String type = matrixType;

  @override
  final RoomAvatarChange content;

  @override
  final RoomAvatarChange previousContent;

  RoomAvatarChangeEvent(
    RoomEventArgs args, {
    required this.content,
    this.previousContent,
  }) : super(args, stateKey: '');
}

@immutable
class RoomAvatarChange extends EventContent {
  /// An `mxc` url pointing to the avatar.
  final Uri url;

  RoomAvatarChange({
    required this.url,
  });

  @override
  bool operator ==(dynamic other) =>
      other is RoomAvatarChange && url == other.url;

  @override
  int get hashCode => url.hashCode;

  factory RoomAvatarChange.fromJson(Map<String, dynamic> content) {
    if (content == null) return null;

    var url = content['url'];
    if (url != null) {
      url = tryParseMxcUrl(url);
    }

    return RoomAvatarChange(url: url);
  }

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'url': url?.toString(),
    });
}
