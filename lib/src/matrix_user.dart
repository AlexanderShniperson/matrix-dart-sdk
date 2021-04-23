// Copyright (C) 2019  Wilko Manger
// Copyright (C) 2019  Mathieu Velten
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:meta/meta.dart';
import 'package:quiver/core.dart';

import 'identifier.dart';

@immutable
abstract class MatrixUser with Identifiable<UserId> {
  @override
  UserId get id;

  String get name;
  Uri? get avatarUrl;

  @override
  bool operator ==(dynamic other) =>
      other is MatrixUser &&
      id == other.id &&
      name == other.name &&
      avatarUrl == other.avatarUrl;

  @override
  int get hashCode => hashObjects([super.hashCode, id, name, avatarUrl]);
}
