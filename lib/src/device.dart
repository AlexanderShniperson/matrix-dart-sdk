// Copyright (C) 2019  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:meta/meta.dart';

import 'identifier.dart';

class DeviceId extends Id {
  DeviceId(String value) : super(value);
}

@immutable
class Device with Identifiable<DeviceId> {
  @override
  final DeviceId? id;

  final UserId? userId;

  final String? name;

  final DateTime? lastSeen;

  final String? lastIpAddress;

  Device({
    this.id,
    this.userId,
    this.name,
    this.lastSeen,
    this.lastIpAddress,
  });

  Device copyWith({
    DeviceId? id,
    UserId? userId,
    String? name,
    DateTime? lastSeen,
    String? lastIpAddress,
  }) {
    return Device(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      lastSeen: lastSeen ?? this.lastSeen,
      lastIpAddress: lastIpAddress ?? this.lastIpAddress,
    );
  }

  Device merge(Device? other) {
    if (other == null) {
      return this;
    }

    return copyWith(
      id: other.id,
      userId: other.userId,
      name: other.name,
      lastSeen: other.lastSeen,
      lastIpAddress: other.lastIpAddress,
    );
  }
}
