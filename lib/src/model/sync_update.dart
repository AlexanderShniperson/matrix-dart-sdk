import 'my_user.dart';
import 'minimized_sync_update.dart';
import 'update.dart';

/// An update caused by a sync.
class SyncUpdate extends Update {
  SyncUpdate(
      MyUser user,
      MyUser delta,
      ) : super(user, delta);

  @override
  MinimizedSyncUpdate minimize() => MinimizedSyncUpdate(delta: delta);
}