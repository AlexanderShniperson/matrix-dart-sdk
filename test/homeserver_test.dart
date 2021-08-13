// Copyright (C) 2019  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';

import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:matrix_sdk/matrix_sdk.dart';
import 'package:test/test.dart';

import 'util.dart';

void testHomeserver() {
  group('Homeserver', () {
    group('.login ', () {
      test('returns MyUser if successful', () async {
        final hs = Homeserver(
          Uri.parse('https://pattle.im'),
          httpClient: MockClient((request) async {
            return Response(
              json.encode({
                'user_id': '@pat:pattle.im',
                'access_token': 'abc123',
                'device_id': 'GHTYAJCE',
                'well_known': {
                  'm.homeserver': {
                    'base_url': 'https://pattle.im',
                  },
                  'm.identity_server': {
                    'base_url': 'https://id.pattle.im',
                  },
                },
              }),
              200,
            );
          }),
        );

        final user = await hs.login(
          Username('pat'),
          'password',
          store: createMemoryStore(),
        );

        expect(user, isNotNull);
        expect(user.id.toString(), matches('@pat:pattle.im'));
        expect(user.accessToken, equals('abc123'));
      });

      test('returns LocalUser with given device id if none given', () async {
        final hs = Homeserver(
          Uri.parse('https://pattle.im'),
          httpClient: MockClient((request) async {
            return Response(
              json.encode({
                'user_id': '@pat:pattle.im',
                'access_token': 'abc123',
                'device_id': 'GHTYAJCE',
                'well_known': {
                  'm.homeserver': {
                    'base_url': 'https://pattle.im',
                  },
                  'm.identity_server': {
                    'base_url': 'https://id.pattle.im',
                  },
                },
              }),
              200,
            );
          }),
        );

        final user = await hs.login(
          Username('pat'),
          'password',
          store: createMemoryStore(),
        );

        expect(user.currentDevice?.id.toString(), equals('GHTYAJCE'));
      });

      test('returns LocalUser with set device id by caller', () async {
        final hs = Homeserver(
          Uri.parse('https://pattle.im'),
          httpClient: MockClient((request) async {
            return Response(
              json.encode({
                'user_id': '@pat:pattle.im',
                'access_token': 'abc123',
                'device_id': 'BLABLA',
                'well_known': {
                  'm.homeserver': {
                    'base_url': 'https://pattle.im',
                  },
                  'm.identity_server': {
                    'base_url': 'https://id.pattle.im',
                  },
                },
              }),
              200,
            );
          }),
        );

        final user = await hs.login(
          Username('pat'),
          'password',
          store: createMemoryStore(),
          device: Device(
            id: DeviceId('BLABLA'),
            name: 'Pattle Android',
          ),
        );

        expect(user.currentDevice?.id.toString(), equals('BLABLA'));
        expect(user.currentDevice?.name, equals('Pattle Android'));
      });

      test('throws ForbiddenException if password is wrong', () async {
        final hs = Homeserver(
          Uri.parse('https://pattle.im'),
          httpClient: MockClient((request) async {
            return Response(
              json.encode({'errcode': 'M_FORBIDDEN'}),
              403,
            );
          }),
        );

        expect(
          hs.login(
            Username('pat'),
            'password',
            store: createMemoryStore(),
          ),
          throwsA(isA<ForbiddenException>()),
        );
      });
    });

    test('returns a LocalUser with profile information', () async {
      final hs = Homeserver(
        Uri.parse('https://pattle.im'),
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('login')) {
            return Response(
              json.encode({
                'user_id': '@pat:pattle.im',
                'access_token': 'abc123',
                'device_id': 'BLABLA',
                'well_known': {
                  'm.homeserver': {
                    'base_url': 'https://pattle.im',
                  },
                  'm.identity_server': {
                    'base_url': 'https://id.pattle.im',
                  },
                },
              }),
              200,
            );
            // Profile call
          } else {
            return Response(
              json.encode({
                'avatar_url': 'mxc://matrix.org/SDGdghriugerRg',
                'displayname': 'Pat Pattle'
              }),
              200,
            );
          }
        }),
      );

      final user = await hs.login(
        Username('pat'),
        'password',
        store: createMemoryStore(),
      );

      expect(user.name, equals('Pat Pattle'));
      expect(
        user.avatarUrl.toString(),
        equals('mxc://matrix.org/SDGdghriugerRg'),
      );
    });

    test('.resolveDownloadUrl resolves correctly', () async {
      final hs = Homeserver(
        Uri.parse('https://pattle.im'),
      );

      final url = hs.resolveDownloadUrl(
        Uri.parse('mxc://pattle.im/s7dysd876y97'),
      );

      expect(
        url.toString(),
        equals(
          'https://pattle.im/_matrix/media/r0/download/pattle.im/s7dysd876y97',
        ),
      );
    });

    test(' Uri.resolveDownloadUrl resolves correctly', () async {
      final hs = Homeserver(
        Uri.parse('https://pattle.im'),
      );

      final url = Uri.parse('mxc://pattle.im/s7dysd876y97').resolveDownloadUrl(
        hs,
      );

      expect(
        url.toString(),
        equals(
          'https://pattle.im/_matrix/media/r0/download/pattle.im/s7dysd876y97',
        ),
      );
    });

    test('.resolveThumbnailUrl resolves correctly', () async {
      final hs = Homeserver(
        Uri.parse('https://pattle.im'),
      );

      final url = hs.resolveThumbnailUrl(
        Uri.parse('mxc://pattle.im/s7dysd876y97'),
        width: 256,
        height: 256,
        resizeMethod: ResizeMethod.crop,
      );

      expect(
        url.toString(),
        equals(
          'https://pattle.im/_matrix/media/r0/thumbnail/'
          'pattle.im/s7dysd876y97?width=256&height=256&method=crop',
        ),
      );
    });

    test(' Uri.resolveThumbnailUrl resolves correctly', () async {
      final hs = Homeserver(
        Uri.parse('https://pattle.im'),
      );

      final url = Uri.parse('mxc://pattle.im/s7dysd876y97').resolveThumbnailUrl(
        hs,
        width: 256,
        height: 256,
        resizeMethod: ResizeMethod.crop,
      );

      expect(
        url.toString(),
        equals(
          'https://pattle.im/_matrix/media/r0/thumbnail/'
          'pattle.im/s7dysd876y97?width=256&height=256&method=crop',
        ),
      );
    });
  });

  group('.fromWellKnown ', () {
    test(' will throw exception if .well-known base_url is null', () async {
      expect(
        Homeserver.fromWellKnown(
          Uri.parse('https://pattle.im'),
          httpClient: MockClient((request) async {
            return Response(
              json.encode({
                'm.homeserver': {'base_url': null},
              }),
              200,
            );
          }),
        ),
        throwsA(isA<WellKnownFailPromptException>()),
      );
    });

    test(' will remove slash suffix from url', () async {
      final hs = await Homeserver.fromWellKnown(
        Uri.parse('https://pattle.im'),
        httpClient: MockClient((request) async {
          return Response(
            json.encode({
              'm.homeserver': {
                'base_url': 'https://pattle.im/',
              },
            }),
            200,
          );
        }),
      );

      expect(hs.url.toString(), isNot(endsWith('/')));
    });
  });
}

// TODO: Handle 400
