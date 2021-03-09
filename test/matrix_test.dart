// Copyright (C) 2019  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:matrix_sdk/matrix_sdk.dart';
import 'package:test/test.dart';

import 'homeserver_test.dart';
import 'local_user_test.dart';
import 'olm_test.dart';

void main() {
  group('Identifier validity', () {
    test('Username', () {
      assert(Username.isValid('michael-scott'));
      assert(Username.isValid('pit_pattle'));
      assert(Username.isValid('joe'));

      assert(!Username.isValid('#\$^%\$43#\$^'));
      assert(!Username.isValid('wil@ko'));
      assert(!Username.isValid('@matthew'));
    });

    test('UserId', () {
      assert(!UserId.isValidFullyQualified('#\$^%\$43#\$^'));
      assert(!UserId.isValidFullyQualified('@pit'));
      assert(!UserId.isValidFullyQualified('pit'));
      assert(!UserId.isValidFullyQualified('pi&*3t'));
      assert(!UserId.isValidFullyQualified('pi&*3:t.tk'));

      assert(UserId.isValidFullyQualified('@pit:pattle.im'));
      assert(UserId.isValidFullyQualified('@joe:matrix.org'));
      assert(UserId.isValidFullyQualified('@jim:192.168.0.1'));
      assert(UserId.isValidFullyQualified('@jim:192.168.0.1:9043'));
    });
  });

  testOlm();
  testHomeserver();
  testLocalUser();
}
