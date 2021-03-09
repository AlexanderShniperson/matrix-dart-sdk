// Copyright (C) 2019  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import '../context.dart';
import '../my_user.dart';

import 'pusher.dart';

class Pushers {
  final Context _context;

  Pushers(this._context);

  Future<void> _set(Map<String, dynamic> pusherJson) =>
      _context.updater.setPusher(pusherJson);

  /// Set a pusher for this [MyUser]. Returns true if successfully set.
  Future<void> set(Pusher pusher) => _set(pusher.toJson());

  Future<void> add(Pusher pusher) => _set(pusher.toJson()
    ..addAll({
      'append': true,
    }));

  /// Remove a pusher for this [MyUser].
  /// Returns true if successfully removed.
  Future<bool> remove(Pusher pusher) {
    final json = pusher.toJson();
    json['kind'] = null;

    return _set(json);
  }
}
