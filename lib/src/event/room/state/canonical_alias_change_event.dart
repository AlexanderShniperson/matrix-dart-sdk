// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:meta/meta.dart';

import '../../../identifier.dart';
import '../room_event.dart';
import 'state_event.dart';
import '../../event.dart';

class CanonicalAliasChangeEvent extends StateEvent {
  static const matrixType = 'm.room.canonical_alias';

  @override
  final String type = matrixType;

  @override
  final CanonicalAliasChange content;

  @override
  final CanonicalAliasChange previousContent;

  CanonicalAliasChangeEvent(
    RoomEventArgs args, {
    @required this.content,
    this.previousContent,
  }) : super(args, stateKey: '');
}

@immutable
class CanonicalAliasChange extends EventContent {
  final RoomAlias canonicalAlias;
  final List<RoomAlias> alternativeAliases;

  CanonicalAliasChange({
    @required this.canonicalAlias,
    this.alternativeAliases = const [],
  });

  @override
  bool operator ==(dynamic other) =>
      other is CanonicalAliasChange && canonicalAlias == other.canonicalAlias;

  @override
  int get hashCode => canonicalAlias.hashCode;

  factory CanonicalAliasChange.fromJson(Map<String, dynamic> content) {
    if (content == null) return null;

    final canonAlias = content['alias'];
    final altAliases = content['alt_aliases'];

    return CanonicalAliasChange(
      canonicalAlias: canonAlias != null ? RoomAlias(canonAlias) : null,
      alternativeAliases: altAliases != null && altAliases is List<dynamic>
          ? altAliases.map((a) => RoomAlias(a)).toList(growable: false)
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'alias': canonicalAlias?.toString(),
      'alt_aliases': alternativeAliases?.map((a) => a.toString())?.toList(),
    });
}
