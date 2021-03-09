# Matrix Dart SDK

  [![](https://img.shields.io/pub/v/matrix_sdk.svg)](https://pub.dartlang.org/packages/matrix_sdk)
  [![](https://img.shields.io/matrix/sdk:pattle.im.svg?server_fqdn=matrix.org)](https://matrix.to/#/#sdk:matrix.org)

  An SDK written in Dart to connect to [Matrix](https://matrix.org),
  the federated communication protocol.

  This SDK is for general use, but mainly being developed for
  [Pattle](https://pattle.im), an easy to use Matrix app.

  Please note that this SDK is still pre-1.0 and in development. Things may
  still change a lot!

## Usage

   Set the initial `MyUser`, either by logging in to a homeserver:

   ```dart
   final homeserver = Homeserver(Uri.parse('https://pattle.im'));

   var user = await homeserver.login(
     Username('pat'),
     'pattle',
     store: MemoryStore(),
   );
   ```

   Or, from a `Store`, for example, the included `MoorStore`, which uses
   [moor](https://pub.dev/packages/moor):

   ```dart
   var user = await MyUser.fromStore(
     MoorStore(
       LazyDatabase(
         () => VmDatabase(File('/somewhere')),
       ),
     ),
   );
   ```

   Once a `MyUser` has been set up, you can start syncing with:

   ```dart
   user.startSync();
   ```

   All data objects such as `MyUser`, `Room`, etc. are immutable.

   The user has a stream of `Update`s, `user.updates`. An `Update` contains
   the latest 'snapshot' of data associated with the user. It also contains
   a `delta` `MyUser`, where all properties are `null`, except those that
   are changed. For example, if a user started typing in a certain room, and we're
   syncing, there will be an `Update` in `user.updates`, where `delta` has 1
   `Room` in `delta.rooms`, with only the room where the user started typing,
   reflected in `room.typingUserIds`. All other properties of the `Room` will
   be null. This is all assuming that this is the only change in the sync.
   If more happened, it will be reflected in `delta`.

   Use `update.user` to get the complete up-to date copy of all data.
   Note that `rooms`, `timeline`s and `memberTimeline`s may not be a
   complete set of the data, more might need to be retrieved from the
   `Store` or remotely.  You can use `load` on `rooms`, `timeline` and
   `memberTimeline`, to load more items.

   ```dart
   user.startSync();

   // Do something after the first received sync specifically.
   var update = await user.updates.firstSync;

   // ALWAYS use the MyUser from the latest update.
   // It will have the latest data.
   user = update.user;

   print(user.rooms.length);

   // Get more events from the timeline. This also returns an update.
   // Note that because we're doing things before we listen to updates, we
   // might miss some syncs. Even though we've missed some syncs, the update
   // received from the load is the most up to date one, and will contain a
   // user with data from processed syncs in the background.
   update = await user.rooms.first.timeline.load(count: 50);
   user = update.user;

   // Because we called load, the update is a RequestUpdate<Timeline>,
   // which means data is the updated Timeline, now with more items.
   print(update.data.timeline.length);

   // Do something every sync. If you don't use onlySync, you will also
   // receive updates that are caused by a request (such as above, load).
   // If you do a request (such as timeline.load) inside a Stream with all
   // updates, and await for it also in the stream, you will use it twice.
   await for (update in user.updates.onlySync) {
     user = update.user;
   }
   ```

### Custom events

   The SDK also supports any custom types, using `RawRoomEvent`. To get
   `RawRoomEvent`s from the `timeline` easily, use

   ```dart
   timeline.withCustomType('my.type');
   ```

   Custom events have a `RawEventContent`, which is comparable to a
   `Map<String, dynamic>` in API. For example, to get the `name` of
   a `im.vector.modular.widgets` event:

   ```dart
   final widgetsEvent = timeline.firstWithCustomType('im.vector.modular.widgets');
   final name = widgetsEvent.content['name'];
   ```

   #### State events

   For custom state events, you can retrieve them as such:

   ```dart
   final widgetsEvent = someRoom.stateEvents['im.vector.modular.widgets']['some_key'];
   ```

## Contributing

   Contributions are encouraged!

   We use the [DCO](https://developercertificate.org/), which asserts that the
   contribution is yours, and you allow the Matrix Dart SDK to use it.

   If you agree to what's stated in the DCO (also shown under), you can
   sign-off your commits:

   ```
   Signed-off-by: Joe Smith <joe.smith@email.org>
   ```

   If your `user.name` and `user.email` are set for git, you can
   sign-off your commits using:

   ```
   git commit -s
   ```

   Contributions can only be accepted if you agree to the DCO,
   indicated by the sign-off.

### DCO

    Developer Certificate of Origin
    Version 1.1

    Copyright (C) 2004, 2006 The Linux Foundation and its contributors.
    660 York Street, Suite 102,
    San Francisco, CA 94110 USA

    Everyone is permitted to copy and distribute verbatim copies of this
    license document, but changing it is not allowed.

    Developer's Certificate of Origin 1.1

    By making a contribution to this project, I certify that:

    (a) The contribution was created in whole or in part by me and I
        have the right to submit it under the open source license
        indicated in the file; or

    (b) The contribution is based upon previous work that, to the best
        of my knowledge, is covered under an appropriate open source
        license and I have the right under that license to submit that
        work with modifications, whether created in whole or in part
        by me, under the same open source license (unless I am
        permitted to submit under a different license), as indicated
        in the file; or

    (c) The contribution was provided directly to me by some other
        person who certified (a), (b) or (c) and I have not modified
        it.

    (d) I understand and agree that this project and the contribution
        are public and that a record of the contribution (including all
        personal information I submit with it, including my sign-off) is
        maintained indefinitely and may be redistributed consistent with
        this project or the open source license(s) involved.