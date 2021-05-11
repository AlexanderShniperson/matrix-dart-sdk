// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// ignore_for_file: always_put_control_body_on_new_line, always_specify_types, prefer_const_declarations
class _$ClientService extends ClientService {
  _$ClientService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final definitionType = ClientService;

  @override
  Future<Response<dynamic>> login(String body) {
    final $url = '/_matrix/client/r0/login';
    final $body = body;
    final $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> profile(
      {required String authorization, required String userId}) {
    final $url = '/_matrix/client/r0/profile/$userId';
    final $headers = {
      'Authorization': authorization,
    };

    final $request = Request('GET', $url, client.baseUrl, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> profileSetDisplayName(
      {required String authorization,
      required String userId,
      required String body}) {
    final $url = '/_matrix/client/r0/profile/$userId/displayname';
    final $headers = {
      'Authorization': authorization,
    };

    final $body = body;
    final $request =
        Request('PUT', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> setPusher(
      {required String authorization, required String body}) {
    final $url = '/_matrix/client/r0/pushers/set';
    final $headers = {
      'Authorization': authorization,
    };

    final $body = body;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> register(
      {required String kind, required String body}) {
    final $url = '/_matrix/client/r0/register';
    final $params = <String, dynamic>{'kind': kind};
    final $body = body;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, parameters: $params);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> sync(
      {required String authorization,
      required String since,
      bool fullState = false,
      required String filter,
      int timeout = 0}) {
    final $url = '/_matrix/client/r0/sync';
    final $params = <String, dynamic>{
      'since': since,
      'full_state': fullState,
      'filter': filter,
      'timeout': timeout
    };
    final $headers = {
      'Authorization': authorization,
    };

    final $request = Request('GET', $url, client.baseUrl,
        parameters: $params, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> roomMessages(
      {required String authorization,
      required String roomId,
      required String from,
      required int limit,
      String dir = 'b',
      required String filter}) {
    final $url = '/_matrix/client/r0/rooms/$roomId/messages';
    final $params = <String, dynamic>{
      'from': from,
      'limit': limit,
      'dir': dir,
      'filter': filter
    };
    final $headers = {
      'Authorization': authorization,
    };

    final $request = Request('GET', $url, client.baseUrl,
        parameters: $params, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> members(
      {required String authorization,
      required String roomId,
      required String at,
      required String membership}) {
    final $url = '/_matrix/client/r0/rooms/$roomId/members';
    final $params = <String, dynamic>{'at': at, 'membership': membership};
    final $headers = {
      'Authorization': authorization,
    };

    final $request = Request('GET', $url, client.baseUrl,
        parameters: $params, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> send(
      {required String authorization,
      required String roomId,
      required String eventType,
      required String txnId,
      required String content}) {
    final $url = '/_matrix/client/r0/rooms/$roomId/send/$eventType/$txnId';
    final $headers = {
      'Authorization': authorization,
    };

    final $body = content;
    final $request =
        Request('PUT', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> edit(
      {required String authorization,
      required String roomId,
      required String txnId,
      required String content}) {
    final $url = '/_matrix/client/r0/rooms/$roomId/send/m.room.message/$txnId';
    final $headers = {
      'Authorization': authorization,
    };

    final $body = content;
    final $request =
        Request('PUT', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> redact(
      {required String authorization,
      required String roomId,
      required String eventId,
      required String txnId,
      required String content}) {
    final $url = '/_matrix/client/r0/rooms/$roomId/send/$eventId/$txnId';
    final $headers = {
      'Authorization': authorization,
    };

    final $body = content;
    final $request =
        Request('PUT', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> sendState(
      {required String authorization,
      required String roomId,
      required String eventType,
      required String stateKey,
      required String content}) {
    final $url = '/_matrix/client/r0/rooms/$roomId/state/$eventType/$stateKey';
    final $headers = {
      'Authorization': authorization,
    };

    final $body = content;
    final $request =
        Request('PUT', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> typing(
      {required String authorization,
      required String roomId,
      required String userId,
      required String body}) {
    final $url = '/_matrix/client/r0/rooms/$roomId/typing/$userId';
    final $headers = {
      'Authorization': authorization,
    };

    final $body = body;
    final $request =
        Request('PUT', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> readMarkers(
      {required String authorization,
      required String roomId,
      required String body}) {
    final $url = '/_matrix/client/r0/rooms/$roomId/read_markers';
    final $headers = {
      'Authorization': authorization,
    };

    final $body = body;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> kick(
      {required String authorization,
      required String roomId,
      required String body}) {
    final $url = '/_matrix/client/r0/rooms/$roomId/kick';
    final $headers = {
      'Authorization': authorization,
    };

    final $body = body;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> leave(
      {required String authorization, required String roomId}) {
    final $url = '/_matrix/client/r0/rooms/$roomId/leave';
    final $headers = {
      'Authorization': authorization,
    };

    final $request = Request('POST', $url, client.baseUrl, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> createRoom(
      {required String authorization, required String body}) {
    final $url = '/_matrix/client/r0/createRoom';
    final $headers = {
      'Authorization': authorization,
    };

    final $body = body;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> join(
      {required String authorization,
      required String roomIdOrAlias,
      required String serverName}) {
    final $url = '/_matrix/client/r0/join/$roomIdOrAlias';
    final $params = <String, dynamic>{'server_name': serverName};
    final $headers = {
      'Authorization': authorization,
    };

    final $request = Request('POST', $url, client.baseUrl,
        parameters: $params, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> logout({required String authorization}) {
    final $url = '/_matrix/client/r0/logout';
    final $headers = {
      'Authorization': authorization,
    };

    final $request = Request('POST', $url, client.baseUrl, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> publicRooms(
      {required String authorization,
      required String server,
      required String body}) {
    final $url = '/_matrix/client/r0/publicRooms';
    final $params = <String, dynamic>{'server': server};
    final $headers = {
      'Authorization': authorization,
    };

    final $body = body;
    final $request = Request('POST', $url, client.baseUrl,
        body: $body, parameters: $params, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }
}
