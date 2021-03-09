// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:meta/meta.dart';

/// Type of membership a user can have in a [Room].
@immutable
abstract class Membership {
  String get value;

  const Membership();

  @override
  bool operator ==(dynamic other) => runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => value;

  static const joined = Joined._();
  static const invited = Invited._();
  static const left = Left._();
  static const kicked = Kicked._();
  static const banned = Banned._();
  static const knocked = Knocked._();

  /// Parse based on Matrix spec membership strings, e.g. `join`, `leave`, etc.
  /// Will never return [Membership.kicked].
  factory Membership.parse(String value) {
    switch (value) {
      case Joined._value:
        return Membership.joined;
      case Left._value:
        return Membership.left;
      case Invited._value:
        return Membership.invited;
      case Banned._value:
        return Membership.banned;
      case Knocked._value:
        return Membership.knocked;
    }

    throw UnsupportedError('Unknown value: $value');
  }
}

class Joined extends Membership {
  static const _value = 'join';

  @override
  final String value = _value;

  const Joined._();
}

class Invited extends Membership {
  static const _value = 'invite';

  @override
  final String value = _value;

  const Invited._();
}

class Left extends Membership {
  static const _value = 'leave';

  @override
  final String value = _value;

  const Left._();
}

class Kicked extends Left {
  const Kicked._() : super._();
}

class Banned extends Membership {
  static const _value = 'ban';

  @override
  final String value = _value;

  const Banned._();
}

class Knocked extends Membership {
  static const _value = 'knock';

  @override
  final String value = _value;

  const Knocked._();
}
