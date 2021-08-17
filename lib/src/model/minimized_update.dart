import 'package:meta/meta.dart';
import 'my_user.dart';
import 'update.dart';

@immutable
abstract class MinimizedUpdate<T extends Update> {
  final MyUser delta;

  MinimizedUpdate(this.delta);

  T deminimize(MyUser user);
}