import 'package:meta/meta.dart';
import 'my_user.dart';
import 'minimized_update.dart';

/// An update to [MyUser], either because of a sync or because of a request.
@immutable
abstract class Update {
  final MyUser user;

  /// The delta [MyUser]. All properties of [delta] are null except
  /// those that are changed with this update. It's `context` and `id` will
  /// also never be null, even if unchanged, which they won't.
  ///
  /// This is useful to find out what changed between an update.
  final MyUser delta;

  Update(this.user, this.delta);

  MinimizedUpdate minimize();
}