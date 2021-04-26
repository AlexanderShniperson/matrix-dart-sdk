// Copyright (C) 2019  Wilko Manger
// Copyright (C) 2019  Mathieu Velten
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:meta/meta.dart';

import 'api.dart';

part 'client.chopper.dart';

@ChopperApi(baseUrl: '/${Api.base}/client/${Api.version}')
abstract class ClientService extends ChopperService {
  static ClientService create([ChopperClient client]) =>
      _$ClientService(client);

  @Post(path: 'login')
  Future<Response> login(@Body() String body);

  @Get(path: 'profile/{userId}')
  Future<Response> profile({
    @Header('Authorization') @required String authorization,
    @Path('userId') @required String userId,
  });

  @Put(path: 'profile/{userId}/displayname')
  Future<Response> profileSetDisplayName({
    @Header('Authorization') @required String authorization,
    @Path('userId') @required String userId,
    @Body() @required String body,
  });

  @Post(path: 'pushers/set')
  Future<Response> setPusher({
    @required @Header('Authorization') String authorization,
    @Body() String body,
  });

  @Post(path: 'register')
  Future<Response> register({
    @Query('kind') String kind,
    @Body() String body,
  });

  @Get(path: 'sync')
  Future<Response> sync({
    @required @Header('Authorization') String authorization,
    @Query('since') @required String since,
    @Query('full_state') bool fullState = false,
    @Query('filter') String filter,
    @Query('timeout') int timeout = 0,
  });

  @Get(path: 'rooms/{roomId}/messages')
  Future<Response> roomMessages({
    @required @Header('Authorization') String authorization,
    @Path('roomId') @required String roomId,
    @Query('from') @required String from,
    @Query('limit') int limit,
    @Query('dir') String dir = 'b',
    @Query('filter') String filter,
  });

  @Get(path: 'rooms/{roomId}/members')
  Future<Response> members({
    @required @Header('Authorization') String authorization,
    @Path('roomId') @required String roomId,
    @Query('at') @required String at,
    @Query('membership') String membership,
  });

  @Put(path: 'rooms/{roomId}/send/{eventType}/{txnId}')
  Future<Response> send({
    @required @Header('Authorization') String authorization,
    @Path('roomId') @required String roomId,
    @Path('eventType') @required String eventType,
    @Path('txnId') @required String txnId,
    @Body() @required String content,
  });

  @Put(path: 'rooms/{roomId}/send/m.room.message/{txnId}')
  Future<Response> edit({
    @required @Header('Authorization') String authorization,
    @Path('roomId') @required String roomId,
    @Path('txnId') @required String txnId,
    @Body() @required String content,
  });

  @Put(path: 'rooms/{roomId}/redact/{eventId}/{txnId}')
  Future<Response> redact({
    @required @Header('Authorization') String authorization,
    @Path('roomId') @required String roomId,
    @Path('eventId') @required String eventId,
    @Path('txnId') @required String txnId,
    @Query('reason') @required String reason,
  });

  @Put(path: 'rooms/{roomId}/state/{eventType}/{stateKey}')
  Future<Response> sendState({
    @required @Header('Authorization') String authorization,
    @Path('roomId') @required String roomId,
    @Path('eventType') @required String eventType,
    @Path('stateKey') @required String stateKey,
    @Body() @required String content,
  });

  @Put(path: 'rooms/{roomId}/typing/{userId}')
  Future<Response> typing({
    @required @Header('Authorization') String authorization,
    @Path('roomId') @required String roomId,
    @Path('userId') @required String userId,
    @Body() @required String body,
  });

  @Post(path: 'rooms/{roomId}/read_markers')
  Future<Response> readMarkers({
    @required @Header('Authorization') String authorization,
    @Path('roomId') @required String roomId,
    @Body() @required String body,
  });

  @Post(path: 'rooms/{roomId}/kick')
  Future<Response> kick({
    @required @Header('Authorization') String authorization,
    @Path('roomId') @required String roomId,
    @Body() @required String body,
  });

  @Post(path: 'rooms/{roomId}/leave')
  Future<Response> leave({
    @required @Header('Authorization') String authorization,
    @Path('roomId') @required String roomId,
  });

  @Post(path: 'createRoom')
  Future<Response> createRoom({
    @required @Header('Authorization') String authorization,
    @Body() @required String body,
  });

  @Post(path: 'join/{roomIdOrAlias}')
  Future<Response> join({
    @required @Header('Authorization') String authorization,
    @Path('roomIdOrAlias') @required String roomIdOrAlias,
    @Query('server_name') String serverName,
  });

  @Post(path: 'logout')
  Future<Response> logout({
    @required @Header('Authorization') String authorization,
  });

  @Post(path: 'publicRooms')
  Future<Response> publicRooms({
    @required @Header('Authorization') String authorization,
    @Query('server') String server,
    @Body() @required String body,
  });
}
