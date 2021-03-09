// Copyright (C) 2019  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'account.dart';

/// Interface of `libolm`.
///
/// Implement this class to provide a `libolm` implementation.
///
/// See
// ignore: one_member_abstracts
abstract class Olm {
  Account account();
}
