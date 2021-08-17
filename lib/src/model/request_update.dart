import 'context.dart';
import 'my_user.dart';
import 'minimized_request_update.dart';
import 'update.dart';

/// An update caused by a request, which has the relevant updated [data] at
/// hand for easy access, and also a [deltaData].
class RequestUpdate<T extends Contextual<T>> extends Update {
  final T? data;
  final T? deltaData;

  /// Type that caused this request.
  final RequestType type;

  /// True if this RequestUpdate was based on another update.
  final bool basedOnUpdate;

  RequestUpdate(
      MyUser user,
      MyUser deltaUser, {
        this.data,
        this.deltaData,
        required this.type,
        // Must not be set to true in most cases.
        this.basedOnUpdate = false,
      }) : super(user, deltaUser);

  /// If this constructor is used, its respective [RequestInstruction] should
  /// have `basedOnSyncUpdate` set to true.
  RequestUpdate.fromUpdate(
      Update update, {
        T? Function(MyUser user)? data,
        T? Function(MyUser delta)? deltaData,
        required RequestType type,
      }) : this(
    update.user,
    update.delta,
    data: data?.call(update.user),
    deltaData: deltaData?.call(update.delta),
    type: type,
    basedOnUpdate: true,
  );

  @override
  MinimizedRequestUpdate<T> minimize() => MinimizedRequestUpdate<T>(
    delta: delta,
    deltaData: deltaData,
    type: type,
    basedOnUpdate: basedOnUpdate,
  );
}

enum RequestType {
  kick,
  loadRoomEvents,
  loadMembers,
  loadRooms,
  logout,
  markRead,
  sendRoomEvent,
  setIsTyping,
  joinRoom,
  leaveRoom,
  setName,
  setPusher,
}