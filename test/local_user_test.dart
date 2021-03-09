// Copyright (C) 2019  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:matrix_sdk/matrix_sdk.dart';
import 'package:test/test.dart';

import 'util.dart';

void testLocalUser() {
  group('LocalUser', () {
    group('Sync', () {
      Homeserver hs;
      MyUser user;

      setUp(() async {
        hs = Homeserver(
          Uri.parse('https://pattle.im'),
          httpClient: MockClient((request) async {
            if (request.url.path.endsWith('login')) {
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
            } else {
              return Response(
                '''
                {
                  "next_batch": "s72595_4483_1934",
                  "presence": {
                    "events": [
                      {
                        "content": {
                          "avatar_url": "mxc://localhost:wefuiwegh8742w",
                          "last_active_ago": 2478593,
                          "presence": "online",
                          "currently_active": false,
                          "status_msg": "Making cupcakes"
                        },
                        "type": "m.presence",
                        "sender": "@example:localhost"
                      }
                    ]
                  },
                  "account_data": {
                    "events": [
                      {
                        "type": "org.example.custom.config",
                        "content": {
                          "custom_config_key": "custom_config_value"
                        }
                      }
                    ]
                  },
                  "rooms": {
                    "join": {
                      "!726s6s6q:example.com": {
                        "summary": {
                          "m.heroes": [
                            "@alice:example.com",
                            "@bob:example.com"
                          ],
                          "m.joined_member_count": 2,
                          "m.invited_member_count": 0
                        },
                        "state": {
                          "events": [
                            {
                              "content": {
                                "membership": "join",
                                "avatar_url": "mxc://example.org/SEsfnsuifSDFSSEF",
                                "displayname": "Alice Margatroid"
                              },
                              "type": "m.room.member",
                              "event_id": "\$143273582443PhrSn:example.org",
                              "room_id": "!726s6s6q:example.com",
                              "sender": "@example:example.org",
                              "origin_server_ts": 1432735824653,
                              "unsigned": {
                                "age": 1234
                              },
                              "state_key": "@alice:example.org"
                            }
                          ]
                        },
                        "timeline": {
                          "events": [
                            {
                              "content": {
                                "membership": "join",
                                "avatar_url": "mxc://example.org/SEsfnsuifSDFSSEF",
                                "displayname": "Alice Margatroid"
                              },
                              "type": "m.room.member",
                              "event_id": "\$143273582443PhrSn:example.org",
                              "room_id": "!726s6s6q:example.com",
                              "sender": "@example:example.org",
                              "origin_server_ts": 1432735824653,
                              "unsigned": {
                                "age": 1234
                              },
                              "state_key": "@alice:example.org"
                            },
                            {
                              "content": {
                                "body": "This is an example text message",
                                "msgtype": "m.text",
                                "format": "org.matrix.custom.html",
                                "formatted_body": "<b>This is an example text message</b>"
                              },
                              "type": "m.room.message",
                              "event_id": "\$143273582443PhrSn:example.org",
                              "room_id": "!726s6s6q:example.com",
                              "sender": "@example:example.org",
                              "origin_server_ts": 1432735824653,
                              "unsigned": {
                                "age": 1234
                              }
                            }
                          ],
                          "limited": true,
                          "prev_batch": "t34-23535_0_0"
                        },
                        "ephemeral": {
                          "events": [
                            {
                              "content": {
                                "user_ids": [
                                  "@alice:matrix.org",
                                  "@bob:example.com"
                                ]
                              },
                              "type": "m.typing",
                              "room_id": "!jEsUZKDJdhlrceRyVU:example.org"
                            }
                          ]
                        },
                        "account_data": {
                          "events": [
                            {
                              "content": {
                                "tags": {
                                  "u.work": {
                                    "order": 0.9
                                  }
                                }
                              },
                              "type": "m.tag"
                            },
                            {
                              "type": "org.example.custom.room.config",
                              "content": {
                                "custom_config_key": "custom_config_value"
                              }
                            }
                          ]
                        }
                      }
                    },
                    "invite": {
                      "!696r7674:example.com": {
                        "invite_state": {
                          "events": [
                            {
                              "sender": "@alice:example.com",
                              "type": "m.room.name",
                              "state_key": "",
                              "content": {
                                "name": "My Room Name"
                              }
                            },
                            {
                              "sender": "@alice:example.com",
                              "type": "m.room.member",
                              "state_key": "@bob:example.com",
                              "content": {
                                "membership": "invite"
                              }
                            }
                          ]
                        }
                      }
                    },
                    "leave": {}
                  }
                }

                ''',
                200,
              );
            }
          }),
        );
        user = await hs.login(
          Username('pat'),
          'password',
          store: createMemoryStore(),
        );
      });

      test('stops sync process', () async {
        StreamSubscription sub;
        sub = user.updates.listen((_) async {
          expect(user.isSyncing, isTrue);
          await user.stopSync();
          expect(user.isSyncing, isFalse);

          await sub.cancel();
        });

        user.startSync();
      });

      test('.updates delta has correct rooms', () async {
        StreamSubscription sub;
        sub = user.updates.listen((update) {
          final room = update.delta.rooms.first;

          expect(room.id, RoomId('!726s6s6q:example.com'));
          expect(room.summary.joinedMembersCount, 2);

          user.stopSync();
          sub.cancel();
        });

        user.startSync();
      });
    });

    test('.pushers.set does not raise an error if sucessful', () async {
      var hs = Homeserver(
        Uri.parse('https://pattle.im'),
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('login')) {
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
          } else {
            return Response(
              json.encode({}),
              200,
            );
          }
        }),
      );
      var user = await hs.login(
        Username('pat'),
        'password',
        store: createMemoryStore(),
      );

      await user.pushers.add(
        HttpPusher(
          key: 'APA91bHPRgkF3JUikC4ENAHEeMrd41Zxv3hVZjC9KtT8OvPVGJ',
          appId: 'im.pattle.app.android',
          appName: 'Pattle',
          deviceName: 'Android',
          url: Uri.parse(
            'https://push-gateway.location.here/_matrix/push/v1/notify',
          ),
        ),
      );
    });
  });
}

// TODO: Handle 400
