// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:io';

import 'package:matrix_sdk/matrix_sdk.dart';

void main() async {
  final homeserver = Homeserver(Uri.parse('https://pattle.im'));

  var user = await homeserver.login(
    Username('pat'),
    'pattle',
    // Use a valid Moor backend here
    store: MoorStoreLocation.file(File('/somewhere')),
  );

  user.startSync();

  // Do something after the first sync specifically.
  var update = await user.updates.firstSync;
  // ALWAYS use the MyUser from the latest update. It will have the latest data.
  user = update.user;

  print(user.rooms.length);

  // Get more events from the timeline. This also returns an update.
  // Note that because we're doing things before we listen to updates, we
  // might miss some syncs. Even though we've missed some syncs, the update
  // received from the load is the most up to date one, and will contain a
  // user with data from processed syncs in the background.
  update = await user.rooms.first.timeline.load(count: 50);
  user = update.user;

  print(user.rooms.first.timeline.length);

  // Do something every sync. If you don't use onlySync, you will also receive
  // updates that are caused by a request (such as above). If you do a request
  // (such as timeline.load) inside a Stream with all updates, and await
  // for it also in the stream, you will use it twice.
  await for (update in user.updates.onlySync) {
    user = update.user;
  }
}
