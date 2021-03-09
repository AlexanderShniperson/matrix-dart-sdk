// Copyright (C) 2019  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:meta/meta.dart';

class Account {
  final IdentityKeys identityKeys;

  Account(this.identityKeys);
}

class IdentityKeys {
  /// Curve22519 base64 encoded key.
  final String curve25519;

  /// Ed25519 base64 encoded key.
  final String ed25519;

  IdentityKeys({
    @required this.curve25519,
    @required this.ed25519,
  });

  factory IdentityKeys.fromJson(Map<String, dynamic> json) {
    return IdentityKeys(
      curve25519: json['curve25519'],
      ed25519: json['ed25519'],
    );
  }

  Map<String, dynamic> toJson() => {
        'curve25519': curve25519,
        'ed25519': ed25519,
      };
}
