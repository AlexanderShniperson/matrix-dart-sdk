// Copyright (C) 2019  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:meta/meta.dart';

// When subclassing this class, make sure to add `kind` and `data`
// to `toJson()`.
abstract class Pusher {
  String get key;

  String get kind;

  Map<String, dynamic> get data;

  /// Reverse DNS style app id (`im.pattle.app`), however, it's recommended
  /// that it ends with a platform, for example: `im.pattle.app.android`.
  String get appId;

  /// User visible string of the app name.
  String get appName;

  /// User visible string of the device name.
  String get deviceName;

  /// Preferred language for receiving notifications. Example: `en` or `en-US`.
  String get language;

  Pusher() {
    assert(key.length <= 512);
    assert(appId.length <= 64);
  }

  Map<String, dynamic> toJson() => {
        'pushkey': key,
        'app_id': appId,
        'app_display_name': appName,
        'device_display_name': deviceName,
        'lang': language,
        'kind': kind,
        'data': data,
        'append': true
      };
}

class HttpPusher extends Pusher {
  @override
  final String appId;

  @override
  Map<String, dynamic> get data => {
        'url': url.toString(),
      };

  @override
  String get kind => 'http';

  @override
  final String appName;

  @override
  final String deviceName;

  /// The Firebase Registration ID, APNS token or something similar.
  @override
  final String key;

  @override
  final String language;

  final Uri url;

  HttpPusher({
    @required this.appId,
    @required this.appName,
    @required this.deviceName,
    @required this.key,
    this.language = 'en-US',
    @required this.url,
  })  : assert(url.path.contains('/_matrix/push/v1/notify')),
        assert(url.isScheme('https'));
}

class EmailPusher extends Pusher {
  @override
  final String appId = 'm.email';

  @override
  String get kind => 'email';

  @override
  Map<String, dynamic> get data => {};

  @override
  final String appName;

  @override
  final String deviceName;

  @override
  String get key => emailAddress;

  @override
  final String language;

  /// Email address to send notifications to.
  final String emailAddress;

  EmailPusher({
    @required this.appName,
    @required this.deviceName,
    @required this.emailAddress,
    this.language = 'en-US',
  });
}
