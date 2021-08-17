import 'my_user.dart';
import 'minimized_update.dart';
import 'sync_update.dart';

class MinimizedSyncUpdate extends MinimizedUpdate<SyncUpdate> {
  MinimizedSyncUpdate({
    required MyUser delta,
  }) : super(delta);

  @override
  SyncUpdate deminimize(MyUser user) => SyncUpdate(user, delta);
}
