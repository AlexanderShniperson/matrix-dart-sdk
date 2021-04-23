// Copyright (C) 2019  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import '../context.dart';
import '../my_user.dart';

import 'pusher.dart';
import '../util/nullable_extension.dart';

class Pushers {
  final Context _context;

  Pushers(this._context);

  bool get isReady => _context.updater?.isReady ?? false;

  Future<void> _set(Map<String, dynamic> pusherJson) {
    final result = _context.updater.let((value) {
      value.setPusher(pusherJson);
    });
    return result ?? Future.value();
  }

  /// Set a pusher for this [MyUser]. Returns true if successfully set.
  Future<void> set(Pusher pusher) => _set(pusher.toJson());

  Future<void> add(Pusher pusher) => _set(pusher.toJson()
    ..addAll({
      'append': true,
    }));

  /// Remove a pusher for this [MyUser].
  /// Returns true if successfully removed.
  Future<void> remove(Pusher pusher) {
    final json = pusher.toJson();
    json['kind'] = null;
    return _set(json);
  }
}
