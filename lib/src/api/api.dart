// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';

import 'package:matrix_sdk/matrix_sdk.dart';
import 'package:meta/meta.dart';
import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;

import 'client.dart';
import 'media.dart';
import '../exception.dart';

/// Low level access to all supported API calls on a homeserver.
class Api {
  static const String base = '_matrix';
  static const String version = 'r0';

  final ChopperClient _chopper;

  ClientService _clientService;
  MediaService _mediaService;

  Media _media;
  Media get media => _media;

  Profile _profile;
  Profile get profile => _profile;

  Pushers _pushers;
  Pushers get pushers => _pushers;

  Rooms _rooms;
  Rooms get rooms => _rooms;

  Api({@required Uri url, http.Client httpClient})
      : _chopper = ChopperClient(
          client: httpClient,
          baseUrl: url.toString(),
          services: [ClientService.create(), MediaService.create()],
        ) {
    _clientService = _chopper.getService();
    _mediaService = _chopper.getService();

    _media = Media._(_mediaService);
    _profile = Profile._(_clientService);
    _rooms = Rooms._(_clientService);
    _pushers = Pushers._(_clientService);
  }

  Future<Map<String, dynamic>> login(Map<String, dynamic> body) async {
    final response = await _clientService.login(json.encode(body));

    response.throwIfNeeded();

    return response.body != null ? json.decode(response.body) : null;
  }

  Future<void> logout({@required String accessToken}) async {
    final response = await _clientService.logout(
      authorization: accessToken.toHeader(),
    );

    response.throwIfNeeded();
  }

  Future<Map<String, dynamic>> register({
    String kind,
    Map<String, dynamic> auth,
    String username,
    String password,
    String deviceId,
    String deviceName,
    bool preventLogin,
  }) async {
    final response = await _clientService.register(
      kind: kind,
      body: json.encode({
        if (auth != null) 'auth': auth,
        'username': username,
        'password': password,
        'device_id': deviceId,
        'initial_device_display_name': deviceName,
        'inhibit_login': preventLogin,
      }),
    );

    if (response.statusCode == 401) {
      return json.decode(response.error);
    }

    response.throwIfNeeded();

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> sync({
    @required String accessToken,
    String since,
    bool fullState = false,
    Map<String, dynamic> filter,
    int timeout,
  }) async {
    final response = await _clientService.sync(
      authorization: accessToken.toHeader(),
      since: since,
      fullState: fullState,
      filter: json.encode(filter),
      timeout: timeout,
    );

    response.throwIfNeeded();

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> join({
    @required String accessToken,
    @required String roomIdOrAlias,
    String serverName,
  }) async {
    final response = await _clientService.join(
      authorization: accessToken.toHeader(),
      roomIdOrAlias: roomIdOrAlias,
      serverName: serverName,
    );

    response.throwIfNeeded();

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> publicRooms({
    @required String accessToken,
    String server,
    int limit = 30,
    String since,
    String genericSearchTerm,
  }) async {
    final response = await _clientService.publicRooms(
      authorization: accessToken.toHeader(),
      server: server,
      body: json.encode({
        'limit': limit,
        'since': since,
        if (genericSearchTerm != null)
          'filter': {
            'generic_search_term': genericSearchTerm,
          },
      }),
    );

    response.throwIfNeeded();

    return json.decode(response.body);
  }
}

@immutable
class Media {
  final MediaService _service;

  const Media._(this._service);

  Future<Stream<List<int>>> download({
    @required String server,
    @required String mediaId,
  }) async {
    final response = await _service.download(server, mediaId);

    response.throwIfNeeded();

    return response.body;
  }

  Future<Stream<List<int>>> thumbnail({
    @required String server,
    @required String mediaId,
    @required int width,
    @required int height,
    @required String resizeMethod,
  }) async {
    final response = await _service.thumbnail(
      server,
      mediaId,
      width,
      height,
      resizeMethod,
    );

    response.throwIfNeeded();

    return response.body;
  }

  Future<Map<String, dynamic>> upload({
    @required String accessToken,
    @required Stream<List<int>> bytes,
    @required int bytesLength,
    @required String contentType,
    @required String fileName,
  }) async {
    final response = await _service.upload(
      accessToken.toHeader(),
      bytes,
      bytesLength.toString(),
      contentType,
      fileName,
    );

    response.throwIfNeeded();

    return json.decode(response.body);
  }
}

@immutable
class Profile {
  final ClientService _service;

  const Profile._(this._service);

  Future<Map<String, dynamic>> get({
    @required String accessToken,
    @required String userId,
  }) async {
    final response = await _service.profile(
      authorization: accessToken.toHeader(),
      userId: userId,
    );

    response.throwIfNeeded();

    return json.decode(response.body);
  }

  Future<void> putDisplayName({
    @required String accessToken,
    @required String userId,
    String value,
  }) async {
    final response = await _service.profileSetDisplayName(
      authorization: accessToken.toHeader(),
      userId: userId,
      body: json.encode({
        'displayname': value,
      }),
    );

    response.throwIfNeeded();
  }
}

@immutable
class Rooms {
  final ClientService _service;

  const Rooms._(this._service);

  Future<Map<String, dynamic>> messages({
    @required String accessToken,
    @required String roomId,
    int limit,
    String from,
    Map<String, dynamic> filter,
  }) async {
    final response = await _service.roomMessages(
      authorization: accessToken.toHeader(),
      roomId: roomId,
      limit: limit,
      from: from,
      filter: json.encode(filter),
    );

    response.throwIfNeeded();

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> members({
    @required String accessToken,
    @required String roomId,
    String at,
    String membership,
  }) async {
    final response = await _service.members(
      authorization: accessToken.toHeader(),
      roomId: roomId.toString(),
      at: membership,
      membership: membership,
    );

    response.throwIfNeeded();

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> send({
    @required String accessToken,
    @required String roomId,
    @required String eventType,
    String transactionId,
    Map<String, dynamic> content,
  }) async {
    final response = await _service.send(
      authorization: accessToken.toHeader(),
      roomId: roomId.toString(),
      eventType: eventType,
      txnId: transactionId,
      content: json.encode(content),
    );

    response.throwIfNeeded();

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> edit({
    @required String accessToken,
    @required String roomId,
    @required TextMessageEvent event,
    @required String newContent,
    String transactionId,
  }) async {
    final body = {
      'body': '${Homeserver.editedEventPrefix}$newContent',
      'msgtype': 'm.text',
      'm.new_content': {'body': newContent, 'msgtype': 'm.text'},
      'm.relates_to': {'event_id': event.id.value, 'rel_type': 'm.replace'}
    };

    final response = await _service.edit(
      authorization: accessToken.toHeader(),
      roomId: roomId.toString(),
      content: json.encode(body),
      txnId: transactionId,
    );

    response.throwIfNeeded();

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> redact({
    @required String accessToken,
    @required String roomId,
    @required String eventId,
    String transactionId,
    String reason,
  }) async {
    final response = await _service.redact(
      authorization: accessToken.toHeader(),
      roomId: roomId.toString(),
      eventId: eventId.toString(),
      txnId: transactionId,
      reason: reason,
    );

    response.throwIfNeeded();

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> sendState({
    @required String accessToken,
    @required String roomId,
    @required String eventType,
    String stateKey,
    Map<String, dynamic> content,
  }) async {
    final response = await _service.sendState(
      authorization: accessToken.toHeader(),
      roomId: roomId.toString(),
      eventType: eventType,
      stateKey: stateKey,
      content: json.encode(content),
    );

    response.throwIfNeeded();

    return json.decode(response.body);
  }

  Future<void> typing({
    @required String accessToken,
    @required String roomId,
    @required String userId,
    @required bool typing,
    int timeout,
  }) async {
    final response = await _service.typing(
      authorization: accessToken.toHeader(),
      roomId: roomId,
      userId: userId,
      body: json.encode({
        'typing': typing,
        if (typing) 'timeout': timeout,
      }),
    );

    response.throwIfNeeded();
  }

  Future<void> kick({
    @required String accessToken,
    @required String roomId,
    @required String userId,
  }) async {
    final response = await _service.kick(
      authorization: accessToken.toHeader(),
      roomId: roomId,
      body: json.encode({
        'user_id': userId,
      }),
    );

    response.throwIfNeeded();
  }

  Future<void> readMarkers({
    @required String accessToken,
    @required String roomId,
    @required String fullyRead,
    String read,
  }) async {
    final body = {
      'm.fully_read': fullyRead,
    };

    if (read != null) {
      body['m.read'] = read;
    }

    final response = await _service.readMarkers(
      authorization: accessToken.toHeader(),
      roomId: roomId,
      body: json.encode(body),
    );

    response.throwIfNeeded();
  }

  Future<void> leave({
    @required String accessToken,
    @required String roomId,
  }) async {
    final response = await _service.leave(
      authorization: accessToken.toHeader(),
      roomId: roomId,
    );

    response.throwIfNeeded();
  }
}

@immutable
class Pushers {
  final ClientService _service;

  const Pushers._(this._service);

  Future<bool> set({
    @required String accessToken,
    @required Map<String, dynamic> body,
  }) async {
    final response = await _service.setPusher(
      authorization: accessToken.toHeader(),
      body: json.encode(body),
    );

    response.throwIfNeeded();

    switch (response.statusCode) {
      case 200:
        return true;
      default:
        return false;
    }
  }
}

extension on String {
  /// Supposed to be used on an access token String.
  String toHeader() => 'Bearer $this';
}

extension on Response {
  void throwIfNeeded() {
    if (error == null) {
      return;
    }

    throw MatrixException.fromJson(json.decode(error));
  }
}
