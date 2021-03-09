// Copyright (C) 2019  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:math';

String randomString() {
  final r = Random();
  final codeUnits = List.generate(128, (index) => r.nextInt(33) + 89);
  return String.fromCharCodes(codeUnits);
}
