class SyncFilter {
  final int timelineLimit;
  final bool fullState;
  final List<String> roomIDs;
  final String syncToken;

  SyncFilter(
      {this.timelineLimit = 30,
      this.fullState = false,
      this.roomIDs = const <String>[],
      this.syncToken = ""});

  Map<String, dynamic> toMap() {
    final filterParams = {
      'room': {
        'state': {
          'lazy_load_members': true,
        },
        'timeline': {
          'limit': timelineLimit,
        },
      }
    };

    if (roomIDs.isNotEmpty) {
      (filterParams['room'] as Map)['rooms'] =
          roomIDs;
    }

    return filterParams;
  }
}
