// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:io';

import 'package:matrix_sdk/matrix_sdk.dart';
import 'package:collection/collection.dart';

void main() async {
  final client = MatrixClient(
    serverUri: Uri.parse('https://pattle.im'),
    storeLocation: MoorStoreLocation.file(File('/somewhere')),
  );
  MyUser user = await client.login(
    Username('pat'),
    'pattle',
  );

  client.startSync(user);

  // Do something after the first sync specifically.
  final update = await client.outUpdates.firstSync;
  // ALWAYS use the MyUser from the latest update. It will have the latest data.
  user = update.user;

  print(user.rooms?.length);

  // Get more events from the timeline. This also returns an update.
  // Note that because we're doing things before we listen to updates, we
  // might miss some syncs. Even though we've missed some syncs, the update
  // received from the load is the most up to date one, and will contain a
  // user with data from processed syncs in the background.
  final timeline = await user.rooms?.firstOrNull?.timeline?.load(count: 50);
  user = timeline!.user;

  print(user.rooms?.firstOrNull?.timeline?.length);

  // Do something every sync. If you don't use onlySync, you will also receive
  // updates that are caused by a request (such as above). If you do a request
  // (such as timeline.load) inside a Stream with all updates, and await
  // for it also in the stream, you will use it twice.
  // await for (update in user?.updates?.onlySync) {
  //   user = update.user;
  // }
  client.outUpdates.onlySync.listen((event) {
    user = event.user;
  });
}
