// Copyright (C) 2019  Wilko Manger
// Copyright (C) 2019  Mathieu Velten
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
import 'dart:async';
import 'package:chopper/chopper.dart';

import 'api.dart';

part 'media.chopper.dart';

@ChopperApi(baseUrl: MediaService.baseUrl)
abstract class MediaService extends ChopperService {
  static MediaService create([ChopperClient? client]) => _$MediaService(client);

  static const baseUrl = '/${Api.base}/media/${Api.version}';
  static const downloadSegment = 'download';
  @Get(path: '$downloadSegment/{serverName}/{mediaId}')
  Future<Response<Stream<List<int>>>> download(
    @Path('serverName') String serverName,
    @Path('mediaId') String mediaId,
  );

  @Post(path: 'upload')
  Future<Response> upload(
    @Header('Authorization') String authorization,
    @Body() Stream<List<int>> byteStream,
    @Header('Content-Length') String length,
    @Header('Content-Type') String contentType,
    @Query('filename') String fileName,
  );

  static const thumbnailSegment = 'thumbnail';
  @Get(path: '$thumbnailSegment/{serverName}/{mediaId}')
  Future<Response<Stream<List<int>>>> thumbnail(
    @Path('serverName') String serverName,
    @Path('mediaId') String mediaId,
    @Query('width') int width,
    @Query('height') int height,
    @Query('method') String method,
  );
}
