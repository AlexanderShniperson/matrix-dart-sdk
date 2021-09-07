import 'package:matrix_sdk/src/model/next_batch_token.dart';

import '../../model/sync_filter.dart';
import '../syncer.dart';
import 'instruction.dart';
import 'isolated_updater.dart';

class IsolatedSyncer implements Syncer {
  final IsolatedUpdater _updater;

  IsolatedSyncer(this._updater);

  bool _isSyncing = false;

  @override
  bool get isSyncing => _isSyncing;

  @override
  void start({
    Duration maxRetryAfter = const Duration(seconds: 30),
    int timelineLimit = 30,
  }) {
    _updater.execute(
      StartSyncInstruction(maxRetryAfter, timelineLimit),
    );
    _isSyncing = true;
  }

  @override
  Future<void> stop() async {
    await _updater.execute(StopSyncInstruction());
    _isSyncing = false;
  }

  @override
  Future<void> runSyncOnce({
    required SyncFilter filter,
  }) async {
    await _updater.execute(RunSyncOnceInstruction(filter));
  }
}
