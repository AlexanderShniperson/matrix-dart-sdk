// Copyright (C) 2019  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

extension MapExtensions on Map? {
  /// Safe way to get a something from a nested map.
  ///
  /// Will return null if any of the keys don't exist or are not a Map.
  dynamic get(List keys) {
    var current = this;

    for (final key in keys) {
      current = current?[key];

      if (current == null || current is! Map) {
        return current;
      }
    }

    return current;
  }
}
