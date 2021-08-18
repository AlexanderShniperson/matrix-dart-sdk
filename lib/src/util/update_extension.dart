import 'package:matrix_sdk/src/model/sync_update.dart';
import 'package:matrix_sdk/src/model/update.dart';

extension UpdatesExtension on Stream<Update> {
  Future<Update> get firstSync => firstWhere((u) => u is SyncUpdate);

  Stream<SyncUpdate> get onlySync => where((u) => u is SyncUpdate).cast();
}