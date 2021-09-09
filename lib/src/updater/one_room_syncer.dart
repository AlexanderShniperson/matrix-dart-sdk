import 'dart:async';

import 'package:async/async.dart';
import 'package:matrix_sdk/matrix_sdk.dart';
import 'package:matrix_sdk/src/model/models.dart';
import 'package:matrix_sdk/src/model/sync_filter.dart';
import 'package:synchronized/synchronized.dart';

import '../homeserver.dart';

class OneRoomSyncer {

  final Homeserver _homeserver;
  final String _roomID;
  MyUser _user;
  final Room? _room;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  String? _syncToken;

  final _lock = Lock();

  OneRoomSyncer(this._homeserver, this._user, this._roomID, this._room);

  Future<void>? _syncFuture;
  CancelableOperation<Map<String, dynamic>>? _cancelableSyncOnceResponse;

  final _updatesSubject = StreamController<Update>.broadcast();
  Stream<Update> get outUpdates => _updatesSubject.stream;

  final _errorSubject = StreamController<ErrorWithStackTraceString>.broadcast();
  Stream<ErrorWithStackTraceString> get outError => _errorSubject.stream;

  /// Syncs data with the user's [_homeserver].
  void start({
    Duration maxRetryAfter = const Duration(seconds: 30),
    int timelineLimit = 30,
  }) {
    if (_syncFuture != null) {
      return;
    }

    _syncFuture = _startSync(
      maxRetryAfter: maxRetryAfter,
      timelineLimit: timelineLimit,
    );
  }

  /// Remember to call this method on instance deinit
  void clear() {
    _errorSubject.close();
    _updatesSubject.close();
  }

  bool _shouldStopSync = false;

  Future<void> _startSync({
    Duration maxRetryAfter = const Duration(seconds: 30),
    int timelineLimit = 30,
  }) async {
    _shouldStopSync = false;
    _isSyncing = true;

    // This var is used to implements exponential backoff
    // until it reaches maxRetryAfter
    var retryAfter = 1000;

    while (!_shouldStopSync) {
      final body = await _sync(
        timeout: Duration(seconds: 10),
        timelineLimit: timelineLimit,
      );

      if (_shouldStopSync) {
        return;
      }

      if (body == null) {
        await Future.delayed(Duration(milliseconds: retryAfter));

        // ignore: invariant_booleans
        if (_shouldStopSync) {
          return;
        }

        retryAfter = (retryAfter * 1.5).floor();
        if (retryAfter > maxRetryAfter.inMilliseconds) {
          retryAfter = maxRetryAfter.inMilliseconds;
        }
      } else {
        _syncToken = body['next_batch']?.toString();
        await processSync(body);

        // Reset exponential backoff.
        retryAfter = 1000;

        await Future.delayed(Duration(milliseconds: retryAfter));
      }
    }
  }

  Future<Map<String, dynamic>?> _sync({
    timeout = Duration.zero,
    int timelineLimit = 30,
    bool fullState = false,
  }) async {
    if (_shouldStopSync) {
      return null;
    }

    try {
      final cancelable = CancelableOperation.fromFuture(
        _homeserver.api.sync(
          accessToken: _user.accessToken ?? '',
          since: _syncToken ?? '',
          fullState: fullState,
          filter: {
            'room': {
              'state': {
                'lazy_load_members': true,
              },
              'timeline': {
                'limit': timelineLimit,
              },
              'rooms': [_roomID]
            },
          },
          timeout: timeout.inMilliseconds,
        ),
      );

      _cancelableSyncOnceResponse = cancelable;

      final body = await cancelable.valueOrCancellation();

      // We're cancelled
      if (body == null) {
        return null;
      }

      if (_shouldStopSync) {
        return null;
      }

      return body;
    } on Exception catch (e) {
      _errorSubject.add(ErrorWithStackTraceString(
        e.toString(),
        StackTrace.current.toString(),
      ));

      return null;
    }
  }

  Future<void> stop() async {
    _shouldStopSync = true;
    await _cancelableSyncOnceResponse?.cancel();
    await _syncFuture;
    _isSyncing = false;
  }
  Future<void> processSync(Map<String, dynamic> body) async {
    final roomDeltas = await _processRooms(body);

    if (roomDeltas.isNotEmpty) {
      await _update(
        _user.delta(
          rooms: roomDeltas,
          hasSynced: !(_user.hasSynced ?? false) ? true : null,
        )!,
            (user, delta) => SyncUpdate(user, delta),
      );
    }
  }

  Future<U> _update<U extends Update>(
      MyUser delta,
      U Function(MyUser user, MyUser delta) createUpdate,
      ) async {
    return _lock.synchronized(() async {
      _user = _user.merge(delta);

      final update = createUpdate(_user, delta);
      _updatesSubject.add(update);
      return update;
    });
  }

  /// Returns list of room delta.
  Future<List<Room>> _processRooms(Map<String, dynamic> body) async {
    final jRooms = body['rooms'];

    const join = 'join';
    const invite = 'invite';
    const leave = 'leave';

    Future<List<Room>?> process(
        Map<String, dynamic>? rooms, {
          required String type,
        }) async {
      final roomDeltas = <Room>[];

      if (rooms != null) {
        for (final entry in rooms.entries) {
          final roomId = RoomId(entry.key);
          final json = entry.value;

          final currentRoom = _room ?? _user.rooms?[roomId] ??
              Room.base(
                context: Context(myId: _user.id),
                id: roomId,
              );
          final isNewRoom = _user.rooms?.any((p0) => p0.id.value == roomId.value) == true;

          var roomDelta = Room.fromJson(json, context: currentRoom.context!);

          // Set previous batch to null if it wasn't set by sync before
          if (!(currentRoom.timeline?.previousBatchSetBySync ?? true)) {
            roomDelta = roomDelta.copyWith(
              // We can't use copyWith because we're setting previousBatch to
              // null again
              timeline: Timeline(
                roomDelta.timeline!,
                context: roomDelta.context,
                previousBatch: null,
                previousBatchSetBySync: false,
              ),
            );
          }

          final accountData = body['account_data'];
          // Process account data
          if (accountData != null) {
            final events = accountData['events'] as List<dynamic>;

            final event = events.firstWhere(
                  (event) => event['type'] == 'm.direct',
              orElse: () => null,
            );

            if (event != null) {
              final content = event['content'] as Map<String, dynamic>;

              for (final entry in content.entries) {
                final userId = entry.key;
                final roomIds = entry.value;

                if (UserId.isValidFullyQualified(userId) &&
                    roomIds.contains(roomId.toString())) {
                  roomDelta = roomDelta.copyWith(directUserId: UserId(userId));
                  break;
                }
              }
            }
          }

          // Process redactions
          // TODO: Redaction deltas
          for (final event
          in currentRoom.timeline!.whereType<RedactionEvent>()) {
            final redactedId = event.redacts;

            final original = currentRoom.timeline?[redactedId];
            if (original != null && original is! RedactedEvent) {
              final newTimeline = currentRoom.timeline!.merge(
                Timeline(
                  [
                    ...currentRoom.timeline!.where((e) => e.id != redactedId),
                    RedactedEvent.fromRedaction(
                      redaction: event,
                      original: original,
                    ),
                  ],
                  context: currentRoom.context,
                ),
              );

              roomDelta = roomDelta.copyWith(timeline: newTimeline!);
            }
          }

          if (isNewRoom) {
            roomDelta = currentRoom.merge(roomDelta);
          }

          roomDeltas.add(roomDelta);
        }

        return roomDeltas;
      }

      return null;
    }

    final joins =
        jRooms == null ? [] : ((await process(jRooms[join], type: join)) ?? []);
    final invites = jRooms == null
    ? []
        : ((await process(jRooms[invite], type: invite)) ?? []);
    final leaves = jRooms == null
    ? []
        : ((await process(jRooms[leave], type: leave)) ?? []);
    return [
    ...joins,
    ...invites,
    ...leaves,
    ];
  }
}