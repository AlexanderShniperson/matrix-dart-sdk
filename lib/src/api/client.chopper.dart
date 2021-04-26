// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// ignore_for_file: always_put_control_body_on_new_line, always_specify_types, prefer_const_declarations
class _$ClientService extends ClientService {
  _$ClientService([ChopperClient client]) {
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
  Future<Response<dynamic>> profile({String authorization, String userId}) {
    final $url = '/_matrix/client/r0/profile/$userId';
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> profileSetDisplayName(
      {String authorization, String userId, String body}) {
    final $url = '/_matrix/client/r0/profile/$userId/displayname';
    final $headers = {'Authorization': authorization};
    final $body = body;
    final $request =
        Request('PUT', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> setPusher({String authorization, String body}) {
    final $url = '/_matrix/client/r0/pushers/set';
    final $headers = {'Authorization': authorization};
    final $body = body;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> register({String kind, String body}) {
    final $url = '/_matrix/client/r0/register';
    final $params = <String, dynamic>{'kind': kind};
    final $body = body;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, parameters: $params);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> sync(
      {String authorization,
      String since,
      bool fullState = false,
      String filter,
      int timeout = 0}) {
    final $url = '/_matrix/client/r0/sync';
    final $params = <String, dynamic>{
      'since': since,
      'full_state': fullState,
      'filter': filter,
      'timeout': timeout
    };
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl,
        parameters: $params, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> roomMessages(
      {String authorization,
      String roomId,
      String from,
      int limit,
      String dir = 'b',
      String filter}) {
    final $url = '/_matrix/client/r0/rooms/$roomId/messages';
    final $params = <String, dynamic>{
      'from': from,
      'limit': limit,
      'dir': dir,
      'filter': filter
    };
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl,
        parameters: $params, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> members(
      {String authorization, String roomId, String at, String membership}) {
    final $url = '/_matrix/client/r0/rooms/$roomId/members';
    final $params = <String, dynamic>{'at': at, 'membership': membership};
    final $headers = {'Authorization': authorization};
    final $request = Request('GET', $url, client.baseUrl,
        parameters: $params, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> send(
      {String authorization,
      String roomId,
      String eventType,
      String txnId,
      String content}) {
    final $url = '/_matrix/client/r0/rooms/$roomId/send/$eventType/$txnId';
    final $headers = {'Authorization': authorization};
    final $body = content;
    final $request =
        Request('PUT', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> edit(
      {String authorization, String roomId, String txnId, String content}) {
    final $url = '/_matrix/client/r0/rooms/$roomId/send/m.room.message/$txnId';
    final $headers = {'Authorization': authorization};
    final $body = content;
    final $request =
        Request('PUT', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> redact(
      {String authorization,
      String roomId,
      String eventId,
      String txnId,
      String reason}) {
    final $url = '/_matrix/client/r0/rooms/$roomId/redact/$eventId/$txnId';
    final $params = <String, dynamic>{'reason': reason};
    final $headers = {'Authorization': authorization};
    final $request = Request('PUT', $url, client.baseUrl,
        parameters: $params, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> sendState(
      {String authorization,
      String roomId,
      String eventType,
      String stateKey,
      String content}) {
    final $url = '/_matrix/client/r0/rooms/$roomId/state/$eventType/$stateKey';
    final $headers = {'Authorization': authorization};
    final $body = content;
    final $request =
        Request('PUT', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> typing(
      {String authorization, String roomId, String userId, String body}) {
    final $url = '/_matrix/client/r0/rooms/$roomId/typing/$userId';
    final $headers = {'Authorization': authorization};
    final $body = body;
    final $request =
        Request('PUT', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> readMarkers(
      {String authorization, String roomId, String body}) {
    final $url = '/_matrix/client/r0/rooms/$roomId/read_markers';
    final $headers = {'Authorization': authorization};
    final $body = body;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> kick(
      {String authorization, String roomId, String body}) {
    final $url = '/_matrix/client/r0/rooms/$roomId/kick';
    final $headers = {'Authorization': authorization};
    final $body = body;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> leave({String authorization, String roomId}) {
    final $url = '/_matrix/client/r0/rooms/$roomId/leave';
    final $headers = {'Authorization': authorization};
    final $request = Request('POST', $url, client.baseUrl, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> createRoom({String authorization, String body}) {
    final $url = '/_matrix/client/r0/createRoom';
    final $headers = {'Authorization': authorization};
    final $body = body;
    final $request =
        Request('POST', $url, client.baseUrl, body: $body, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> join(
      {String authorization, String roomIdOrAlias, String serverName}) {
    final $url = '/_matrix/client/r0/join/$roomIdOrAlias';
    final $params = <String, dynamic>{'server_name': serverName};
    final $headers = {'Authorization': authorization};
    final $request = Request('POST', $url, client.baseUrl,
        parameters: $params, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> logout({String authorization}) {
    final $url = '/_matrix/client/r0/logout';
    final $headers = {'Authorization': authorization};
    final $request = Request('POST', $url, client.baseUrl, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> publicRooms(
      {String authorization, String server, String body}) {
    final $url = '/_matrix/client/r0/publicRooms';
    final $params = <String, dynamic>{'server': server};
    final $headers = {'Authorization': authorization};
    final $body = body;
    final $request = Request('POST', $url, client.baseUrl,
        body: $body, parameters: $params, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }
}
