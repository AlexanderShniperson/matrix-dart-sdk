// Copyright (C) 2019  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:meta/meta.dart';

import '../homeserver.dart';

extension MatrixUrl on Uri {
  /// Returns true if the `scheme` is `mxc`.
  bool get isMxc => scheme == 'mxc';

  Uri resolveDownloadUrl(Homeserver homeserver) =>
      homeserver.resolveDownloadUrl(this);

  Uri resolveThumbnailUrl(
    Homeserver homeserver, {
    @required int width,
    @required int height,
    ResizeMethod resizeMethod = ResizeMethod.scale,
  }) =>
      homeserver.resolveThumbnailUrl(
        this,
        width: width,
        height: height,
        resizeMethod: resizeMethod,
      );
}

Uri tryParseMxcUrl(String input) {
  if (input == null) {
    return null;
  }

  final uri = Uri.tryParse(input);

  return uri?.isMxc == true ? uri : null;
}
