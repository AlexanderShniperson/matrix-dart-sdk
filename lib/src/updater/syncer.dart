import 'package:async/async.dart';
import 'package:matrix_sdk/matrix_sdk.dart';
import 'package:matrix_sdk/src/model/models.dart';
import 'package:matrix_sdk/src/model/sync_filter.dart';

import '../homeserver.dart';

class Syncer {
  final Updater _updater;

  Homeserver get _homeserver => _updater.homeServer;
  MyUser get _user => _updater.user;

  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  Syncer(this._updater);

  Future<void>? _syncFuture;
  CancelableOperation<Map<String, dynamic>>? _cancelableSyncOnceResponse;

  /// Syncs data with the user's [_homeserver].
  void start({
    Duration maxRetryAfter = const Duration(seconds: 30),
    int timelineLimit = 30,
    String? syncToken,
  }) {
    if (_user.isLoggedOut ?? false) {
      throw StateError('The user can not be logged out');
    }

    if (_syncFuture != null) {
      return;
    }

    _syncFuture = _startSync(
      maxRetryAfter: maxRetryAfter,
      timelineLimit: timelineLimit,
      syncToken: syncToken,
    );
  }

  bool _shouldStopSync = false;

  Future<void> _startSync({
    Duration maxRetryAfter = const Duration(seconds: 30),
    int timelineLimit = 30,
    String? syncToken,
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
        syncToken: syncToken,
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
        await _updater.processSync(body);

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
    String? syncToken,
  }) async {
    if (_user.isLoggedOut ?? false) {
      throw StateError('The user can not be logged out');
    }

    if (_shouldStopSync) {
      return null;
    }

    try {
      final cancelable = CancelableOperation.fromFuture(
        _homeserver.api.sync(
          accessToken: _user.accessToken ?? '',
          since: syncToken ?? _user.syncToken ?? '',
          fullState: fullState,
          filter: {
            'room': {
              'state': {
                'lazy_load_members': true,
              },
              'timeline': {
                'limit': timelineLimit,
              },
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
      _updater.inError.add(ErrorWithStackTraceString(
        e.toString(),
        StackTrace.current.toString(),
      ));

      return null;
    }
  }

  Future<void> runSyncOnce({
    required SyncFilter filter,
  }) async {
    if (_user.isLoggedOut ?? false) {
      throw StateError('The user can not be logged out');
    }

    if (_shouldStopSync) {
      return;
    }

    try {
      final cancelable = CancelableOperation.fromFuture(
        _homeserver.api.sync(
          accessToken: _user.accessToken ?? '',
          since: filter.syncToken,
          fullState: filter.fullState,
          filter: filter.toMap(),
          timeout: 0,
        ),
      );

      _cancelableSyncOnceResponse = cancelable;
      // final initStopwatch = Stopwatch();
      // initStopwatch.start();
      final body = await cancelable.valueOrCancellation();
      // final time = initStopwatch.elapsedMilliseconds;
      // print("Stopwatch SYNC : $time");
      // initStopwatch.stop();

      // We're cancelled
      if (body == null) {
        return;
      }

      if (_shouldStopSync) {
        return;
      }

      await _updater.processSync(body);
    } on Exception catch (e) {
      _updater.inError.add(ErrorWithStackTraceString(
        e.toString(),
        StackTrace.current.toString(),
      ));
    }
  }

  Future<void> stop() async {
    _shouldStopSync = true;
    await _cancelableSyncOnceResponse?.cancel();
    await _syncFuture;
    _isSyncing = false;
  }
}
