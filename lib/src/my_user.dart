// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:meta/meta.dart';
import 'package:quiver/core.dart';

import 'context.dart';
import 'room/room.dart';
import 'room/rooms.dart';
import 'device.dart';
import 'identifier.dart';
import 'notifications/pushers.dart';
import 'store/store.dart';
import 'updater/updater.dart';
import 'matrix_user.dart';
import 'model/error_with_stacktrace.dart';
import 'util/nullable_extension.dart';

/// A user which is authenticated and can send messages, join rooms etc.
@immutable
class MyUser extends MatrixUser implements Contextual<MyUser> {
  @override
  final Context? context;

  @override
  final UserId id;

  @override
  final String name;

  @override
  final Uri? avatarUrl;

  final String? accessToken;

  final String? syncToken;

  final Device? currentDevice;

  final Rooms? rooms;

  final Pushers? pushers;

  /// Whether this user has been synchronized fully at least once.
  final bool? hasSynced;

  final bool? isLoggedOut;

  MyUser({
    required this.id,
    this.name = "",
    this.avatarUrl,
    this.accessToken = "",
    this.syncToken = "",
    this.currentDevice,
    this.rooms,
    this.hasSynced,
    this.isLoggedOut,
  })  : context = Context(myId: id),
        pushers = Pushers(Context(myId: id));

  MyUser.base({
    required UserId id,
    String name = "",
    Uri? avatarUrl,
    String accessToken = "",
    String syncToken = "",
    Device? currentDevice,
    bool hasSynced = false,
    bool isLoggedOut = false,
  }) : this(
          id: id,
          name: name,
          avatarUrl: avatarUrl,
          accessToken: accessToken,
          syncToken: syncToken,
          currentDevice: currentDevice,
          rooms: Rooms.empty(context: Context(myId: id)),
          hasSynced: hasSynced,
          isLoggedOut: isLoggedOut,
        );

  /// Retrieve a [MyUser] from a given [store].
  ///
  /// If [roomIds] is given, only the rooms with those ids will be loaded.
  ///
  /// Use [timelineLimit] to control the maximum amount of messages that
  /// are loaded in each room's timeline.
  ///
  /// If [isolated] is true, sync and other requests are processed in a
  /// different [Isolate].
  static Future<MyUser?> fromStore(
    StoreLocation storeLocation, {
    Iterable<RoomId>? roomIds,
    int timelineLimit = 15,
    bool isolated = false,
  }) async {
    final store = storeLocation.create();

    store.open();

    return store.getMyUser(
      roomIds: roomIds,
      timelineLimit: timelineLimit,
      isolated: isolated,
      storeLocation: storeLocation,
    );
  }

  MyUser copyWith({
    UserId? id,
    String? name,
    Uri? avatarUrl,
    String? accessToken,
    String? syncToken,
    Device? currentDevice,
    Rooms? rooms,
    bool? hasSynced,
    bool? isLoggedOut,
  }) {
    rooms ??= this.rooms;

    if (id != null && id != this.id) {
      rooms = rooms?.copyWith(context: Context(myId: id));
    }

    return MyUser(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      accessToken: accessToken ?? this.accessToken,
      syncToken: syncToken ?? this.syncToken,
      currentDevice: currentDevice ?? this.currentDevice,
      rooms: rooms,
      hasSynced: hasSynced ?? this.hasSynced,
      isLoggedOut: isLoggedOut ?? this.isLoggedOut,
    );
  }

  MyUser merge(MyUser? other) {
    if (other == null) {
      return this;
    }

    return copyWith(
      id: other.id,
      name: other.name,
      avatarUrl: other.avatarUrl,
      accessToken: other.accessToken,
      syncToken: other.syncToken,
      currentDevice:
          currentDevice?.merge(other.currentDevice) ?? other.currentDevice,
      rooms: rooms?.merge(other.rooms) ?? other.rooms,
      hasSynced: other.hasSynced,
      isLoggedOut: other.isLoggedOut,
    );
  }

  @override
  MyUser? delta({
    String? name,
    Uri? avatarUrl,
    String? accessToken,
    String? syncToken,
    Device? currentDevice,
    Iterable<Room>? rooms,
    bool? hasSynced,
    bool? isLoggedOut,
  }) {
    return MyUser(
      id: id,
      name: name ?? this.name,
      avatarUrl: avatarUrl,
      accessToken: accessToken,
      syncToken: syncToken ?? this.syncToken,
      currentDevice: currentDevice,
      rooms: (rooms == null) ? this.rooms : this.rooms?.delta(rooms: rooms),
      hasSynced: hasSynced ?? this.hasSynced,
      isLoggedOut: isLoggedOut ?? this.isLoggedOut,
    );
  }

  @override
  bool operator ==(dynamic other) =>
      other is MyUser &&
      super == other &&
      id == other.id &&
      name == other.name &&
      avatarUrl == other.avatarUrl &&
      accessToken == other.accessToken &&
      currentDevice == other.currentDevice &&
      rooms == other.rooms &&
      isLoggedOut == other.isLoggedOut;

  @override
  int get hashCode => hashObjects([
        super.hashCode,
        id,
        name,
        avatarUrl,
        accessToken,
        currentDevice,
        rooms,
        isLoggedOut,
      ]);

  /// Get all invites for this user. Note that for now this will load
  /// all rooms to memory.
  /*Future<List<Invite>> get invites async =>
      (await _rooms.get(where: (r) => r is InvitedRoom))
          .map((r) => Invite._(scope, r))
          .toList(growable: false);*/

  /// Set the display name of this user to the given value.
  ///
  /// Returns the [Update] where [MyUser] has it's name set to [name]`,
  /// if successful.
  Future<RequestUpdate<MyUser>?> setName(String name) {
    final result = context?.updater.let((value) {
      return value.setName(name: name);
    });
    return result ?? Future.value(null);
  }

  /// Invalidates the access token of the user. Makes all
  /// [MyUser] calls unusable.
  ///
  /// Returns the [Update] where [MyUser] has logged out, if successful.
  Future<RequestUpdate<MyUser>?> logout() {
    final result = context?.updater.let((value) {
      return value.logout();
    });
    return result ?? Future.value(null);
  }

  /// Send all unsent messages still in the [Store].
  /*Future<void> sendAllUnsent() async {
    for (Room room in await rooms.get()) {
      if (room is JoinedRoom) {
        for (RoomEvent event in await _store.getUnsentEvents(room)) {
          await for (final _ in room.send(
            event.content,
            transactionId: event.transactionId,
          )) {}
        }
      }
    }
  }*/

  /// Unlike other contextual methods, depends on the current [accessToken] and
  /// [isLoggedOut].
  Future<Uri?> upload({
    required Stream<List<int>> bytes,
    required int length,
    required String contentType,
    required String fileName,
  }) {
    final result = context?.homeServer.let((value) {
      return value.upload(
        as: this,
        bytes: bytes,
        length: length,
        contentType: contentType,
        fileName: fileName,
      );
    });
    return result ?? Future.value(null);
  }

  Stream<Update>? get updates => context?.updater?.updates;

  Stream<ErrorWithStackTraceString>? get outError => context?.updater?.outError;

  bool get isSyncing => context?.updater?.syncer.isSyncing ?? false;

  void startSync({
    Duration maxRetryAfter = const Duration(seconds: 30),
    int timelineLimit = 30,
  }) {
    context?.updater?.syncer.start(
      maxRetryAfter: maxRetryAfter,
      timelineLimit: timelineLimit,
    );
  }

  Future<void> stopSync() {
    final result = context?.updater.let((value) {
      return value.syncer.stop();
    });
    return result ?? Future.value();
  }

  @override
  MyUser propertyOf(MyUser user) => user;
}
