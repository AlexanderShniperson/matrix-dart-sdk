// Copyright (C) 2019  Wilko Manger
// Copyright (C) 2019  Mathieu Velten
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'dart:convert';
import 'package:matrix_sdk/src/model/api_call_statistics.dart';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;
import 'api/media.dart';
import 'model/authentication_session.dart';
import 'model/identifier.dart';
import 'store/store.dart';
import 'api/api.dart' show Api;
import 'model/device.dart';
import 'model/my_user.dart';
import 'util/mxc_url.dart';

/// Represents a Matrix homeserver. Also used as the main entry point
/// of the SDK.
@immutable
class Homeserver {
  static const String editedEventPrefix = ' * ';

  final Uri url;
  final Uri? wellKnownUrl;

  final Api api;

  Stream<ApiCallStatistics> get outApiCallStats => api.outApiCallStats;

  /// Returns a homeserver based on `.well-known` info.
  /// If there is no well-known info (404), just uses [url].
  ///
  /// Queries `$url/.well-known/matrix/client` for information.
  ///
  /// Throws [WellKnownException] on failure.
  static Future<Homeserver> fromWellKnown(
    Uri url, {
    http.Client? httpClient,
  }) async {
    final wellKnownUrl = url.resolve('/.well-known/matrix/client');

    httpClient = httpClient ?? http.Client();
    final response = await httpClient.get(wellKnownUrl);

    if (response.statusCode == 404) {
      return Homeserver(url);
    }

    if (response.statusCode != 200) {
      throw WellKnownFailPromptException('Response status code is not 200');
    }

    if (response.body.isEmpty) {
      throw WellKnownFailPromptException('Response body is null or empty');
    }

    dynamic body;
    try {
      body = json.decode(response.body);
    } on FormatException {
      throw WellKnownFailPromptException('Response body is not valid JSON');
    }

    final homeserverInfo = body['m.homeserver'];
    if (homeserverInfo == null) {
      throw WellKnownFailPromptException('m.homeserver key is missing');
    }

    String? baseUrl = homeserverInfo['base_url'];
    if (baseUrl == null) {
      throw WellKnownFailPromptException('base_url key is missing or null');
    }

    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    try {
      final actualUrl = Uri.parse(baseUrl);
      return Homeserver(actualUrl, wellKnownUrl: url);
    } on FormatException {
      throw WellKnownFailErrorException('base_url is not valid');
    }

    // TODO: Validation
  }

  Homeserver(
    this.url, {
    this.wellKnownUrl,
    http.Client? httpClient,
  }) : api = Api(url: url, httpClient: httpClient);

  Uri resolveDownloadUrl(Uri url) {
    if (url.scheme != 'mxc') {
      throw ArgumentError.value(url, 'url', 'Must be an mxc URL');
    }

    return this.url.resolve(
          '${MediaService.baseUrl}'
          '/${MediaService.downloadSegment}'
          '/${url.authority}/${url.pathSegments[0]}',
        );
  }

  Uri resolveThumbnailUrl(
    Uri url, {
    required int width,
    required int height,
    ResizeMethod resizeMethod = ResizeMethod.scale,
  }) {
    if (url.scheme != 'mxc') {
      throw ArgumentError.value(url, 'url', 'Must be an mxc URL');
    }

    return this
        .url
        .resolve(
          '${MediaService.baseUrl}'
          '/${MediaService.thumbnailSegment}'
          '/${url.authority}/${url.pathSegments[0]}',
        )
        .replace(
      queryParameters: {
        'width': width.toString(),
        'height': height.toString(),
        'method': resizeMethod.toShortString()
      },
    );
  }

  Future<MyUser> _prepareUser(
    Map<String, dynamic> body, {
    Device? device,
    required StoreLocation store,
  }) async {
    final accessToken = body['access_token'];
    final userId = UserId(body['user_id']);

    // If device was null,
    // create one with the id from the response
    if (device == null) {
      device = Device(
        id: DeviceId(body['device_id']),
        userId: userId,
      );
    } else {
      device = device.copyWith(
        id: DeviceId(body['device_id']),
        userId: userId,
      );
    }

    // Get profile information of this user
    final profile = await api.profile.get(
      accessToken: accessToken,
      userId: userId.toString(),
    );

    final displayName = profile['displayname'];
    final avatarUrl = tryParseMxcUrl(profile['avatar_url']);

    final myUser = MyUser.base(
      id: userId,
      accessToken: accessToken,
      name: displayName,
      avatarUrl: avatarUrl,
      currentDevice: device,
      hasSynced: false,
      isLoggedOut: false,
    );

    /// TODO(alex): saveMyUserToStore

    return myUser;
  }

  /// Register a user on this homeserver.
  ///
  /// This will return an [AuthenticationSession] the user must complete. One
  /// of the `flows` must be completed before the registration can be completed.
  ///
  /// Once registration is complete, will return a logged in [MyUser].
  Future<AuthenticationSession<MyUser>> register({
    required Username username,
    required String password,
    required StoreLocation store,
    required Device device,
    bool isolated = false,
  }) async {
    Future<Map<String, dynamic>> request([Map<String, dynamic>? auth]) {
      return api.register(
        kind: 'user',
        username: username.toString(),
        password: password,
        deviceId: device.id.toString(),
        deviceName: device.name ?? '',
        preventLogin: false,
        auth: auth,
      );
    }

    final body = await request();

    return AuthenticationSession<MyUser>.fromJson(
      body,
      request: request,
      onSuccess: (body) {
        return _prepareUser(
          body,
          store: store,
          device: device,
        );
      },
    );
  }

  /// Logs in to this homeserver and returns a [MyUser], which can be
  /// used for further operations.
  ///
  /// The [user] can be either a [UserId] or just a [Username].
  ///
  /// The [store] is a location to where all user data (rooms, events, etc)
  /// will be stored.
  ///
  /// Use the [device] to specify a device name or id for this
  /// login. Note that the `id` and `userId` are allowed to be null, they'll
  /// be filled automatically afterwards.
  ///
  /// If [isolated] is true, syncing and other operations will happen in a
  /// different [Isolate], transparently.
  Future<MyUser> login(
    UserIdentifier user,
    String password, {
    required StoreLocation store,
    Device? device,
  }) async {
    final body = await api.login(
      userIdentifier: user.toIdentifierJson(),
      password: password,
      deviceId: device?.id?.toString(),
      deviceDisplayName: device?.name,
    );

    return _prepareUser(
      body,
      store: store,
      device: device,
    );
  }

  /// Download content via this [Homeserver].
  Future<Stream<List<int>>> download(Uri url) {
    if (url.scheme != 'mxc') {
      throw ArgumentError.value(url, 'url', 'Must be an mxc URL');
    }

    final server = url.authority;
    final mediaId = url.pathSegments[0];

    return api.media.download(server: server, mediaId: mediaId);
  }

  /// Download a thumbnail via this [Homeserver].
  Future<Stream<List<int>>> downloadThumbnail(
    Uri url, {
    required int width,
    required int height,
    ResizeMethod resizeMethod = ResizeMethod.scale,
  }) {
    if (url.scheme != 'mxc') {
      throw ArgumentError.value(url, 'url', 'Must be an mxc URL');
    }

    final server = url.authority;
    final mediaId = url.pathSegments[0];

    return api.media.thumbnail(
      server: server,
      mediaId: mediaId,
      width: width,
      height: height,
      resizeMethod: resizeMethod.toShortString(),
    );
  }

  Future<Uri?> upload({
    required MyUser as,
    required Stream<List<int>> bytes,
    required int length,
    required String contentType,
    String fileName = '',
  }) async {
    if (as.accessToken == null || (as.isLoggedOut ?? false)) {
      throw StateError('User is logged out or has no access token');
    }

    final body = await api.media.upload(
      accessToken: as.accessToken!,
      bytes: bytes,
      bytesLength: length,
      contentType: contentType,
      fileName: fileName,
    );

    return tryParseMxcUrl(body['content_uri']);
  }
}

enum ResizeMethod {
  crop,
  scale,
}

extension ResizeMethodString on ResizeMethod {
  String toShortString() => toString().split('.')[1];
}

/// Extracting information from `.well-known` failed. See
/// [message] for details.
abstract class WellKnownException implements Exception {
  final String message;

  WellKnownException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Extracting information from `.well-known` failed. See
/// [message] for details.
///
/// Clients should `FAIL_PROMPT`, as per the spec.
class WellKnownFailPromptException extends WellKnownException {
  WellKnownFailPromptException(String message) : super(message);
}

/// Extracting information from `.well-known` failed. See
/// [message] for details.
///
/// Clients should `FAIL_ERROR`, as per the spec.
class WellKnownFailErrorException extends WellKnownException {
  WellKnownFailErrorException(String message) : super(message);
}
