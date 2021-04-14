// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:meta/meta.dart';

import 'homeserver.dart';
import 'identifier.dart';
import 'my_user.dart';
import 'updater/updater.dart';

/// Context that certain objects have like [Room]s to determine what
/// [Homeserver] or [MyUser] they're associated with.
@immutable
class Context {
  final UserId? myId;

  Updater? get updater {
    if (myId == null) {
      return null;
    }
    return Updater.get(myId!);
  }

  Homeserver? get homeserver => updater?.homeserver;

  const Context({
    required this.myId,
  });

  @override
  bool operator ==(dynamic other) => other is Context && myId == other.myId;

  @override
  int get hashCode => myId.hashCode;
}

/// A class that can have a [Context], required for certain operations.
///
/// Contextual operations need a non-null [context], and don't (in general)
/// depend on any data of the object itself.
@immutable
abstract class Contextual<T> {
  /// A [Context] to which this object relates to, necessary for certain
  /// operations.
  Context? get context;

  /// Create a delta of this object.
  ///
  /// Implementers should set the [context] and possible `id` in the delta
  /// and its children.
  T delta();

  /// Get this data as a property from [MyUser].
  T propertyOf(MyUser user);
}
