// Copyright (C) 2019  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:meta/meta.dart';

import '../room_event.dart';
import 'state_event.dart';

import '../../event.dart';

class JoinRulesChangeEvent extends StateEvent {
  static const matrixType = 'm.room.join_rules';

  @override
  final String type = matrixType;

  @override
  final JoinRules content;

  @override
  final JoinRules previousContent;

  JoinRulesChangeEvent(
    RoomEventArgs args, {
    @required this.content,
    this.previousContent,
  }) : super(args, stateKey: '');
}

@immutable
class JoinRules extends EventContent {
  final JoinRule rule;

  JoinRules({@required this.rule});

  @override
  bool operator ==(dynamic other) => other is JoinRules && rule == other.rule;

  @override
  int get hashCode => rule.hashCode;

  factory JoinRules.fromJson(Map<String, dynamic> content) {
    if (content == null) return null;

    JoinRule rule;

    switch (content['join_rule']) {
      case 'public':
        rule = JoinRule.public;
        break;
      case 'invite':
        rule = JoinRule.invite;
        break;
      case 'private':
        rule = JoinRule.private;
        break;
      case 'knock':
        rule = JoinRule.knock;
        break;
    }

    return JoinRules(rule: rule);
  }

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'join_rule': rule.toString().split('.')[1],
    });
}

enum JoinRule {
  public,
  invite,

  /// Unused.
  private,

  /// Unused.
  knock,
}
