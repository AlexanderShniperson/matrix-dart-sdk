// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:matrix_sdk/src/event/room/message_event.dart';
import 'package:matrix_sdk/src/homeserver.dart';
import 'package:matrix_sdk/src/model/api_call_statistics.dart';
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

  late ClientService _clientService;
  late MediaService _mediaService;

  late Media _media;
  Media get media => _media;

  late Profile _profile;
  Profile get profile => _profile;

  late Pushers _pushers;
  Pushers get pushers => _pushers;

  late Rooms _rooms;
  Rooms get rooms => _rooms;

  // ignore: close_sinks
  final _apiStatsSubject = StreamController<ApiCallStatistics>.broadcast();

  Stream<ApiCallStatistics> get outApiCallStats => _apiStatsSubject.stream;
  Sink<ApiCallStatistics> get _inApiCallStats => _apiStatsSubject.sink;

  Api({
    required Uri url,
    http.Client? httpClient,
  }) : _chopper = ChopperClient(
          client: httpClient,
          baseUrl: url.toString(),
          services: [
            ClientService.create(),
            MediaService.create(),
          ],
        ) {
    _clientService = _chopper.getService<ClientService>();
    _mediaService = _chopper.getService<MediaService>();

    _media = Media._(_mediaService, _inApiCallStats);
    _profile = Profile._(_clientService, _inApiCallStats);
    _rooms = Rooms._(_clientService, _inApiCallStats);
    _pushers = Pushers._(_clientService, _inApiCallStats);
  }

  Future<Map<String, dynamic>> login({
    String loginType = "m.login.password",
    required Map<String, dynamic> userIdentifier,
    required String password,
    String? deviceId,
    String? deviceDisplayName,
  }) async {
    final stopWatch = Stopwatch();
    stopWatch.start();
    final response = await _clientService.login(json.encode({
      'type': loginType,
      'identifier': userIdentifier,
      'password': password,
      'device_id': deviceId,
      'initial_device_display_name': deviceDisplayName,
    }));
    stopWatch.stop();
    _inApiCallStats.sendApiCallStats(
      "$runtimeType.login",
      stopWatch.elapsedMilliseconds,
      response,
    );

    response.throwIfNeeded();

    return response.body != null ? json.decode(response.body) : null;
  }

  Future<void> logout({
    required String accessToken,
  }) async {
    final stopWatch = Stopwatch();
    stopWatch.start();
    final response = await _clientService.logout(
      authorization: accessToken.toHeader(),
    );
    stopWatch.stop();
    _inApiCallStats.sendApiCallStats(
      "$runtimeType.logout",
      stopWatch.elapsedMilliseconds,
      response,
    );

    response.throwIfNeeded();
  }

  Future<Map<String, dynamic>> register({
    required String kind,
    Map<String, dynamic>? auth,
    required String username,
    required String password,
    required String deviceId,
    required String deviceName,
    required bool preventLogin,
  }) async {
    final stopWatch = Stopwatch();
    stopWatch.start();
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
    stopWatch.stop();
    _inApiCallStats.sendApiCallStats(
      "$runtimeType.register",
      stopWatch.elapsedMilliseconds,
      response,
    );

    if (response.statusCode == 401) {
      return json.decode(response.error?.toString() ?? '');
    }

    response.throwIfNeeded();

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> sync({
    required String accessToken,
    required String since,
    bool fullState = false,
    required Map<String, dynamic> filter,
    required int timeout,
  }) async {
    final stopWatch = Stopwatch();
    stopWatch.start();
    final response = await _clientService.sync(
      authorization: accessToken.toHeader(),
      since: since,
      fullState: fullState,
      filter: json.encode(filter),
      timeout: timeout,
    );
    stopWatch.stop();
    _inApiCallStats.sendApiCallStats(
      "$runtimeType.sync",
      stopWatch.elapsedMilliseconds,
      response,
    );

    response.throwIfNeeded();

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> join({
    required String accessToken,
    required String roomIdOrAlias,
    required String serverName,
  }) async {
    final stopWatch = Stopwatch();
    stopWatch.start();
    final response = await _clientService.join(
      authorization: accessToken.toHeader(),
      roomIdOrAlias: roomIdOrAlias,
      serverName: serverName,
    );
    stopWatch.stop();
    _inApiCallStats.sendApiCallStats(
      "$runtimeType.join",
      stopWatch.elapsedMilliseconds,
      response,
    );

    response.throwIfNeeded();

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> publicRooms({
    required String accessToken,
    required String server,
    int limit = 30,
    String since = '',
    String? genericSearchTerm,
  }) async {
    final stopWatch = Stopwatch();
    stopWatch.start();
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
    stopWatch.stop();
    _inApiCallStats.sendApiCallStats(
      "$runtimeType.publicRooms",
      stopWatch.elapsedMilliseconds,
      response,
    );

    response.throwIfNeeded();

    return json.decode(response.body);
  }
}

@immutable
class Media {
  final MediaService _service;
  final Sink<ApiCallStatistics> _inApiCallStats;

  const Media._(
    this._service,
    this._inApiCallStats,
  );

  Future<Stream<List<int>>> download({
    required String server,
    required String mediaId,
  }) async {
    final stopWatch = Stopwatch();
    stopWatch.start();
    final response = await _service.download(server, mediaId);
    stopWatch.stop();
    _inApiCallStats.sendApiCallStats(
      "$runtimeType.download",
      stopWatch.elapsedMilliseconds,
      response,
    );

    response.throwIfNeeded();

    return response.body!;
  }

  Future<Stream<List<int>>> thumbnail({
    required String server,
    required String mediaId,
    required int width,
    required int height,
    required String resizeMethod,
  }) async {
    final stopWatch = Stopwatch();
    stopWatch.start();
    final response = await _service.thumbnail(
      server,
      mediaId,
      width,
      height,
      resizeMethod,
    );
    stopWatch.stop();
    _inApiCallStats.sendApiCallStats(
      "$runtimeType.thumbnail",
      stopWatch.elapsedMilliseconds,
      response,
    );

    response.throwIfNeeded();

    return response.body!;
  }

  Future<Map<String, dynamic>> upload({
    required String accessToken,
    required Stream<List<int>> bytes,
    required int bytesLength,
    required String contentType,
    required String fileName,
  }) async {
    final stopWatch = Stopwatch();
    stopWatch.start();
    final response = await _service.upload(
      accessToken.toHeader(),
      bytes,
      bytesLength.toString(),
      contentType,
      fileName,
    );
    stopWatch.stop();
    _inApiCallStats.sendApiCallStats(
      "$runtimeType.upload",
      stopWatch.elapsedMilliseconds,
      response,
    );

    response.throwIfNeeded();

    return json.decode(response.body);
  }
}

@immutable
class Profile {
  final ClientService _service;
  final Sink<ApiCallStatistics> _inApiCallStats;

  const Profile._(
    this._service,
    this._inApiCallStats,
  );

  Future<Map<String, dynamic>> get({
    required String accessToken,
    required String userId,
  }) async {
    final stopWatch = Stopwatch();
    stopWatch.start();
    final response = await _service.profile(
      authorization: accessToken.toHeader(),
      userId: userId,
    );
    stopWatch.stop();
    _inApiCallStats.sendApiCallStats(
      "$runtimeType.get",
      stopWatch.elapsedMilliseconds,
      response,
    );

    response.throwIfNeeded();

    return json.decode(response.body);
  }

  Future<void> putDisplayName({
    required String accessToken,
    required String userId,
    required String value,
  }) async {
    final stopWatch = Stopwatch();
    stopWatch.start();
    final response = await _service.profileSetDisplayName(
      authorization: accessToken.toHeader(),
      userId: userId,
      body: json.encode({
        'displayname': value,
      }),
    );
    stopWatch.stop();
    _inApiCallStats.sendApiCallStats(
      "$runtimeType.putDisplayName",
      stopWatch.elapsedMilliseconds,
      response,
    );

    response.throwIfNeeded();
  }
}

@immutable
class Rooms {
  final ClientService _service;
  final Sink<ApiCallStatistics> _inApiCallStats;

  const Rooms._(
    this._service,
    this._inApiCallStats,
  );

  Future<Map<String, dynamic>> messages({
    required String accessToken,
    required String roomId,
    required int limit,
    required String from,
    required Map<String, dynamic> filter,
  }) async {
    final stopWatch = Stopwatch();
    stopWatch.start();
    final response = await _service.roomMessages(
      authorization: accessToken.toHeader(),
      roomId: roomId,
      limit: limit,
      from: from,
      filter: json.encode(filter),
    );
    stopWatch.stop();
    _inApiCallStats.sendApiCallStats(
      "$runtimeType.messages",
      stopWatch.elapsedMilliseconds,
      response,
    );

    response.throwIfNeeded();

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> members({
    required String accessToken,
    required String roomId,
    required String at,
    String membership = '',
  }) async {
    final stopWatch = Stopwatch();
    stopWatch.start();
    final response = await _service.members(
      authorization: accessToken.toHeader(),
      roomId: roomId.toString(),
      at: membership,
      membership: membership,
    );
    stopWatch.stop();
    _inApiCallStats.sendApiCallStats(
      "$runtimeType.members",
      stopWatch.elapsedMilliseconds,
      response,
    );

    response.throwIfNeeded();

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> send({
    required String accessToken,
    required String roomId,
    required String eventType,
    required String transactionId,
    required Map<String, dynamic> content,
  }) async {
    final stopWatch = Stopwatch();
    stopWatch.start();
    final response = await _service.send(
      authorization: accessToken.toHeader(),
      roomId: roomId.toString(),
      eventType: eventType,
      txnId: transactionId,
      content: json.encode(content),
    );
    stopWatch.stop();
    _inApiCallStats.sendApiCallStats(
      "$runtimeType.send",
      stopWatch.elapsedMilliseconds,
      response,
    );

    response.throwIfNeeded();

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> edit({
    required String accessToken,
    required String roomId,
    required TextMessageEvent event,
    required String newContent,
    required String transactionId,
  }) async {
    final body = {
      'body': '${Homeserver.editedEventPrefix}$newContent',
      'msgtype': 'm.text',
      'm.new_content': {'body': newContent, 'msgtype': 'm.text'},
      'm.relates_to': {'event_id': event.id.value, 'rel_type': 'm.replace'}
    };

    final stopWatch = Stopwatch();
    stopWatch.start();
    final response = await _service.edit(
      authorization: accessToken.toHeader(),
      roomId: roomId.toString(),
      content: json.encode(body),
      txnId: transactionId,
    );
    stopWatch.stop();
    _inApiCallStats.sendApiCallStats(
      "$runtimeType.edit",
      stopWatch.elapsedMilliseconds,
      response,
    );

    response.throwIfNeeded();

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> redact({
    required String accessToken,
    required String roomId,
    required String eventId,
    String transactionId = '',
    String? reason,
  }) async {
    final stopWatch = Stopwatch();
    stopWatch.start();
    final response = await _service.redact(
      authorization: accessToken.toHeader(),
      roomId: roomId.toString(),
      eventId: eventId.toString(),
      txnId: transactionId,
      content: json.encode({
        'reason': (reason ?? "").isEmpty ? 'Deleted by author' : reason,
      }),
    );
    stopWatch.stop();
    _inApiCallStats.sendApiCallStats(
      "$runtimeType.redact",
      stopWatch.elapsedMilliseconds,
      response,
    );

    response.throwIfNeeded();

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> sendState({
    required String accessToken,
    required String roomId,
    required String eventType,
    required String stateKey,
    required Map<String, dynamic> content,
  }) async {
    final stopWatch = Stopwatch();
    stopWatch.start();
    final response = await _service.sendState(
      authorization: accessToken.toHeader(),
      roomId: roomId.toString(),
      eventType: eventType,
      stateKey: stateKey,
      content: json.encode(content),
    );
    stopWatch.stop();
    _inApiCallStats.sendApiCallStats(
      "$runtimeType.sendState",
      stopWatch.elapsedMilliseconds,
      response,
    );

    response.throwIfNeeded();

    return json.decode(response.body);
  }

  Future<void> typing({
    required String accessToken,
    required String roomId,
    required String userId,
    required bool typing,
    int timeout = 0,
  }) async {
    final stopWatch = Stopwatch();
    stopWatch.start();
    final response = await _service.typing(
      authorization: accessToken.toHeader(),
      roomId: roomId,
      userId: userId,
      body: json.encode({
        'typing': typing,
        if (typing) 'timeout': timeout,
      }),
    );
    stopWatch.stop();
    _inApiCallStats.sendApiCallStats(
      "$runtimeType.typing",
      stopWatch.elapsedMilliseconds,
      response,
    );

    response.throwIfNeeded();
  }

  Future<void> kick({
    required String accessToken,
    required String roomId,
    required String userId,
  }) async {
    final stopWatch = Stopwatch();
    stopWatch.start();
    final response = await _service.kick(
      authorization: accessToken.toHeader(),
      roomId: roomId,
      body: json.encode({
        'user_id': userId,
      }),
    );
    stopWatch.stop();
    _inApiCallStats.sendApiCallStats(
      "$runtimeType.kick",
      stopWatch.elapsedMilliseconds,
      response,
    );

    response.throwIfNeeded();
  }

  Future<void> readMarkers({
    required String accessToken,
    required String roomId,
    required String fullyRead,
    String? read,
  }) async {
    final body = {
      'm.fully_read': fullyRead,
    };

    if (read != null) {
      body['m.read'] = read;
    }

    final stopWatch = Stopwatch();
    stopWatch.start();
    final response = await _service.readMarkers(
      authorization: accessToken.toHeader(),
      roomId: roomId,
      body: json.encode(body),
    );
    stopWatch.stop();
    _inApiCallStats.sendApiCallStats(
      "$runtimeType.readMarkers",
      stopWatch.elapsedMilliseconds,
      response,
    );

    response.throwIfNeeded();
  }

  Future<void> leave({
    required String accessToken,
    required String roomId,
  }) async {
    final stopWatch = Stopwatch();
    stopWatch.start();
    final response = await _service.leave(
      authorization: accessToken.toHeader(),
      roomId: roomId,
    );
    stopWatch.stop();
    _inApiCallStats.sendApiCallStats(
      "$runtimeType.leave",
      stopWatch.elapsedMilliseconds,
      response,
    );

    response.throwIfNeeded();
  }
}

@immutable
class Pushers {
  final ClientService _service;
  final Sink<ApiCallStatistics> _inApiCallStats;

  const Pushers._(
    this._service,
    this._inApiCallStats,
  );

  Future<bool> set({
    required String accessToken,
    required Map<String, dynamic> body,
  }) async {
    final stopWatch = Stopwatch();
    stopWatch.start();
    final response = await _service.setPusher(
      authorization: accessToken.toHeader(),
      body: json.encode(body),
    );
    stopWatch.stop();
    _inApiCallStats.sendApiCallStats(
      "$runtimeType.set",
      stopWatch.elapsedMilliseconds,
      response,
    );

    response.throwIfNeeded();

    return response.statusCode == 200;
  }
}

extension on String {
  /// Supposed to be used on an access token String.
  String toHeader() => 'Bearer $this';
}

extension on Response {
  void throwIfNeeded() {
    final error = getMatrixException();
    if (error == null) {
      return;
    }

    throw error;
  }

  MatrixException? getMatrixException() {
    if (error == null) {
      return null;
    }

    if (headers[HttpHeaders.contentEncodingHeader]
            ?.toLowerCase()
            .contains(jsonHeaders) ==
        true) {
      final errorMap = json.decode(error.toString());
      return MatrixException.fromJson(errorMap);
    } else {
      return MatrixException.fromJson({
        "errcode": "HTTP_ERROR",
        "error": bodyString,
        "status_code": statusCode,
      });
    }
  }
}

extension on Sink<ApiCallStatistics> {
  void sendApiCallStats(
    String method,
    int timeMillis,
    Response response,
  ) {
    final request = response.base.request;
    add(ApiCallStatistics(
      method: method,
      requestMethod: request?.method ?? "",
      requestUrl: request?.url.toString() ?? "",
      responseTimeMillis: timeMillis,
      responseStatusCode: response.statusCode,
      bytesSend: request?.contentLength ?? 0,
      bytesReceived: response.bodyBytes.length,
    ));
  }
}
