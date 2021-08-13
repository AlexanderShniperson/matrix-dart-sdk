// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// ignore_for_file: always_put_control_body_on_new_line, always_specify_types, prefer_const_declarations
class _$MediaService extends MediaService {
  _$MediaService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final definitionType = MediaService;

  @override
  Future<Response<Stream<List<int>>>> download(
      String serverName, String mediaId) {
    final $url = '/_matrix/media/r0/download/$serverName/$mediaId';
    final $request = Request('GET', $url, client.baseUrl);
    return client.send<Stream<List<int>>, int>($request);
  }

  @override
  Future<Response<dynamic>> upload(
      String authorization,
      Stream<List<int>> byteStream,
      String length,
      String contentType,
      String fileName) {
    final $url = '/_matrix/media/r0/upload';
    final $params = <String, dynamic>{'filename': fileName};
    final $headers = {
      'Authorization': authorization,
      'Content-Length': length,
      'Content-Type': contentType,
    };

    final $body = byteStream;
    final $request = Request('POST', $url, client.baseUrl,
        body: $body, parameters: $params, headers: $headers);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<Stream<List<int>>>> thumbnail(
      String serverName, String mediaId, int width, int height, String method) {
    final $url = '/_matrix/media/r0/thumbnail/$serverName/$mediaId';
    final $params = <String, dynamic>{
      'width': width,
      'height': height,
      'method': method
    };
    final $request = Request('GET', $url, client.baseUrl, parameters: $params);
    return client.send<Stream<List<int>>, int>($request);
  }
}
