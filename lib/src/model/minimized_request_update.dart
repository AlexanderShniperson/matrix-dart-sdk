import 'context.dart';
import 'my_user.dart';
import 'minimized_update.dart';
import 'request_update.dart';

class MinimizedRequestUpdate<T extends Contextual<T>>
    extends MinimizedUpdate<RequestUpdate<T>> {
  final T? deltaData;
  final RequestType type;
  final bool basedOnUpdate;

  MinimizedRequestUpdate({
    required MyUser delta,
    required this.deltaData,
    required this.type,
    required this.basedOnUpdate,
  }) : super(delta);

  @override
  RequestUpdate<T> deminimize(MyUser user) {
    final deltaData = this.deltaData;

    return RequestUpdate<T>(
      user,
      delta,
      data: deltaData is Contextual<T> ? deltaData.propertyOf(user) : null,
      deltaData: deltaData,
      type: type,
      basedOnUpdate: basedOnUpdate,
    );
  }
}
