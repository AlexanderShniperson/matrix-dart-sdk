import 'package:meta/meta.dart';

@immutable
abstract class Instruction<T> {
  /// Whether the instruction expects a return value. Can also be true if
  /// it needs to await on a Future, even though it returns nothing (void).
  bool get expectsReturnValue => true;
}