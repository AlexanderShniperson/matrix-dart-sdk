// Copyright (C) 2019  Wilko Manger
// Copyright (C) 2019  Mathieu Velten
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'package:chopper/chopper.dart';
import 'api.dart';

part 'client.chopper.dart';

@ChopperApi(baseUrl: '/${Api.base}/client/${Api.version}')
abstract class ClientService extends ChopperService {
  static ClientService create([ChopperClient? client]) =>
      _$ClientService(client);

  @Post(path: 'login')
  Future<Response> login(@Body() String body);

  @Get(path: 'profile/{userId}')
  Future<Response> profile({
    @Header('Authorization') required String authorization,
    @Path('userId') required String userId,
  });

  @Put(path: 'profile/{userId}/displayname')
  Future<Response> profileSetDisplayName({
    @Header('Authorization') required String authorization,
    @Path('userId') required String userId,
    @Body() required String body,
  });

  @Post(path: 'pushers/set')
  Future<Response> setPusher({
    @Header('Authorization') required String authorization,
    @Body() required String body,
  });

  @Post(path: 'register')
  Future<Response> register({
    @Query('kind') required String kind,
    @Body() required String body,
  });

  @Get(path: 'sync')
  Future<Response> sync({
    @Header('Authorization') required String authorization,
    @Query('since') required String since,
    @Query('full_state') bool fullState = false,
    @Query('filter') required String filter,
    @Query('timeout') int timeout = 0,
  });

  @Get(path: 'rooms/{roomId}/messages')
  Future<Response> roomMessages({
    @Header('Authorization') required String authorization,
    @Path('roomId') required String roomId,
    @Query('from') required String from,
    @Query('limit') required int limit,
    @Query('dir') String dir = 'b',
    @Query('filter') required String filter,
  });

  @Get(path: 'rooms/{roomId}/members')
  Future<Response> members({
    @Header('Authorization') required String authorization,
    @Path('roomId') required String roomId,
    @Query('at') required String at,
    @Query('membership') required String membership,
  });

  @Put(path: 'rooms/{roomId}/send/{eventType}/{txnId}')
  Future<Response> send({
    @Header('Authorization') required String authorization,
    @Path('roomId') required String roomId,
    @Path('eventType') required String eventType,
    @Path('txnId') required String txnId,
    @Body() required String content,
  });

  @Put(path: 'rooms/{roomId}/send/m.room.message/{txnId}')
  Future<Response> edit({
    @Header('Authorization') required String authorization,
    @Path('roomId') required String roomId,
    @Path('txnId') required String txnId,
    @Body() required String content,
  });

  @Put(path: 'rooms/{roomId}/redact/{eventId}/{txnId}')
  Future<Response> redact({
    @Header('Authorization') required String authorization,
    @Path('roomId') required String roomId,
    @Path('eventId') required String eventId,
    @Path('txnId') required String txnId,
    @Body() required String content,
  });

  @Put(path: 'rooms/{roomId}/state/{eventType}/{stateKey}')
  Future<Response> sendState({
    @Header('Authorization') required String authorization,
    @Path('roomId') required String roomId,
    @Path('eventType') required String eventType,
    @Path('stateKey') required String stateKey,
    @Body() required String content,
  });

  @Put(path: 'rooms/{roomId}/typing/{userId}')
  Future<Response> typing({
    @Header('Authorization') required String authorization,
    @Path('roomId') required String roomId,
    @Path('userId') required String userId,
    @Body() required String body,
  });

  @Post(path: 'rooms/{roomId}/read_markers')
  Future<Response> readMarkers({
    @Header('Authorization') required String authorization,
    @Path('roomId') required String roomId,
    @Body() required String body,
  });

  @Post(path: 'rooms/{roomId}/kick')
  Future<Response> kick({
    @Header('Authorization') required String authorization,
    @Path('roomId') required String roomId,
    @Body() required String body,
  });

  @Post(path: 'rooms/{roomId}/leave')
  Future<Response> leave({
    @Header('Authorization') required String authorization,
    @Path('roomId') required String roomId,
  });

  @Post(path: 'createRoom')
  Future<Response> createRoom({
    @Header('Authorization') required String authorization,
    @Body() required String body,
  });

  @Post(path: 'join/{roomIdOrAlias}')
  Future<Response> join({
    @Header('Authorization') required String authorization,
    @Path('roomIdOrAlias') required String roomIdOrAlias,
    @Query('server_name') required String serverName,
  });

  @Post(path: 'logout')
  Future<Response> logout({
    @Header('Authorization') required String authorization,
  });

  @Post(path: 'publicRooms')
  Future<Response> publicRooms({
    @Header('Authorization') required String authorization,
    @Query('server') required String server,
    @Body() required String body,
  });
}
