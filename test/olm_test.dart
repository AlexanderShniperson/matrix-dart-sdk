// Copyright (C) 2019  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:io';

import 'package:matrix_sdk/olm_ffi.dart';
import 'package:test/test.dart';

void testOlm() {
  group('Olm', () {
    group('.account ', () {
      test('returns Account if successful', () async {
        final olm = OlmFFI(
          libraryPath: '${Directory.current.path}/lib-native/',
        );

        final account = olm.account();
        expect(account.identityKeys.curve25519, isNotNull);
        expect(account.identityKeys.ed25519, isNotNull);
      });
    });
  });
}
