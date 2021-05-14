// Copyright (C) 2020  Mathieu Velten
// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:moor/backends.dart';
import 'package:moor/moor.dart';

import '../../event/room/state/member_change_event.dart';

part 'database.g.dart';

@DataClassName('MyUserRecord')
class MyUsers extends Table {
  TextColumn get homeserver => text().nullable()();

  TextColumn get id => text().nullable()();
  TextColumn get name => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get accessToken => text().nullable()();
  TextColumn get syncToken => text().nullable()();

  TextColumn get currentDeviceId =>
      text().nullable().customConstraint('REFERENCES devices(id)')();

  BoolColumn get hasSynced => boolean().nullable()();

  BoolColumn get isLoggedOut => boolean().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RoomRecord')
class Rooms extends Table {
  TextColumn get myMembership => text().nullable()();

  TextColumn get id => text()();

  TextColumn get timelinePreviousBatch => text().nullable()();
  BoolColumn get timelinePreviousBatchSetBySync => boolean().nullable()();

  IntColumn get summaryJoinedMembersCount => integer().nullable()();
  IntColumn get summaryInvitedMembersCount => integer().nullable()();

  TextColumn get nameChangeEventId =>
      text().customConstraint('REFERENCES room_events(id)').nullable()();
  TextColumn get avatarChangeEventId =>
      text().customConstraint('REFERENCES room_events(id)').nullable()();
  TextColumn get topicChangeEventId =>
      text().customConstraint('REFERENCES room_events(id)').nullable()();
  TextColumn get powerLevelsChangeEventId =>
      text().customConstraint('REFERENCES room_events(id)').nullable()();
  TextColumn get joinRulesChangeEventId =>
      text().customConstraint('REFERENCES room_events(id)').nullable()();
  TextColumn get canonicalAliasChangeEventId =>
      text().customConstraint('REFERENCES room_events(id)').nullable()();
  TextColumn get creationEventId =>
      text().customConstraint('REFERENCES room_events(id)').nullable()();
  TextColumn get upgradeEventId =>
      text().customConstraint('REFERENCES room_events(id)').nullable()();

  IntColumn get highlightedUnreadNotificationCount => integer().nullable()();
  IntColumn get totalUnreadNotificationCount => integer().nullable()();

  TextColumn get directUserId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RoomEventRecord')
class RoomEvents extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get roomId =>
      text().customConstraint('REFERENCES room_events(id)')();
  TextColumn get senderId => text()();
  DateTimeColumn get time => dateTime().nullable()();
  TextColumn get content => text().nullable()();
  TextColumn get previousContent => text().nullable()();
  TextColumn get sentState => text().nullable()();
  TextColumn get transactionId => text().nullable()();
  TextColumn get stateKey => text().nullable()();
  TextColumn get redacts => text().nullable()();
  BoolColumn get inTimeline => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('EphemeralEventRecord')
class EphemeralEvents extends Table {
  TextColumn get type => text()();
  TextColumn get roomId =>
      text().customConstraint('REFERENCES room_events(id)')();
  TextColumn get content => text().nullable()();

  @override
  Set<Column> get primaryKey => {type, roomId};
}

@DataClassName('DeviceRecord')
class Devices extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text().nullable()();
  DateTimeColumn get lastSeen => dateTime().nullable()();
  TextColumn get lastIpAddress => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@UseMoor(tables: [MyUsers, Rooms, RoomEvents, EphemeralEvents, Devices])
class Database extends _$Database {
  Database(DelegatedDatabase delegate) : super(delegate);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => destructiveFallback;

  Future<MyUserRecordWithDeviceRecord?> getMyUserRecord() {
    return (select(myUsers).join([
      leftOuterJoin(
        devices,
        devices.id.equalsExp(myUsers.currentDeviceId),
      )
    ])
          ..limit(1))
        .map(
          (r) => MyUserRecordWithDeviceRecord(
            myUserRecord: r.readTable(myUsers),
            deviceRecord: r.readTable(devices),
          ),
        )
        .getSingleOrNull();
  }

  Future<void> setMyUser(MyUsersCompanion companion) async {
    // TODO: Use insertOnConflictUpdate when released
    await batch((batch) {
      batch.insert(myUsers, companion, mode: InsertMode.insertOrIgnore);
      batch.update<$MyUsersTable, MyUserRecord>(
        myUsers,
        companion,
        where: (tbl) => tbl.id.equals(companion.id.value),
      );
    });
  }

  Future<List<RoomRecordWithStateRecords>> getRoomRecords(
    Iterable<String>? roomIds,
  ) {
    final nameChangeAlias = alias(roomEvents, 'name_change');
    final avatarChangeAlias = alias(roomEvents, 'avatar_change');
    final topicChangeAlias = alias(roomEvents, 'topic_change');
    final powerLevelsChangeAlias = alias(roomEvents, 'power_levels_change');
    final joinRulesChangeAlias = alias(roomEvents, 'join_rules_change');
    final canonicalAliasChangeAlias = alias(
      roomEvents,
      'canonical_alias_change',
    );
    final creationAlias = alias(roomEvents, 'creation');
    final upgradeAlias = alias(roomEvents, 'upgrade');

    final query = select(rooms).join([
      leftOuterJoin(
        nameChangeAlias,
        nameChangeAlias.id.equalsExp(rooms.nameChangeEventId),
      ),
      leftOuterJoin(
        avatarChangeAlias,
        avatarChangeAlias.id.equalsExp(rooms.avatarChangeEventId),
      ),
      leftOuterJoin(
        topicChangeAlias,
        topicChangeAlias.id.equalsExp(rooms.topicChangeEventId),
      ),
      leftOuterJoin(
        powerLevelsChangeAlias,
        powerLevelsChangeAlias.id.equalsExp(rooms.powerLevelsChangeEventId),
      ),
      leftOuterJoin(
        joinRulesChangeAlias,
        joinRulesChangeAlias.id.equalsExp(rooms.joinRulesChangeEventId),
      ),
      leftOuterJoin(
        canonicalAliasChangeAlias,
        canonicalAliasChangeAlias.id.equalsExp(
          rooms.canonicalAliasChangeEventId,
        ),
      ),
      leftOuterJoin(
        creationAlias,
        creationAlias.id.equalsExp(rooms.creationEventId),
      ),
      leftOuterJoin(
        upgradeAlias,
        upgradeAlias.id.equalsExp(rooms.upgradeEventId),
      ),
    ]);

    if (roomIds != null) {
      query.where(rooms.id.isIn(roomIds));
    }

    return query
        .map(
          (r) => RoomRecordWithStateRecords(
            roomRecord: r.readTable(rooms),
            nameChangeRecord: r.readTableOrNull(nameChangeAlias),
            avatarChangeRecord: r.readTableOrNull(avatarChangeAlias),
            topicChangeRecord: r.readTableOrNull(topicChangeAlias),
            powerLevelsChangeRecord: r.readTableOrNull(powerLevelsChangeAlias),
            joinRulesChangeRecord: r.readTableOrNull(joinRulesChangeAlias),
            canonicalAliasChangeRecord:
                r.readTableOrNull(canonicalAliasChangeAlias),
            creationRecord: r.readTableOrNull(creationAlias),
            upgradeRecord: r.readTableOrNull(upgradeAlias),
          ),
        )
        .get();
  }

  Future<void> setRooms(List<RoomsCompanion> companions) async {
    // TODO: Use insertOnConflictUpdate when released
    await batch((batch) async {
      for (final companion in companions) {
        batch.insert(rooms, companion, mode: InsertMode.insertOrIgnore);
        batch.update<$RoomsTable, RoomRecord>(
          rooms,
          companion,
          where: (tbl) => tbl.id.equals(companion.id.value),
        );
      }
    });
  }

  Future<Iterable<RoomEventRecord>> getRoomEventRecords(
    String roomId, {
    int? count,
    DateTime? fromTime,
    bool onlyMemberChanges = false,
    bool? inTimeline,
  }) async {
    final query = select(roomEvents);

    if (onlyMemberChanges) {
      query.where(
        (tbl) => tbl.type.equals(MemberChangeEvent.matrixType),
      );
    }

    if (inTimeline != null) {
      query.where((tbl) => tbl.inTimeline.equals(inTimeline));
    }

    if (fromTime != null) {
      query.where((tbl) => tbl.time.isSmallerThanValue(fromTime));
    }

    query.where((tbl) => tbl.roomId.equals(roomId));

    query.orderBy([
      (e) => OrderingTerm(expression: e.time, mode: OrderingMode.desc),
    ]);

    if (count != null) {
      query.limit(count);
    }

    return query.get();
  }

  Future<void> setRoomEventRecords(List<RoomEventRecord> records) async {
    await batch((batch) async {
      batch.insertAll(
        roomEvents,
        records,
        mode: InsertMode.insertOrReplace,
      );
      batch.deleteWhere<$RoomEventsTable, RoomEventRecord>(
        roomEvents,
        (tbl) => tbl.id.isIn(
          records.map((r) => r.transactionId).where((txnId) => txnId != null),
        ),
      );
    });
  }

  /// Get the MemberChangeEvents for each user.
  Future<Iterable<RoomEventRecord>> getMemberEventRecordsOfSenders(
    String roomId,
    Iterable<String> userIds,
  ) async {
    return (select(roomEvents)
          ..where(
            (tbl) =>
                tbl.roomId.equals(roomId) &
                tbl.type.equals(MemberChangeEvent.matrixType) &
                (tbl.senderId.isIn(userIds) | tbl.stateKey.isIn(userIds)),
          ))
        .get();
  }

  Future<Iterable<EphemeralEventRecord>> getEphemeralEventRecords(
    String roomId,
  ) async {
    final query = select(ephemeralEvents)
      ..where(
        (tbl) => tbl.roomId.equals(roomId),
      );

    return query.get();
  }

  Future<void> setEphemeralEventRecords(
    List<EphemeralEventRecord> records,
  ) async {
    await batch((batch) async {
      batch.insertAll(
        ephemeralEvents,
        records,
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<void> setDeviceRecords(List<DevicesCompanion> companions) async {
    // TODO: Use insertOnConflictUpdate when released
    await batch((batch) async {
      for (final companion in companions) {
        batch.insert(devices, companion, mode: InsertMode.insertOrIgnore);
        batch.update<$DevicesTable, DeviceRecord>(
          devices,
          companion,
          where: (tbl) => tbl.id.equals(companion.id.value),
        );
      }
    });
  }

  Future<void> deleteInviteStates(List<String> roomIds) async {
    await batch((batch) async {
      for (final roomId in roomIds) {
        batch.deleteWhere<$RoomEventsTable, RoomEventRecord>(
          roomEvents,
          (tbl) => tbl.id.isIn(['$roomId:%']),
        );
      }
    });
  }
}

class MyUserRecordWithDeviceRecord {
  final MyUserRecord myUserRecord;
  final DeviceRecord deviceRecord;

  MyUserRecordWithDeviceRecord({
    required this.myUserRecord,
    required this.deviceRecord,
  });
}

class RoomRecordWithStateRecords {
  final RoomRecord roomRecord;

  final RoomEventRecord? nameChangeRecord;
  final RoomEventRecord? avatarChangeRecord;
  final RoomEventRecord? topicChangeRecord;
  final RoomEventRecord? powerLevelsChangeRecord;
  final RoomEventRecord? joinRulesChangeRecord;
  final RoomEventRecord? canonicalAliasChangeRecord;
  final RoomEventRecord? creationRecord;
  final RoomEventRecord? upgradeRecord;

  RoomRecordWithStateRecords({
    required this.roomRecord,
    required this.nameChangeRecord,
    required this.avatarChangeRecord,
    required this.topicChangeRecord,
    required this.powerLevelsChangeRecord,
    required this.joinRulesChangeRecord,
    required this.canonicalAliasChangeRecord,
    required this.creationRecord,
    required this.upgradeRecord,
  });
}
