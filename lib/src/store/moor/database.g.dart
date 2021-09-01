// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps, unnecessary_this
class MyUserRecord extends DataClass implements Insertable<MyUserRecord> {
  final String? homeserver;
  final String? id;
  final String? name;
  final String? avatarUrl;
  final String? accessToken;
  final String? syncToken;
  final String? currentDeviceId;
  final bool? hasSynced;
  final bool? isLoggedOut;
  MyUserRecord(
      {this.homeserver,
      this.id,
      this.name,
      this.avatarUrl,
      this.accessToken,
      this.syncToken,
      this.currentDeviceId,
      this.hasSynced,
      this.isLoggedOut});
  factory MyUserRecord.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return MyUserRecord(
      homeserver: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}homeserver']),
      id: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}id']),
      name: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}name']),
      avatarUrl: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}avatar_url']),
      accessToken: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}access_token']),
      syncToken: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}sync_token']),
      currentDeviceId: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}current_device_id']),
      hasSynced: const BoolType()
          .mapFromDatabaseResponse(data['${effectivePrefix}has_synced']),
      isLoggedOut: const BoolType()
          .mapFromDatabaseResponse(data['${effectivePrefix}is_logged_out']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || homeserver != null) {
      map['homeserver'] = Variable<String?>(homeserver);
    }
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<String?>(id);
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String?>(name);
    }
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String?>(avatarUrl);
    }
    if (!nullToAbsent || accessToken != null) {
      map['access_token'] = Variable<String?>(accessToken);
    }
    if (!nullToAbsent || syncToken != null) {
      map['sync_token'] = Variable<String?>(syncToken);
    }
    if (!nullToAbsent || currentDeviceId != null) {
      map['current_device_id'] = Variable<String?>(currentDeviceId);
    }
    if (!nullToAbsent || hasSynced != null) {
      map['has_synced'] = Variable<bool?>(hasSynced);
    }
    if (!nullToAbsent || isLoggedOut != null) {
      map['is_logged_out'] = Variable<bool?>(isLoggedOut);
    }
    return map;
  }

  MyUsersCompanion toCompanion(bool nullToAbsent) {
    return MyUsersCompanion(
      homeserver: homeserver == null && nullToAbsent
          ? const Value.absent()
          : Value(homeserver),
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
      accessToken: accessToken == null && nullToAbsent
          ? const Value.absent()
          : Value(accessToken),
      syncToken: syncToken == null && nullToAbsent
          ? const Value.absent()
          : Value(syncToken),
      currentDeviceId: currentDeviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(currentDeviceId),
      hasSynced: hasSynced == null && nullToAbsent
          ? const Value.absent()
          : Value(hasSynced),
      isLoggedOut: isLoggedOut == null && nullToAbsent
          ? const Value.absent()
          : Value(isLoggedOut),
    );
  }

  factory MyUserRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return MyUserRecord(
      homeserver: serializer.fromJson<String?>(json['homeserver']),
      id: serializer.fromJson<String?>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      accessToken: serializer.fromJson<String?>(json['accessToken']),
      syncToken: serializer.fromJson<String?>(json['syncToken']),
      currentDeviceId: serializer.fromJson<String?>(json['currentDeviceId']),
      hasSynced: serializer.fromJson<bool?>(json['hasSynced']),
      isLoggedOut: serializer.fromJson<bool?>(json['isLoggedOut']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'homeserver': serializer.toJson<String?>(homeserver),
      'id': serializer.toJson<String?>(id),
      'name': serializer.toJson<String?>(name),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'accessToken': serializer.toJson<String?>(accessToken),
      'syncToken': serializer.toJson<String?>(syncToken),
      'currentDeviceId': serializer.toJson<String?>(currentDeviceId),
      'hasSynced': serializer.toJson<bool?>(hasSynced),
      'isLoggedOut': serializer.toJson<bool?>(isLoggedOut),
    };
  }

  MyUserRecord copyWith(
          {String? homeserver,
          String? id,
          String? name,
          String? avatarUrl,
          String? accessToken,
          String? syncToken,
          String? currentDeviceId,
          bool? hasSynced,
          bool? isLoggedOut}) =>
      MyUserRecord(
        homeserver: homeserver ?? this.homeserver,
        id: id ?? this.id,
        name: name ?? this.name,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        accessToken: accessToken ?? this.accessToken,
        syncToken: syncToken ?? this.syncToken,
        currentDeviceId: currentDeviceId ?? this.currentDeviceId,
        hasSynced: hasSynced ?? this.hasSynced,
        isLoggedOut: isLoggedOut ?? this.isLoggedOut,
      );
  @override
  String toString() {
    return (StringBuffer('MyUserRecord(')
          ..write('homeserver: $homeserver, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('accessToken: $accessToken, ')
          ..write('syncToken: $syncToken, ')
          ..write('currentDeviceId: $currentDeviceId, ')
          ..write('hasSynced: $hasSynced, ')
          ..write('isLoggedOut: $isLoggedOut')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      homeserver.hashCode,
      $mrjc(
          id.hashCode,
          $mrjc(
              name.hashCode,
              $mrjc(
                  avatarUrl.hashCode,
                  $mrjc(
                      accessToken.hashCode,
                      $mrjc(
                          syncToken.hashCode,
                          $mrjc(
                              currentDeviceId.hashCode,
                              $mrjc(hasSynced.hashCode,
                                  isLoggedOut.hashCode)))))))));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MyUserRecord &&
          other.homeserver == this.homeserver &&
          other.id == this.id &&
          other.name == this.name &&
          other.avatarUrl == this.avatarUrl &&
          other.accessToken == this.accessToken &&
          other.syncToken == this.syncToken &&
          other.currentDeviceId == this.currentDeviceId &&
          other.hasSynced == this.hasSynced &&
          other.isLoggedOut == this.isLoggedOut);
}

class MyUsersCompanion extends UpdateCompanion<MyUserRecord> {
  final Value<String?> homeserver;
  final Value<String?> id;
  final Value<String?> name;
  final Value<String?> avatarUrl;
  final Value<String?> accessToken;
  final Value<String?> syncToken;
  final Value<String?> currentDeviceId;
  final Value<bool?> hasSynced;
  final Value<bool?> isLoggedOut;
  const MyUsersCompanion({
    this.homeserver = const Value.absent(),
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.accessToken = const Value.absent(),
    this.syncToken = const Value.absent(),
    this.currentDeviceId = const Value.absent(),
    this.hasSynced = const Value.absent(),
    this.isLoggedOut = const Value.absent(),
  });
  MyUsersCompanion.insert({
    this.homeserver = const Value.absent(),
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.accessToken = const Value.absent(),
    this.syncToken = const Value.absent(),
    this.currentDeviceId = const Value.absent(),
    this.hasSynced = const Value.absent(),
    this.isLoggedOut = const Value.absent(),
  });
  static Insertable<MyUserRecord> custom({
    Expression<String?>? homeserver,
    Expression<String?>? id,
    Expression<String?>? name,
    Expression<String?>? avatarUrl,
    Expression<String?>? accessToken,
    Expression<String?>? syncToken,
    Expression<String?>? currentDeviceId,
    Expression<bool?>? hasSynced,
    Expression<bool?>? isLoggedOut,
  }) {
    return RawValuesInsertable({
      if (homeserver != null) 'homeserver': homeserver,
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (accessToken != null) 'access_token': accessToken,
      if (syncToken != null) 'sync_token': syncToken,
      if (currentDeviceId != null) 'current_device_id': currentDeviceId,
      if (hasSynced != null) 'has_synced': hasSynced,
      if (isLoggedOut != null) 'is_logged_out': isLoggedOut,
    });
  }

  MyUsersCompanion copyWith(
      {Value<String?>? homeserver,
      Value<String?>? id,
      Value<String?>? name,
      Value<String?>? avatarUrl,
      Value<String?>? accessToken,
      Value<String?>? syncToken,
      Value<String?>? currentDeviceId,
      Value<bool?>? hasSynced,
      Value<bool?>? isLoggedOut}) {
    return MyUsersCompanion(
      homeserver: homeserver ?? this.homeserver,
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      accessToken: accessToken ?? this.accessToken,
      syncToken: syncToken ?? this.syncToken,
      currentDeviceId: currentDeviceId ?? this.currentDeviceId,
      hasSynced: hasSynced ?? this.hasSynced,
      isLoggedOut: isLoggedOut ?? this.isLoggedOut,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (homeserver.present) {
      map['homeserver'] = Variable<String?>(homeserver.value);
    }
    if (id.present) {
      map['id'] = Variable<String?>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String?>(name.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String?>(avatarUrl.value);
    }
    if (accessToken.present) {
      map['access_token'] = Variable<String?>(accessToken.value);
    }
    if (syncToken.present) {
      map['sync_token'] = Variable<String?>(syncToken.value);
    }
    if (currentDeviceId.present) {
      map['current_device_id'] = Variable<String?>(currentDeviceId.value);
    }
    if (hasSynced.present) {
      map['has_synced'] = Variable<bool?>(hasSynced.value);
    }
    if (isLoggedOut.present) {
      map['is_logged_out'] = Variable<bool?>(isLoggedOut.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MyUsersCompanion(')
          ..write('homeserver: $homeserver, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('accessToken: $accessToken, ')
          ..write('syncToken: $syncToken, ')
          ..write('currentDeviceId: $currentDeviceId, ')
          ..write('hasSynced: $hasSynced, ')
          ..write('isLoggedOut: $isLoggedOut')
          ..write(')'))
        .toString();
  }
}

class $MyUsersTable extends MyUsers
    with TableInfo<$MyUsersTable, MyUserRecord> {
  final GeneratedDatabase _db;
  final String? _alias;
  $MyUsersTable(this._db, [this._alias]);
  final VerificationMeta _homeserverMeta = const VerificationMeta('homeserver');
  late final GeneratedColumn<String?> homeserver = GeneratedColumn<String?>(
      'homeserver', aliasedName, true,
      typeName: 'TEXT', requiredDuringInsert: false);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String?> id = GeneratedColumn<String?>(
      'id', aliasedName, true,
      typeName: 'TEXT', requiredDuringInsert: false);
  final VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String?> name = GeneratedColumn<String?>(
      'name', aliasedName, true,
      typeName: 'TEXT', requiredDuringInsert: false);
  final VerificationMeta _avatarUrlMeta = const VerificationMeta('avatarUrl');
  late final GeneratedColumn<String?> avatarUrl = GeneratedColumn<String?>(
      'avatar_url', aliasedName, true,
      typeName: 'TEXT', requiredDuringInsert: false);
  final VerificationMeta _accessTokenMeta =
      const VerificationMeta('accessToken');
  late final GeneratedColumn<String?> accessToken = GeneratedColumn<String?>(
      'access_token', aliasedName, true,
      typeName: 'TEXT', requiredDuringInsert: false);
  final VerificationMeta _syncTokenMeta = const VerificationMeta('syncToken');
  late final GeneratedColumn<String?> syncToken = GeneratedColumn<String?>(
      'sync_token', aliasedName, true,
      typeName: 'TEXT', requiredDuringInsert: false);
  final VerificationMeta _currentDeviceIdMeta =
      const VerificationMeta('currentDeviceId');
  late final GeneratedColumn<String?> currentDeviceId =
      GeneratedColumn<String?>('current_device_id', aliasedName, true,
          typeName: 'TEXT',
          requiredDuringInsert: false,
          $customConstraints: 'REFERENCES devices(id)');
  final VerificationMeta _hasSyncedMeta = const VerificationMeta('hasSynced');
  late final GeneratedColumn<bool?> hasSynced = GeneratedColumn<bool?>(
      'has_synced', aliasedName, true,
      typeName: 'INTEGER',
      requiredDuringInsert: false,
      defaultConstraints: 'CHECK (has_synced IN (0, 1))');
  final VerificationMeta _isLoggedOutMeta =
      const VerificationMeta('isLoggedOut');
  late final GeneratedColumn<bool?> isLoggedOut = GeneratedColumn<bool?>(
      'is_logged_out', aliasedName, true,
      typeName: 'INTEGER',
      requiredDuringInsert: false,
      defaultConstraints: 'CHECK (is_logged_out IN (0, 1))');
  @override
  List<GeneratedColumn> get $columns => [
        homeserver,
        id,
        name,
        avatarUrl,
        accessToken,
        syncToken,
        currentDeviceId,
        hasSynced,
        isLoggedOut
      ];
  @override
  String get aliasedName => _alias ?? 'my_users';
  @override
  String get actualTableName => 'my_users';
  @override
  VerificationContext validateIntegrity(Insertable<MyUserRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('homeserver')) {
      context.handle(
          _homeserverMeta,
          homeserver.isAcceptableOrUnknown(
              data['homeserver']!, _homeserverMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('avatar_url')) {
      context.handle(_avatarUrlMeta,
          avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta));
    }
    if (data.containsKey('access_token')) {
      context.handle(
          _accessTokenMeta,
          accessToken.isAcceptableOrUnknown(
              data['access_token']!, _accessTokenMeta));
    }
    if (data.containsKey('sync_token')) {
      context.handle(_syncTokenMeta,
          syncToken.isAcceptableOrUnknown(data['sync_token']!, _syncTokenMeta));
    }
    if (data.containsKey('current_device_id')) {
      context.handle(
          _currentDeviceIdMeta,
          currentDeviceId.isAcceptableOrUnknown(
              data['current_device_id']!, _currentDeviceIdMeta));
    }
    if (data.containsKey('has_synced')) {
      context.handle(_hasSyncedMeta,
          hasSynced.isAcceptableOrUnknown(data['has_synced']!, _hasSyncedMeta));
    }
    if (data.containsKey('is_logged_out')) {
      context.handle(
          _isLoggedOutMeta,
          isLoggedOut.isAcceptableOrUnknown(
              data['is_logged_out']!, _isLoggedOutMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MyUserRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    return MyUserRecord.fromData(data, _db,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $MyUsersTable createAlias(String alias) {
    return $MyUsersTable(_db, alias);
  }
}

class RoomRecord extends DataClass implements Insertable<RoomRecord> {
  final String? myMembership;
  final String id;
  final String? timelinePreviousBatch;
  final bool? timelinePreviousBatchSetBySync;
  final int? summaryJoinedMembersCount;
  final int? summaryInvitedMembersCount;
  final String? nameChangeEventId;
  final String? avatarChangeEventId;
  final String? topicChangeEventId;
  final String? powerLevelsChangeEventId;
  final String? joinRulesChangeEventId;
  final String? canonicalAliasChangeEventId;
  final String? creationEventId;
  final String? upgradeEventId;
  final int? highlightedUnreadNotificationCount;
  final int? totalUnreadNotificationCount;
  final int lastMessageTimeInterval;
  final String? directUserId;
  RoomRecord(
      {this.myMembership,
      required this.id,
      this.timelinePreviousBatch,
      this.timelinePreviousBatchSetBySync,
      this.summaryJoinedMembersCount,
      this.summaryInvitedMembersCount,
      this.nameChangeEventId,
      this.avatarChangeEventId,
      this.topicChangeEventId,
      this.powerLevelsChangeEventId,
      this.joinRulesChangeEventId,
      this.canonicalAliasChangeEventId,
      this.creationEventId,
      this.upgradeEventId,
      this.highlightedUnreadNotificationCount,
      this.totalUnreadNotificationCount,
      required this.lastMessageTimeInterval,
      this.directUserId});
  factory RoomRecord.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return RoomRecord(
      myMembership: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}my_membership']),
      id: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      timelinePreviousBatch: const StringType().mapFromDatabaseResponse(
          data['${effectivePrefix}timeline_previous_batch']),
      timelinePreviousBatchSetBySync: const BoolType().mapFromDatabaseResponse(
          data['${effectivePrefix}timeline_previous_batch_set_by_sync']),
      summaryJoinedMembersCount: const IntType().mapFromDatabaseResponse(
          data['${effectivePrefix}summary_joined_members_count']),
      summaryInvitedMembersCount: const IntType().mapFromDatabaseResponse(
          data['${effectivePrefix}summary_invited_members_count']),
      nameChangeEventId: const StringType().mapFromDatabaseResponse(
          data['${effectivePrefix}name_change_event_id']),
      avatarChangeEventId: const StringType().mapFromDatabaseResponse(
          data['${effectivePrefix}avatar_change_event_id']),
      topicChangeEventId: const StringType().mapFromDatabaseResponse(
          data['${effectivePrefix}topic_change_event_id']),
      powerLevelsChangeEventId: const StringType().mapFromDatabaseResponse(
          data['${effectivePrefix}power_levels_change_event_id']),
      joinRulesChangeEventId: const StringType().mapFromDatabaseResponse(
          data['${effectivePrefix}join_rules_change_event_id']),
      canonicalAliasChangeEventId: const StringType().mapFromDatabaseResponse(
          data['${effectivePrefix}canonical_alias_change_event_id']),
      creationEventId: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}creation_event_id']),
      upgradeEventId: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}upgrade_event_id']),
      highlightedUnreadNotificationCount: const IntType()
          .mapFromDatabaseResponse(
              data['${effectivePrefix}highlighted_unread_notification_count']),
      totalUnreadNotificationCount: const IntType().mapFromDatabaseResponse(
          data['${effectivePrefix}total_unread_notification_count']),
      lastMessageTimeInterval: const IntType().mapFromDatabaseResponse(
          data['${effectivePrefix}last_message_time_interval'])!,
      directUserId: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}direct_user_id']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || myMembership != null) {
      map['my_membership'] = Variable<String?>(myMembership);
    }
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || timelinePreviousBatch != null) {
      map['timeline_previous_batch'] = Variable<String?>(timelinePreviousBatch);
    }
    if (!nullToAbsent || timelinePreviousBatchSetBySync != null) {
      map['timeline_previous_batch_set_by_sync'] =
          Variable<bool?>(timelinePreviousBatchSetBySync);
    }
    if (!nullToAbsent || summaryJoinedMembersCount != null) {
      map['summary_joined_members_count'] =
          Variable<int?>(summaryJoinedMembersCount);
    }
    if (!nullToAbsent || summaryInvitedMembersCount != null) {
      map['summary_invited_members_count'] =
          Variable<int?>(summaryInvitedMembersCount);
    }
    if (!nullToAbsent || nameChangeEventId != null) {
      map['name_change_event_id'] = Variable<String?>(nameChangeEventId);
    }
    if (!nullToAbsent || avatarChangeEventId != null) {
      map['avatar_change_event_id'] = Variable<String?>(avatarChangeEventId);
    }
    if (!nullToAbsent || topicChangeEventId != null) {
      map['topic_change_event_id'] = Variable<String?>(topicChangeEventId);
    }
    if (!nullToAbsent || powerLevelsChangeEventId != null) {
      map['power_levels_change_event_id'] =
          Variable<String?>(powerLevelsChangeEventId);
    }
    if (!nullToAbsent || joinRulesChangeEventId != null) {
      map['join_rules_change_event_id'] =
          Variable<String?>(joinRulesChangeEventId);
    }
    if (!nullToAbsent || canonicalAliasChangeEventId != null) {
      map['canonical_alias_change_event_id'] =
          Variable<String?>(canonicalAliasChangeEventId);
    }
    if (!nullToAbsent || creationEventId != null) {
      map['creation_event_id'] = Variable<String?>(creationEventId);
    }
    if (!nullToAbsent || upgradeEventId != null) {
      map['upgrade_event_id'] = Variable<String?>(upgradeEventId);
    }
    if (!nullToAbsent || highlightedUnreadNotificationCount != null) {
      map['highlighted_unread_notification_count'] =
          Variable<int?>(highlightedUnreadNotificationCount);
    }
    if (!nullToAbsent || totalUnreadNotificationCount != null) {
      map['total_unread_notification_count'] =
          Variable<int?>(totalUnreadNotificationCount);
    }
    map['last_message_time_interval'] = Variable<int>(lastMessageTimeInterval);
    if (!nullToAbsent || directUserId != null) {
      map['direct_user_id'] = Variable<String?>(directUserId);
    }
    return map;
  }

  RoomsCompanion toCompanion(bool nullToAbsent) {
    return RoomsCompanion(
      myMembership: myMembership == null && nullToAbsent
          ? const Value.absent()
          : Value(myMembership),
      id: Value(id),
      timelinePreviousBatch: timelinePreviousBatch == null && nullToAbsent
          ? const Value.absent()
          : Value(timelinePreviousBatch),
      timelinePreviousBatchSetBySync:
          timelinePreviousBatchSetBySync == null && nullToAbsent
              ? const Value.absent()
              : Value(timelinePreviousBatchSetBySync),
      summaryJoinedMembersCount:
          summaryJoinedMembersCount == null && nullToAbsent
              ? const Value.absent()
              : Value(summaryJoinedMembersCount),
      summaryInvitedMembersCount:
          summaryInvitedMembersCount == null && nullToAbsent
              ? const Value.absent()
              : Value(summaryInvitedMembersCount),
      nameChangeEventId: nameChangeEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(nameChangeEventId),
      avatarChangeEventId: avatarChangeEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarChangeEventId),
      topicChangeEventId: topicChangeEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(topicChangeEventId),
      powerLevelsChangeEventId: powerLevelsChangeEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(powerLevelsChangeEventId),
      joinRulesChangeEventId: joinRulesChangeEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(joinRulesChangeEventId),
      canonicalAliasChangeEventId:
          canonicalAliasChangeEventId == null && nullToAbsent
              ? const Value.absent()
              : Value(canonicalAliasChangeEventId),
      creationEventId: creationEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(creationEventId),
      upgradeEventId: upgradeEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(upgradeEventId),
      highlightedUnreadNotificationCount:
          highlightedUnreadNotificationCount == null && nullToAbsent
              ? const Value.absent()
              : Value(highlightedUnreadNotificationCount),
      totalUnreadNotificationCount:
          totalUnreadNotificationCount == null && nullToAbsent
              ? const Value.absent()
              : Value(totalUnreadNotificationCount),
      lastMessageTimeInterval: Value(lastMessageTimeInterval),
      directUserId: directUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(directUserId),
    );
  }

  factory RoomRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return RoomRecord(
      myMembership: serializer.fromJson<String?>(json['myMembership']),
      id: serializer.fromJson<String>(json['id']),
      timelinePreviousBatch:
          serializer.fromJson<String?>(json['timelinePreviousBatch']),
      timelinePreviousBatchSetBySync:
          serializer.fromJson<bool?>(json['timelinePreviousBatchSetBySync']),
      summaryJoinedMembersCount:
          serializer.fromJson<int?>(json['summaryJoinedMembersCount']),
      summaryInvitedMembersCount:
          serializer.fromJson<int?>(json['summaryInvitedMembersCount']),
      nameChangeEventId:
          serializer.fromJson<String?>(json['nameChangeEventId']),
      avatarChangeEventId:
          serializer.fromJson<String?>(json['avatarChangeEventId']),
      topicChangeEventId:
          serializer.fromJson<String?>(json['topicChangeEventId']),
      powerLevelsChangeEventId:
          serializer.fromJson<String?>(json['powerLevelsChangeEventId']),
      joinRulesChangeEventId:
          serializer.fromJson<String?>(json['joinRulesChangeEventId']),
      canonicalAliasChangeEventId:
          serializer.fromJson<String?>(json['canonicalAliasChangeEventId']),
      creationEventId: serializer.fromJson<String?>(json['creationEventId']),
      upgradeEventId: serializer.fromJson<String?>(json['upgradeEventId']),
      highlightedUnreadNotificationCount:
          serializer.fromJson<int?>(json['highlightedUnreadNotificationCount']),
      totalUnreadNotificationCount:
          serializer.fromJson<int?>(json['totalUnreadNotificationCount']),
      lastMessageTimeInterval:
          serializer.fromJson<int>(json['lastMessageTimeInterval']),
      directUserId: serializer.fromJson<String?>(json['directUserId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'myMembership': serializer.toJson<String?>(myMembership),
      'id': serializer.toJson<String>(id),
      'timelinePreviousBatch':
          serializer.toJson<String?>(timelinePreviousBatch),
      'timelinePreviousBatchSetBySync':
          serializer.toJson<bool?>(timelinePreviousBatchSetBySync),
      'summaryJoinedMembersCount':
          serializer.toJson<int?>(summaryJoinedMembersCount),
      'summaryInvitedMembersCount':
          serializer.toJson<int?>(summaryInvitedMembersCount),
      'nameChangeEventId': serializer.toJson<String?>(nameChangeEventId),
      'avatarChangeEventId': serializer.toJson<String?>(avatarChangeEventId),
      'topicChangeEventId': serializer.toJson<String?>(topicChangeEventId),
      'powerLevelsChangeEventId':
          serializer.toJson<String?>(powerLevelsChangeEventId),
      'joinRulesChangeEventId':
          serializer.toJson<String?>(joinRulesChangeEventId),
      'canonicalAliasChangeEventId':
          serializer.toJson<String?>(canonicalAliasChangeEventId),
      'creationEventId': serializer.toJson<String?>(creationEventId),
      'upgradeEventId': serializer.toJson<String?>(upgradeEventId),
      'highlightedUnreadNotificationCount':
          serializer.toJson<int?>(highlightedUnreadNotificationCount),
      'totalUnreadNotificationCount':
          serializer.toJson<int?>(totalUnreadNotificationCount),
      'lastMessageTimeInterval':
          serializer.toJson<int>(lastMessageTimeInterval),
      'directUserId': serializer.toJson<String?>(directUserId),
    };
  }

  RoomRecord copyWith(
          {String? myMembership,
          String? id,
          String? timelinePreviousBatch,
          bool? timelinePreviousBatchSetBySync,
          int? summaryJoinedMembersCount,
          int? summaryInvitedMembersCount,
          String? nameChangeEventId,
          String? avatarChangeEventId,
          String? topicChangeEventId,
          String? powerLevelsChangeEventId,
          String? joinRulesChangeEventId,
          String? canonicalAliasChangeEventId,
          String? creationEventId,
          String? upgradeEventId,
          int? highlightedUnreadNotificationCount,
          int? totalUnreadNotificationCount,
          int? lastMessageTimeInterval,
          String? directUserId}) =>
      RoomRecord(
        myMembership: myMembership ?? this.myMembership,
        id: id ?? this.id,
        timelinePreviousBatch:
            timelinePreviousBatch ?? this.timelinePreviousBatch,
        timelinePreviousBatchSetBySync: timelinePreviousBatchSetBySync ??
            this.timelinePreviousBatchSetBySync,
        summaryJoinedMembersCount:
            summaryJoinedMembersCount ?? this.summaryJoinedMembersCount,
        summaryInvitedMembersCount:
            summaryInvitedMembersCount ?? this.summaryInvitedMembersCount,
        nameChangeEventId: nameChangeEventId ?? this.nameChangeEventId,
        avatarChangeEventId: avatarChangeEventId ?? this.avatarChangeEventId,
        topicChangeEventId: topicChangeEventId ?? this.topicChangeEventId,
        powerLevelsChangeEventId:
            powerLevelsChangeEventId ?? this.powerLevelsChangeEventId,
        joinRulesChangeEventId:
            joinRulesChangeEventId ?? this.joinRulesChangeEventId,
        canonicalAliasChangeEventId:
            canonicalAliasChangeEventId ?? this.canonicalAliasChangeEventId,
        creationEventId: creationEventId ?? this.creationEventId,
        upgradeEventId: upgradeEventId ?? this.upgradeEventId,
        highlightedUnreadNotificationCount:
            highlightedUnreadNotificationCount ??
                this.highlightedUnreadNotificationCount,
        totalUnreadNotificationCount:
            totalUnreadNotificationCount ?? this.totalUnreadNotificationCount,
        lastMessageTimeInterval:
            lastMessageTimeInterval ?? this.lastMessageTimeInterval,
        directUserId: directUserId ?? this.directUserId,
      );
  @override
  String toString() {
    return (StringBuffer('RoomRecord(')
          ..write('myMembership: $myMembership, ')
          ..write('id: $id, ')
          ..write('timelinePreviousBatch: $timelinePreviousBatch, ')
          ..write(
              'timelinePreviousBatchSetBySync: $timelinePreviousBatchSetBySync, ')
          ..write('summaryJoinedMembersCount: $summaryJoinedMembersCount, ')
          ..write('summaryInvitedMembersCount: $summaryInvitedMembersCount, ')
          ..write('nameChangeEventId: $nameChangeEventId, ')
          ..write('avatarChangeEventId: $avatarChangeEventId, ')
          ..write('topicChangeEventId: $topicChangeEventId, ')
          ..write('powerLevelsChangeEventId: $powerLevelsChangeEventId, ')
          ..write('joinRulesChangeEventId: $joinRulesChangeEventId, ')
          ..write('canonicalAliasChangeEventId: $canonicalAliasChangeEventId, ')
          ..write('creationEventId: $creationEventId, ')
          ..write('upgradeEventId: $upgradeEventId, ')
          ..write(
              'highlightedUnreadNotificationCount: $highlightedUnreadNotificationCount, ')
          ..write(
              'totalUnreadNotificationCount: $totalUnreadNotificationCount, ')
          ..write('lastMessageTimeInterval: $lastMessageTimeInterval, ')
          ..write('directUserId: $directUserId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      myMembership.hashCode,
      $mrjc(
          id.hashCode,
          $mrjc(
              timelinePreviousBatch.hashCode,
              $mrjc(
                  timelinePreviousBatchSetBySync.hashCode,
                  $mrjc(
                      summaryJoinedMembersCount.hashCode,
                      $mrjc(
                          summaryInvitedMembersCount.hashCode,
                          $mrjc(
                              nameChangeEventId.hashCode,
                              $mrjc(
                                  avatarChangeEventId.hashCode,
                                  $mrjc(
                                      topicChangeEventId.hashCode,
                                      $mrjc(
                                          powerLevelsChangeEventId.hashCode,
                                          $mrjc(
                                              joinRulesChangeEventId.hashCode,
                                              $mrjc(
                                                  canonicalAliasChangeEventId
                                                      .hashCode,
                                                  $mrjc(
                                                      creationEventId.hashCode,
                                                      $mrjc(
                                                          upgradeEventId
                                                              .hashCode,
                                                          $mrjc(
                                                              highlightedUnreadNotificationCount
                                                                  .hashCode,
                                                              $mrjc(
                                                                  totalUnreadNotificationCount
                                                                      .hashCode,
                                                                  $mrjc(
                                                                      lastMessageTimeInterval
                                                                          .hashCode,
                                                                      directUserId
                                                                          .hashCode))))))))))))))))));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoomRecord &&
          other.myMembership == this.myMembership &&
          other.id == this.id &&
          other.timelinePreviousBatch == this.timelinePreviousBatch &&
          other.timelinePreviousBatchSetBySync ==
              this.timelinePreviousBatchSetBySync &&
          other.summaryJoinedMembersCount == this.summaryJoinedMembersCount &&
          other.summaryInvitedMembersCount == this.summaryInvitedMembersCount &&
          other.nameChangeEventId == this.nameChangeEventId &&
          other.avatarChangeEventId == this.avatarChangeEventId &&
          other.topicChangeEventId == this.topicChangeEventId &&
          other.powerLevelsChangeEventId == this.powerLevelsChangeEventId &&
          other.joinRulesChangeEventId == this.joinRulesChangeEventId &&
          other.canonicalAliasChangeEventId ==
              this.canonicalAliasChangeEventId &&
          other.creationEventId == this.creationEventId &&
          other.upgradeEventId == this.upgradeEventId &&
          other.highlightedUnreadNotificationCount ==
              this.highlightedUnreadNotificationCount &&
          other.totalUnreadNotificationCount ==
              this.totalUnreadNotificationCount &&
          other.lastMessageTimeInterval == this.lastMessageTimeInterval &&
          other.directUserId == this.directUserId);
}

class RoomsCompanion extends UpdateCompanion<RoomRecord> {
  final Value<String?> myMembership;
  final Value<String> id;
  final Value<String?> timelinePreviousBatch;
  final Value<bool?> timelinePreviousBatchSetBySync;
  final Value<int?> summaryJoinedMembersCount;
  final Value<int?> summaryInvitedMembersCount;
  final Value<String?> nameChangeEventId;
  final Value<String?> avatarChangeEventId;
  final Value<String?> topicChangeEventId;
  final Value<String?> powerLevelsChangeEventId;
  final Value<String?> joinRulesChangeEventId;
  final Value<String?> canonicalAliasChangeEventId;
  final Value<String?> creationEventId;
  final Value<String?> upgradeEventId;
  final Value<int?> highlightedUnreadNotificationCount;
  final Value<int?> totalUnreadNotificationCount;
  final Value<int> lastMessageTimeInterval;
  final Value<String?> directUserId;
  const RoomsCompanion({
    this.myMembership = const Value.absent(),
    this.id = const Value.absent(),
    this.timelinePreviousBatch = const Value.absent(),
    this.timelinePreviousBatchSetBySync = const Value.absent(),
    this.summaryJoinedMembersCount = const Value.absent(),
    this.summaryInvitedMembersCount = const Value.absent(),
    this.nameChangeEventId = const Value.absent(),
    this.avatarChangeEventId = const Value.absent(),
    this.topicChangeEventId = const Value.absent(),
    this.powerLevelsChangeEventId = const Value.absent(),
    this.joinRulesChangeEventId = const Value.absent(),
    this.canonicalAliasChangeEventId = const Value.absent(),
    this.creationEventId = const Value.absent(),
    this.upgradeEventId = const Value.absent(),
    this.highlightedUnreadNotificationCount = const Value.absent(),
    this.totalUnreadNotificationCount = const Value.absent(),
    this.lastMessageTimeInterval = const Value.absent(),
    this.directUserId = const Value.absent(),
  });
  RoomsCompanion.insert({
    this.myMembership = const Value.absent(),
    required String id,
    this.timelinePreviousBatch = const Value.absent(),
    this.timelinePreviousBatchSetBySync = const Value.absent(),
    this.summaryJoinedMembersCount = const Value.absent(),
    this.summaryInvitedMembersCount = const Value.absent(),
    this.nameChangeEventId = const Value.absent(),
    this.avatarChangeEventId = const Value.absent(),
    this.topicChangeEventId = const Value.absent(),
    this.powerLevelsChangeEventId = const Value.absent(),
    this.joinRulesChangeEventId = const Value.absent(),
    this.canonicalAliasChangeEventId = const Value.absent(),
    this.creationEventId = const Value.absent(),
    this.upgradeEventId = const Value.absent(),
    this.highlightedUnreadNotificationCount = const Value.absent(),
    this.totalUnreadNotificationCount = const Value.absent(),
    this.lastMessageTimeInterval = const Value.absent(),
    this.directUserId = const Value.absent(),
  }) : id = Value(id);
  static Insertable<RoomRecord> custom({
    Expression<String?>? myMembership,
    Expression<String>? id,
    Expression<String?>? timelinePreviousBatch,
    Expression<bool?>? timelinePreviousBatchSetBySync,
    Expression<int?>? summaryJoinedMembersCount,
    Expression<int?>? summaryInvitedMembersCount,
    Expression<String?>? nameChangeEventId,
    Expression<String?>? avatarChangeEventId,
    Expression<String?>? topicChangeEventId,
    Expression<String?>? powerLevelsChangeEventId,
    Expression<String?>? joinRulesChangeEventId,
    Expression<String?>? canonicalAliasChangeEventId,
    Expression<String?>? creationEventId,
    Expression<String?>? upgradeEventId,
    Expression<int?>? highlightedUnreadNotificationCount,
    Expression<int?>? totalUnreadNotificationCount,
    Expression<int>? lastMessageTimeInterval,
    Expression<String?>? directUserId,
  }) {
    return RawValuesInsertable({
      if (myMembership != null) 'my_membership': myMembership,
      if (id != null) 'id': id,
      if (timelinePreviousBatch != null)
        'timeline_previous_batch': timelinePreviousBatch,
      if (timelinePreviousBatchSetBySync != null)
        'timeline_previous_batch_set_by_sync': timelinePreviousBatchSetBySync,
      if (summaryJoinedMembersCount != null)
        'summary_joined_members_count': summaryJoinedMembersCount,
      if (summaryInvitedMembersCount != null)
        'summary_invited_members_count': summaryInvitedMembersCount,
      if (nameChangeEventId != null) 'name_change_event_id': nameChangeEventId,
      if (avatarChangeEventId != null)
        'avatar_change_event_id': avatarChangeEventId,
      if (topicChangeEventId != null)
        'topic_change_event_id': topicChangeEventId,
      if (powerLevelsChangeEventId != null)
        'power_levels_change_event_id': powerLevelsChangeEventId,
      if (joinRulesChangeEventId != null)
        'join_rules_change_event_id': joinRulesChangeEventId,
      if (canonicalAliasChangeEventId != null)
        'canonical_alias_change_event_id': canonicalAliasChangeEventId,
      if (creationEventId != null) 'creation_event_id': creationEventId,
      if (upgradeEventId != null) 'upgrade_event_id': upgradeEventId,
      if (highlightedUnreadNotificationCount != null)
        'highlighted_unread_notification_count':
            highlightedUnreadNotificationCount,
      if (totalUnreadNotificationCount != null)
        'total_unread_notification_count': totalUnreadNotificationCount,
      if (lastMessageTimeInterval != null)
        'last_message_time_interval': lastMessageTimeInterval,
      if (directUserId != null) 'direct_user_id': directUserId,
    });
  }

  RoomsCompanion copyWith(
      {Value<String?>? myMembership,
      Value<String>? id,
      Value<String?>? timelinePreviousBatch,
      Value<bool?>? timelinePreviousBatchSetBySync,
      Value<int?>? summaryJoinedMembersCount,
      Value<int?>? summaryInvitedMembersCount,
      Value<String?>? nameChangeEventId,
      Value<String?>? avatarChangeEventId,
      Value<String?>? topicChangeEventId,
      Value<String?>? powerLevelsChangeEventId,
      Value<String?>? joinRulesChangeEventId,
      Value<String?>? canonicalAliasChangeEventId,
      Value<String?>? creationEventId,
      Value<String?>? upgradeEventId,
      Value<int?>? highlightedUnreadNotificationCount,
      Value<int?>? totalUnreadNotificationCount,
      Value<int>? lastMessageTimeInterval,
      Value<String?>? directUserId}) {
    return RoomsCompanion(
      myMembership: myMembership ?? this.myMembership,
      id: id ?? this.id,
      timelinePreviousBatch:
          timelinePreviousBatch ?? this.timelinePreviousBatch,
      timelinePreviousBatchSetBySync:
          timelinePreviousBatchSetBySync ?? this.timelinePreviousBatchSetBySync,
      summaryJoinedMembersCount:
          summaryJoinedMembersCount ?? this.summaryJoinedMembersCount,
      summaryInvitedMembersCount:
          summaryInvitedMembersCount ?? this.summaryInvitedMembersCount,
      nameChangeEventId: nameChangeEventId ?? this.nameChangeEventId,
      avatarChangeEventId: avatarChangeEventId ?? this.avatarChangeEventId,
      topicChangeEventId: topicChangeEventId ?? this.topicChangeEventId,
      powerLevelsChangeEventId:
          powerLevelsChangeEventId ?? this.powerLevelsChangeEventId,
      joinRulesChangeEventId:
          joinRulesChangeEventId ?? this.joinRulesChangeEventId,
      canonicalAliasChangeEventId:
          canonicalAliasChangeEventId ?? this.canonicalAliasChangeEventId,
      creationEventId: creationEventId ?? this.creationEventId,
      upgradeEventId: upgradeEventId ?? this.upgradeEventId,
      highlightedUnreadNotificationCount: highlightedUnreadNotificationCount ??
          this.highlightedUnreadNotificationCount,
      totalUnreadNotificationCount:
          totalUnreadNotificationCount ?? this.totalUnreadNotificationCount,
      lastMessageTimeInterval:
          lastMessageTimeInterval ?? this.lastMessageTimeInterval,
      directUserId: directUserId ?? this.directUserId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (myMembership.present) {
      map['my_membership'] = Variable<String?>(myMembership.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (timelinePreviousBatch.present) {
      map['timeline_previous_batch'] =
          Variable<String?>(timelinePreviousBatch.value);
    }
    if (timelinePreviousBatchSetBySync.present) {
      map['timeline_previous_batch_set_by_sync'] =
          Variable<bool?>(timelinePreviousBatchSetBySync.value);
    }
    if (summaryJoinedMembersCount.present) {
      map['summary_joined_members_count'] =
          Variable<int?>(summaryJoinedMembersCount.value);
    }
    if (summaryInvitedMembersCount.present) {
      map['summary_invited_members_count'] =
          Variable<int?>(summaryInvitedMembersCount.value);
    }
    if (nameChangeEventId.present) {
      map['name_change_event_id'] = Variable<String?>(nameChangeEventId.value);
    }
    if (avatarChangeEventId.present) {
      map['avatar_change_event_id'] =
          Variable<String?>(avatarChangeEventId.value);
    }
    if (topicChangeEventId.present) {
      map['topic_change_event_id'] =
          Variable<String?>(topicChangeEventId.value);
    }
    if (powerLevelsChangeEventId.present) {
      map['power_levels_change_event_id'] =
          Variable<String?>(powerLevelsChangeEventId.value);
    }
    if (joinRulesChangeEventId.present) {
      map['join_rules_change_event_id'] =
          Variable<String?>(joinRulesChangeEventId.value);
    }
    if (canonicalAliasChangeEventId.present) {
      map['canonical_alias_change_event_id'] =
          Variable<String?>(canonicalAliasChangeEventId.value);
    }
    if (creationEventId.present) {
      map['creation_event_id'] = Variable<String?>(creationEventId.value);
    }
    if (upgradeEventId.present) {
      map['upgrade_event_id'] = Variable<String?>(upgradeEventId.value);
    }
    if (highlightedUnreadNotificationCount.present) {
      map['highlighted_unread_notification_count'] =
          Variable<int?>(highlightedUnreadNotificationCount.value);
    }
    if (totalUnreadNotificationCount.present) {
      map['total_unread_notification_count'] =
          Variable<int?>(totalUnreadNotificationCount.value);
    }
    if (lastMessageTimeInterval.present) {
      map['last_message_time_interval'] =
          Variable<int>(lastMessageTimeInterval.value);
    }
    if (directUserId.present) {
      map['direct_user_id'] = Variable<String?>(directUserId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoomsCompanion(')
          ..write('myMembership: $myMembership, ')
          ..write('id: $id, ')
          ..write('timelinePreviousBatch: $timelinePreviousBatch, ')
          ..write(
              'timelinePreviousBatchSetBySync: $timelinePreviousBatchSetBySync, ')
          ..write('summaryJoinedMembersCount: $summaryJoinedMembersCount, ')
          ..write('summaryInvitedMembersCount: $summaryInvitedMembersCount, ')
          ..write('nameChangeEventId: $nameChangeEventId, ')
          ..write('avatarChangeEventId: $avatarChangeEventId, ')
          ..write('topicChangeEventId: $topicChangeEventId, ')
          ..write('powerLevelsChangeEventId: $powerLevelsChangeEventId, ')
          ..write('joinRulesChangeEventId: $joinRulesChangeEventId, ')
          ..write('canonicalAliasChangeEventId: $canonicalAliasChangeEventId, ')
          ..write('creationEventId: $creationEventId, ')
          ..write('upgradeEventId: $upgradeEventId, ')
          ..write(
              'highlightedUnreadNotificationCount: $highlightedUnreadNotificationCount, ')
          ..write(
              'totalUnreadNotificationCount: $totalUnreadNotificationCount, ')
          ..write('lastMessageTimeInterval: $lastMessageTimeInterval, ')
          ..write('directUserId: $directUserId')
          ..write(')'))
        .toString();
  }
}

class $RoomsTable extends Rooms with TableInfo<$RoomsTable, RoomRecord> {
  final GeneratedDatabase _db;
  final String? _alias;
  $RoomsTable(this._db, [this._alias]);
  final VerificationMeta _myMembershipMeta =
      const VerificationMeta('myMembership');
  late final GeneratedColumn<String?> myMembership = GeneratedColumn<String?>(
      'my_membership', aliasedName, true,
      typeName: 'TEXT', requiredDuringInsert: false);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String?> id = GeneratedColumn<String?>(
      'id', aliasedName, false,
      typeName: 'TEXT', requiredDuringInsert: true);
  final VerificationMeta _timelinePreviousBatchMeta =
      const VerificationMeta('timelinePreviousBatch');
  late final GeneratedColumn<String?> timelinePreviousBatch =
      GeneratedColumn<String?>('timeline_previous_batch', aliasedName, true,
          typeName: 'TEXT', requiredDuringInsert: false);
  final VerificationMeta _timelinePreviousBatchSetBySyncMeta =
      const VerificationMeta('timelinePreviousBatchSetBySync');
  late final GeneratedColumn<bool?> timelinePreviousBatchSetBySync =
      GeneratedColumn<bool?>(
          'timeline_previous_batch_set_by_sync', aliasedName, true,
          typeName: 'INTEGER',
          requiredDuringInsert: false,
          defaultConstraints:
              'CHECK (timeline_previous_batch_set_by_sync IN (0, 1))');
  final VerificationMeta _summaryJoinedMembersCountMeta =
      const VerificationMeta('summaryJoinedMembersCount');
  late final GeneratedColumn<int?> summaryJoinedMembersCount =
      GeneratedColumn<int?>('summary_joined_members_count', aliasedName, true,
          typeName: 'INTEGER', requiredDuringInsert: false);
  final VerificationMeta _summaryInvitedMembersCountMeta =
      const VerificationMeta('summaryInvitedMembersCount');
  late final GeneratedColumn<int?> summaryInvitedMembersCount =
      GeneratedColumn<int?>('summary_invited_members_count', aliasedName, true,
          typeName: 'INTEGER', requiredDuringInsert: false);
  final VerificationMeta _nameChangeEventIdMeta =
      const VerificationMeta('nameChangeEventId');
  late final GeneratedColumn<String?> nameChangeEventId =
      GeneratedColumn<String?>('name_change_event_id', aliasedName, true,
          typeName: 'TEXT',
          requiredDuringInsert: false,
          $customConstraints: 'REFERENCES room_events(id)');
  final VerificationMeta _avatarChangeEventIdMeta =
      const VerificationMeta('avatarChangeEventId');
  late final GeneratedColumn<String?> avatarChangeEventId =
      GeneratedColumn<String?>('avatar_change_event_id', aliasedName, true,
          typeName: 'TEXT',
          requiredDuringInsert: false,
          $customConstraints: 'REFERENCES room_events(id)');
  final VerificationMeta _topicChangeEventIdMeta =
      const VerificationMeta('topicChangeEventId');
  late final GeneratedColumn<String?> topicChangeEventId =
      GeneratedColumn<String?>('topic_change_event_id', aliasedName, true,
          typeName: 'TEXT',
          requiredDuringInsert: false,
          $customConstraints: 'REFERENCES room_events(id)');
  final VerificationMeta _powerLevelsChangeEventIdMeta =
      const VerificationMeta('powerLevelsChangeEventId');
  late final GeneratedColumn<String?> powerLevelsChangeEventId =
      GeneratedColumn<String?>(
          'power_levels_change_event_id', aliasedName, true,
          typeName: 'TEXT',
          requiredDuringInsert: false,
          $customConstraints: 'REFERENCES room_events(id)');
  final VerificationMeta _joinRulesChangeEventIdMeta =
      const VerificationMeta('joinRulesChangeEventId');
  late final GeneratedColumn<String?> joinRulesChangeEventId =
      GeneratedColumn<String?>('join_rules_change_event_id', aliasedName, true,
          typeName: 'TEXT',
          requiredDuringInsert: false,
          $customConstraints: 'REFERENCES room_events(id)');
  final VerificationMeta _canonicalAliasChangeEventIdMeta =
      const VerificationMeta('canonicalAliasChangeEventId');
  late final GeneratedColumn<String?> canonicalAliasChangeEventId =
      GeneratedColumn<String?>(
          'canonical_alias_change_event_id', aliasedName, true,
          typeName: 'TEXT',
          requiredDuringInsert: false,
          $customConstraints: 'REFERENCES room_events(id)');
  final VerificationMeta _creationEventIdMeta =
      const VerificationMeta('creationEventId');
  late final GeneratedColumn<String?> creationEventId =
      GeneratedColumn<String?>('creation_event_id', aliasedName, true,
          typeName: 'TEXT',
          requiredDuringInsert: false,
          $customConstraints: 'REFERENCES room_events(id)');
  final VerificationMeta _upgradeEventIdMeta =
      const VerificationMeta('upgradeEventId');
  late final GeneratedColumn<String?> upgradeEventId = GeneratedColumn<String?>(
      'upgrade_event_id', aliasedName, true,
      typeName: 'TEXT',
      requiredDuringInsert: false,
      $customConstraints: 'REFERENCES room_events(id)');
  final VerificationMeta _highlightedUnreadNotificationCountMeta =
      const VerificationMeta('highlightedUnreadNotificationCount');
  late final GeneratedColumn<int?> highlightedUnreadNotificationCount =
      GeneratedColumn<int?>(
          'highlighted_unread_notification_count', aliasedName, true,
          typeName: 'INTEGER', requiredDuringInsert: false);
  final VerificationMeta _totalUnreadNotificationCountMeta =
      const VerificationMeta('totalUnreadNotificationCount');
  late final GeneratedColumn<int?> totalUnreadNotificationCount =
      GeneratedColumn<int?>(
          'total_unread_notification_count', aliasedName, true,
          typeName: 'INTEGER', requiredDuringInsert: false);
  final VerificationMeta _lastMessageTimeIntervalMeta =
      const VerificationMeta('lastMessageTimeInterval');
  late final GeneratedColumn<int?> lastMessageTimeInterval =
      GeneratedColumn<int?>('last_message_time_interval', aliasedName, false,
          typeName: 'INTEGER',
          requiredDuringInsert: false,
          defaultValue: const Constant(0));
  final VerificationMeta _directUserIdMeta =
      const VerificationMeta('directUserId');
  late final GeneratedColumn<String?> directUserId = GeneratedColumn<String?>(
      'direct_user_id', aliasedName, true,
      typeName: 'TEXT', requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        myMembership,
        id,
        timelinePreviousBatch,
        timelinePreviousBatchSetBySync,
        summaryJoinedMembersCount,
        summaryInvitedMembersCount,
        nameChangeEventId,
        avatarChangeEventId,
        topicChangeEventId,
        powerLevelsChangeEventId,
        joinRulesChangeEventId,
        canonicalAliasChangeEventId,
        creationEventId,
        upgradeEventId,
        highlightedUnreadNotificationCount,
        totalUnreadNotificationCount,
        lastMessageTimeInterval,
        directUserId
      ];
  @override
  String get aliasedName => _alias ?? 'rooms';
  @override
  String get actualTableName => 'rooms';
  @override
  VerificationContext validateIntegrity(Insertable<RoomRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('my_membership')) {
      context.handle(
          _myMembershipMeta,
          myMembership.isAcceptableOrUnknown(
              data['my_membership']!, _myMembershipMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('timeline_previous_batch')) {
      context.handle(
          _timelinePreviousBatchMeta,
          timelinePreviousBatch.isAcceptableOrUnknown(
              data['timeline_previous_batch']!, _timelinePreviousBatchMeta));
    }
    if (data.containsKey('timeline_previous_batch_set_by_sync')) {
      context.handle(
          _timelinePreviousBatchSetBySyncMeta,
          timelinePreviousBatchSetBySync.isAcceptableOrUnknown(
              data['timeline_previous_batch_set_by_sync']!,
              _timelinePreviousBatchSetBySyncMeta));
    }
    if (data.containsKey('summary_joined_members_count')) {
      context.handle(
          _summaryJoinedMembersCountMeta,
          summaryJoinedMembersCount.isAcceptableOrUnknown(
              data['summary_joined_members_count']!,
              _summaryJoinedMembersCountMeta));
    }
    if (data.containsKey('summary_invited_members_count')) {
      context.handle(
          _summaryInvitedMembersCountMeta,
          summaryInvitedMembersCount.isAcceptableOrUnknown(
              data['summary_invited_members_count']!,
              _summaryInvitedMembersCountMeta));
    }
    if (data.containsKey('name_change_event_id')) {
      context.handle(
          _nameChangeEventIdMeta,
          nameChangeEventId.isAcceptableOrUnknown(
              data['name_change_event_id']!, _nameChangeEventIdMeta));
    }
    if (data.containsKey('avatar_change_event_id')) {
      context.handle(
          _avatarChangeEventIdMeta,
          avatarChangeEventId.isAcceptableOrUnknown(
              data['avatar_change_event_id']!, _avatarChangeEventIdMeta));
    }
    if (data.containsKey('topic_change_event_id')) {
      context.handle(
          _topicChangeEventIdMeta,
          topicChangeEventId.isAcceptableOrUnknown(
              data['topic_change_event_id']!, _topicChangeEventIdMeta));
    }
    if (data.containsKey('power_levels_change_event_id')) {
      context.handle(
          _powerLevelsChangeEventIdMeta,
          powerLevelsChangeEventId.isAcceptableOrUnknown(
              data['power_levels_change_event_id']!,
              _powerLevelsChangeEventIdMeta));
    }
    if (data.containsKey('join_rules_change_event_id')) {
      context.handle(
          _joinRulesChangeEventIdMeta,
          joinRulesChangeEventId.isAcceptableOrUnknown(
              data['join_rules_change_event_id']!,
              _joinRulesChangeEventIdMeta));
    }
    if (data.containsKey('canonical_alias_change_event_id')) {
      context.handle(
          _canonicalAliasChangeEventIdMeta,
          canonicalAliasChangeEventId.isAcceptableOrUnknown(
              data['canonical_alias_change_event_id']!,
              _canonicalAliasChangeEventIdMeta));
    }
    if (data.containsKey('creation_event_id')) {
      context.handle(
          _creationEventIdMeta,
          creationEventId.isAcceptableOrUnknown(
              data['creation_event_id']!, _creationEventIdMeta));
    }
    if (data.containsKey('upgrade_event_id')) {
      context.handle(
          _upgradeEventIdMeta,
          upgradeEventId.isAcceptableOrUnknown(
              data['upgrade_event_id']!, _upgradeEventIdMeta));
    }
    if (data.containsKey('highlighted_unread_notification_count')) {
      context.handle(
          _highlightedUnreadNotificationCountMeta,
          highlightedUnreadNotificationCount.isAcceptableOrUnknown(
              data['highlighted_unread_notification_count']!,
              _highlightedUnreadNotificationCountMeta));
    }
    if (data.containsKey('total_unread_notification_count')) {
      context.handle(
          _totalUnreadNotificationCountMeta,
          totalUnreadNotificationCount.isAcceptableOrUnknown(
              data['total_unread_notification_count']!,
              _totalUnreadNotificationCountMeta));
    }
    if (data.containsKey('last_message_time_interval')) {
      context.handle(
          _lastMessageTimeIntervalMeta,
          lastMessageTimeInterval.isAcceptableOrUnknown(
              data['last_message_time_interval']!,
              _lastMessageTimeIntervalMeta));
    }
    if (data.containsKey('direct_user_id')) {
      context.handle(
          _directUserIdMeta,
          directUserId.isAcceptableOrUnknown(
              data['direct_user_id']!, _directUserIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoomRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    return RoomRecord.fromData(data, _db,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $RoomsTable createAlias(String alias) {
    return $RoomsTable(_db, alias);
  }
}

class RoomEventRecord extends DataClass implements Insertable<RoomEventRecord> {
  final String id;
  final String type;
  final String roomId;
  final String senderId;
  final DateTime? time;
  final String? content;
  final String? previousContent;
  final String? sentState;
  final String? transactionId;
  final String? stateKey;
  final String? redacts;
  final bool inTimeline;
  RoomEventRecord(
      {required this.id,
      required this.type,
      required this.roomId,
      required this.senderId,
      this.time,
      this.content,
      this.previousContent,
      this.sentState,
      this.transactionId,
      this.stateKey,
      this.redacts,
      required this.inTimeline});
  factory RoomEventRecord.fromData(
      Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return RoomEventRecord(
      id: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      type: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}type'])!,
      roomId: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}room_id'])!,
      senderId: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}sender_id'])!,
      time: const DateTimeType()
          .mapFromDatabaseResponse(data['${effectivePrefix}time']),
      content: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}content']),
      previousContent: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}previous_content']),
      sentState: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}sent_state']),
      transactionId: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}transaction_id']),
      stateKey: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}state_key']),
      redacts: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}redacts']),
      inTimeline: const BoolType()
          .mapFromDatabaseResponse(data['${effectivePrefix}in_timeline'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['room_id'] = Variable<String>(roomId);
    map['sender_id'] = Variable<String>(senderId);
    if (!nullToAbsent || time != null) {
      map['time'] = Variable<DateTime?>(time);
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String?>(content);
    }
    if (!nullToAbsent || previousContent != null) {
      map['previous_content'] = Variable<String?>(previousContent);
    }
    if (!nullToAbsent || sentState != null) {
      map['sent_state'] = Variable<String?>(sentState);
    }
    if (!nullToAbsent || transactionId != null) {
      map['transaction_id'] = Variable<String?>(transactionId);
    }
    if (!nullToAbsent || stateKey != null) {
      map['state_key'] = Variable<String?>(stateKey);
    }
    if (!nullToAbsent || redacts != null) {
      map['redacts'] = Variable<String?>(redacts);
    }
    map['in_timeline'] = Variable<bool>(inTimeline);
    return map;
  }

  RoomEventsCompanion toCompanion(bool nullToAbsent) {
    return RoomEventsCompanion(
      id: Value(id),
      type: Value(type),
      roomId: Value(roomId),
      senderId: Value(senderId),
      time: time == null && nullToAbsent ? const Value.absent() : Value(time),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      previousContent: previousContent == null && nullToAbsent
          ? const Value.absent()
          : Value(previousContent),
      sentState: sentState == null && nullToAbsent
          ? const Value.absent()
          : Value(sentState),
      transactionId: transactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionId),
      stateKey: stateKey == null && nullToAbsent
          ? const Value.absent()
          : Value(stateKey),
      redacts: redacts == null && nullToAbsent
          ? const Value.absent()
          : Value(redacts),
      inTimeline: Value(inTimeline),
    );
  }

  factory RoomEventRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return RoomEventRecord(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      roomId: serializer.fromJson<String>(json['roomId']),
      senderId: serializer.fromJson<String>(json['senderId']),
      time: serializer.fromJson<DateTime?>(json['time']),
      content: serializer.fromJson<String?>(json['content']),
      previousContent: serializer.fromJson<String?>(json['previousContent']),
      sentState: serializer.fromJson<String?>(json['sentState']),
      transactionId: serializer.fromJson<String?>(json['transactionId']),
      stateKey: serializer.fromJson<String?>(json['stateKey']),
      redacts: serializer.fromJson<String?>(json['redacts']),
      inTimeline: serializer.fromJson<bool>(json['inTimeline']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'roomId': serializer.toJson<String>(roomId),
      'senderId': serializer.toJson<String>(senderId),
      'time': serializer.toJson<DateTime?>(time),
      'content': serializer.toJson<String?>(content),
      'previousContent': serializer.toJson<String?>(previousContent),
      'sentState': serializer.toJson<String?>(sentState),
      'transactionId': serializer.toJson<String?>(transactionId),
      'stateKey': serializer.toJson<String?>(stateKey),
      'redacts': serializer.toJson<String?>(redacts),
      'inTimeline': serializer.toJson<bool>(inTimeline),
    };
  }

  RoomEventRecord copyWith(
          {String? id,
          String? type,
          String? roomId,
          String? senderId,
          DateTime? time,
          String? content,
          String? previousContent,
          String? sentState,
          String? transactionId,
          String? stateKey,
          String? redacts,
          bool? inTimeline}) =>
      RoomEventRecord(
        id: id ?? this.id,
        type: type ?? this.type,
        roomId: roomId ?? this.roomId,
        senderId: senderId ?? this.senderId,
        time: time ?? this.time,
        content: content ?? this.content,
        previousContent: previousContent ?? this.previousContent,
        sentState: sentState ?? this.sentState,
        transactionId: transactionId ?? this.transactionId,
        stateKey: stateKey ?? this.stateKey,
        redacts: redacts ?? this.redacts,
        inTimeline: inTimeline ?? this.inTimeline,
      );
  @override
  String toString() {
    return (StringBuffer('RoomEventRecord(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('roomId: $roomId, ')
          ..write('senderId: $senderId, ')
          ..write('time: $time, ')
          ..write('content: $content, ')
          ..write('previousContent: $previousContent, ')
          ..write('sentState: $sentState, ')
          ..write('transactionId: $transactionId, ')
          ..write('stateKey: $stateKey, ')
          ..write('redacts: $redacts, ')
          ..write('inTimeline: $inTimeline')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      id.hashCode,
      $mrjc(
          type.hashCode,
          $mrjc(
              roomId.hashCode,
              $mrjc(
                  senderId.hashCode,
                  $mrjc(
                      time.hashCode,
                      $mrjc(
                          content.hashCode,
                          $mrjc(
                              previousContent.hashCode,
                              $mrjc(
                                  sentState.hashCode,
                                  $mrjc(
                                      transactionId.hashCode,
                                      $mrjc(
                                          stateKey.hashCode,
                                          $mrjc(redacts.hashCode,
                                              inTimeline.hashCode))))))))))));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoomEventRecord &&
          other.id == this.id &&
          other.type == this.type &&
          other.roomId == this.roomId &&
          other.senderId == this.senderId &&
          other.time == this.time &&
          other.content == this.content &&
          other.previousContent == this.previousContent &&
          other.sentState == this.sentState &&
          other.transactionId == this.transactionId &&
          other.stateKey == this.stateKey &&
          other.redacts == this.redacts &&
          other.inTimeline == this.inTimeline);
}

class RoomEventsCompanion extends UpdateCompanion<RoomEventRecord> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> roomId;
  final Value<String> senderId;
  final Value<DateTime?> time;
  final Value<String?> content;
  final Value<String?> previousContent;
  final Value<String?> sentState;
  final Value<String?> transactionId;
  final Value<String?> stateKey;
  final Value<String?> redacts;
  final Value<bool> inTimeline;
  const RoomEventsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.roomId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.time = const Value.absent(),
    this.content = const Value.absent(),
    this.previousContent = const Value.absent(),
    this.sentState = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.stateKey = const Value.absent(),
    this.redacts = const Value.absent(),
    this.inTimeline = const Value.absent(),
  });
  RoomEventsCompanion.insert({
    required String id,
    required String type,
    required String roomId,
    required String senderId,
    this.time = const Value.absent(),
    this.content = const Value.absent(),
    this.previousContent = const Value.absent(),
    this.sentState = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.stateKey = const Value.absent(),
    this.redacts = const Value.absent(),
    required bool inTimeline,
  })  : id = Value(id),
        type = Value(type),
        roomId = Value(roomId),
        senderId = Value(senderId),
        inTimeline = Value(inTimeline);
  static Insertable<RoomEventRecord> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? roomId,
    Expression<String>? senderId,
    Expression<DateTime?>? time,
    Expression<String?>? content,
    Expression<String?>? previousContent,
    Expression<String?>? sentState,
    Expression<String?>? transactionId,
    Expression<String?>? stateKey,
    Expression<String?>? redacts,
    Expression<bool>? inTimeline,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (roomId != null) 'room_id': roomId,
      if (senderId != null) 'sender_id': senderId,
      if (time != null) 'time': time,
      if (content != null) 'content': content,
      if (previousContent != null) 'previous_content': previousContent,
      if (sentState != null) 'sent_state': sentState,
      if (transactionId != null) 'transaction_id': transactionId,
      if (stateKey != null) 'state_key': stateKey,
      if (redacts != null) 'redacts': redacts,
      if (inTimeline != null) 'in_timeline': inTimeline,
    });
  }

  RoomEventsCompanion copyWith(
      {Value<String>? id,
      Value<String>? type,
      Value<String>? roomId,
      Value<String>? senderId,
      Value<DateTime?>? time,
      Value<String?>? content,
      Value<String?>? previousContent,
      Value<String?>? sentState,
      Value<String?>? transactionId,
      Value<String?>? stateKey,
      Value<String?>? redacts,
      Value<bool>? inTimeline}) {
    return RoomEventsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      time: time ?? this.time,
      content: content ?? this.content,
      previousContent: previousContent ?? this.previousContent,
      sentState: sentState ?? this.sentState,
      transactionId: transactionId ?? this.transactionId,
      stateKey: stateKey ?? this.stateKey,
      redacts: redacts ?? this.redacts,
      inTimeline: inTimeline ?? this.inTimeline,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (roomId.present) {
      map['room_id'] = Variable<String>(roomId.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<String>(senderId.value);
    }
    if (time.present) {
      map['time'] = Variable<DateTime?>(time.value);
    }
    if (content.present) {
      map['content'] = Variable<String?>(content.value);
    }
    if (previousContent.present) {
      map['previous_content'] = Variable<String?>(previousContent.value);
    }
    if (sentState.present) {
      map['sent_state'] = Variable<String?>(sentState.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String?>(transactionId.value);
    }
    if (stateKey.present) {
      map['state_key'] = Variable<String?>(stateKey.value);
    }
    if (redacts.present) {
      map['redacts'] = Variable<String?>(redacts.value);
    }
    if (inTimeline.present) {
      map['in_timeline'] = Variable<bool>(inTimeline.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoomEventsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('roomId: $roomId, ')
          ..write('senderId: $senderId, ')
          ..write('time: $time, ')
          ..write('content: $content, ')
          ..write('previousContent: $previousContent, ')
          ..write('sentState: $sentState, ')
          ..write('transactionId: $transactionId, ')
          ..write('stateKey: $stateKey, ')
          ..write('redacts: $redacts, ')
          ..write('inTimeline: $inTimeline')
          ..write(')'))
        .toString();
  }
}

class $RoomEventsTable extends RoomEvents
    with TableInfo<$RoomEventsTable, RoomEventRecord> {
  final GeneratedDatabase _db;
  final String? _alias;
  $RoomEventsTable(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String?> id = GeneratedColumn<String?>(
      'id', aliasedName, false,
      typeName: 'TEXT', requiredDuringInsert: true);
  final VerificationMeta _typeMeta = const VerificationMeta('type');
  late final GeneratedColumn<String?> type = GeneratedColumn<String?>(
      'type', aliasedName, false,
      typeName: 'TEXT', requiredDuringInsert: true);
  final VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  late final GeneratedColumn<String?> roomId = GeneratedColumn<String?>(
      'room_id', aliasedName, false,
      typeName: 'TEXT',
      requiredDuringInsert: true,
      $customConstraints: 'REFERENCES room_events(id)');
  final VerificationMeta _senderIdMeta = const VerificationMeta('senderId');
  late final GeneratedColumn<String?> senderId = GeneratedColumn<String?>(
      'sender_id', aliasedName, false,
      typeName: 'TEXT', requiredDuringInsert: true);
  final VerificationMeta _timeMeta = const VerificationMeta('time');
  late final GeneratedColumn<DateTime?> time = GeneratedColumn<DateTime?>(
      'time', aliasedName, true,
      typeName: 'INTEGER', requiredDuringInsert: false);
  final VerificationMeta _contentMeta = const VerificationMeta('content');
  late final GeneratedColumn<String?> content = GeneratedColumn<String?>(
      'content', aliasedName, true,
      typeName: 'TEXT', requiredDuringInsert: false);
  final VerificationMeta _previousContentMeta =
      const VerificationMeta('previousContent');
  late final GeneratedColumn<String?> previousContent =
      GeneratedColumn<String?>('previous_content', aliasedName, true,
          typeName: 'TEXT', requiredDuringInsert: false);
  final VerificationMeta _sentStateMeta = const VerificationMeta('sentState');
  late final GeneratedColumn<String?> sentState = GeneratedColumn<String?>(
      'sent_state', aliasedName, true,
      typeName: 'TEXT', requiredDuringInsert: false);
  final VerificationMeta _transactionIdMeta =
      const VerificationMeta('transactionId');
  late final GeneratedColumn<String?> transactionId = GeneratedColumn<String?>(
      'transaction_id', aliasedName, true,
      typeName: 'TEXT', requiredDuringInsert: false);
  final VerificationMeta _stateKeyMeta = const VerificationMeta('stateKey');
  late final GeneratedColumn<String?> stateKey = GeneratedColumn<String?>(
      'state_key', aliasedName, true,
      typeName: 'TEXT', requiredDuringInsert: false);
  final VerificationMeta _redactsMeta = const VerificationMeta('redacts');
  late final GeneratedColumn<String?> redacts = GeneratedColumn<String?>(
      'redacts', aliasedName, true,
      typeName: 'TEXT', requiredDuringInsert: false);
  final VerificationMeta _inTimelineMeta = const VerificationMeta('inTimeline');
  late final GeneratedColumn<bool?> inTimeline = GeneratedColumn<bool?>(
      'in_timeline', aliasedName, false,
      typeName: 'INTEGER',
      requiredDuringInsert: true,
      defaultConstraints: 'CHECK (in_timeline IN (0, 1))');
  @override
  List<GeneratedColumn> get $columns => [
        id,
        type,
        roomId,
        senderId,
        time,
        content,
        previousContent,
        sentState,
        transactionId,
        stateKey,
        redacts,
        inTimeline
      ];
  @override
  String get aliasedName => _alias ?? 'room_events';
  @override
  String get actualTableName => 'room_events';
  @override
  VerificationContext validateIntegrity(Insertable<RoomEventRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('room_id')) {
      context.handle(_roomIdMeta,
          roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta));
    } else if (isInserting) {
      context.missing(_roomIdMeta);
    }
    if (data.containsKey('sender_id')) {
      context.handle(_senderIdMeta,
          senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta));
    } else if (isInserting) {
      context.missing(_senderIdMeta);
    }
    if (data.containsKey('time')) {
      context.handle(
          _timeMeta, time.isAcceptableOrUnknown(data['time']!, _timeMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    if (data.containsKey('previous_content')) {
      context.handle(
          _previousContentMeta,
          previousContent.isAcceptableOrUnknown(
              data['previous_content']!, _previousContentMeta));
    }
    if (data.containsKey('sent_state')) {
      context.handle(_sentStateMeta,
          sentState.isAcceptableOrUnknown(data['sent_state']!, _sentStateMeta));
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
          _transactionIdMeta,
          transactionId.isAcceptableOrUnknown(
              data['transaction_id']!, _transactionIdMeta));
    }
    if (data.containsKey('state_key')) {
      context.handle(_stateKeyMeta,
          stateKey.isAcceptableOrUnknown(data['state_key']!, _stateKeyMeta));
    }
    if (data.containsKey('redacts')) {
      context.handle(_redactsMeta,
          redacts.isAcceptableOrUnknown(data['redacts']!, _redactsMeta));
    }
    if (data.containsKey('in_timeline')) {
      context.handle(
          _inTimelineMeta,
          inTimeline.isAcceptableOrUnknown(
              data['in_timeline']!, _inTimelineMeta));
    } else if (isInserting) {
      context.missing(_inTimelineMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoomEventRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    return RoomEventRecord.fromData(data, _db,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $RoomEventsTable createAlias(String alias) {
    return $RoomEventsTable(_db, alias);
  }
}

class EphemeralEventRecord extends DataClass
    implements Insertable<EphemeralEventRecord> {
  final String type;
  final String roomId;
  final String? content;
  EphemeralEventRecord(
      {required this.type, required this.roomId, this.content});
  factory EphemeralEventRecord.fromData(
      Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return EphemeralEventRecord(
      type: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}type'])!,
      roomId: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}room_id'])!,
      content: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}content']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['type'] = Variable<String>(type);
    map['room_id'] = Variable<String>(roomId);
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String?>(content);
    }
    return map;
  }

  EphemeralEventsCompanion toCompanion(bool nullToAbsent) {
    return EphemeralEventsCompanion(
      type: Value(type),
      roomId: Value(roomId),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
    );
  }

  factory EphemeralEventRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return EphemeralEventRecord(
      type: serializer.fromJson<String>(json['type']),
      roomId: serializer.fromJson<String>(json['roomId']),
      content: serializer.fromJson<String?>(json['content']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'type': serializer.toJson<String>(type),
      'roomId': serializer.toJson<String>(roomId),
      'content': serializer.toJson<String?>(content),
    };
  }

  EphemeralEventRecord copyWith(
          {String? type, String? roomId, String? content}) =>
      EphemeralEventRecord(
        type: type ?? this.type,
        roomId: roomId ?? this.roomId,
        content: content ?? this.content,
      );
  @override
  String toString() {
    return (StringBuffer('EphemeralEventRecord(')
          ..write('type: $type, ')
          ..write('roomId: $roomId, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      $mrjf($mrjc(type.hashCode, $mrjc(roomId.hashCode, content.hashCode)));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EphemeralEventRecord &&
          other.type == this.type &&
          other.roomId == this.roomId &&
          other.content == this.content);
}

class EphemeralEventsCompanion extends UpdateCompanion<EphemeralEventRecord> {
  final Value<String> type;
  final Value<String> roomId;
  final Value<String?> content;
  const EphemeralEventsCompanion({
    this.type = const Value.absent(),
    this.roomId = const Value.absent(),
    this.content = const Value.absent(),
  });
  EphemeralEventsCompanion.insert({
    required String type,
    required String roomId,
    this.content = const Value.absent(),
  })  : type = Value(type),
        roomId = Value(roomId);
  static Insertable<EphemeralEventRecord> custom({
    Expression<String>? type,
    Expression<String>? roomId,
    Expression<String?>? content,
  }) {
    return RawValuesInsertable({
      if (type != null) 'type': type,
      if (roomId != null) 'room_id': roomId,
      if (content != null) 'content': content,
    });
  }

  EphemeralEventsCompanion copyWith(
      {Value<String>? type, Value<String>? roomId, Value<String?>? content}) {
    return EphemeralEventsCompanion(
      type: type ?? this.type,
      roomId: roomId ?? this.roomId,
      content: content ?? this.content,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (roomId.present) {
      map['room_id'] = Variable<String>(roomId.value);
    }
    if (content.present) {
      map['content'] = Variable<String?>(content.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EphemeralEventsCompanion(')
          ..write('type: $type, ')
          ..write('roomId: $roomId, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }
}

class $EphemeralEventsTable extends EphemeralEvents
    with TableInfo<$EphemeralEventsTable, EphemeralEventRecord> {
  final GeneratedDatabase _db;
  final String? _alias;
  $EphemeralEventsTable(this._db, [this._alias]);
  final VerificationMeta _typeMeta = const VerificationMeta('type');
  late final GeneratedColumn<String?> type = GeneratedColumn<String?>(
      'type', aliasedName, false,
      typeName: 'TEXT', requiredDuringInsert: true);
  final VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  late final GeneratedColumn<String?> roomId = GeneratedColumn<String?>(
      'room_id', aliasedName, false,
      typeName: 'TEXT',
      requiredDuringInsert: true,
      $customConstraints: 'REFERENCES room_events(id)');
  final VerificationMeta _contentMeta = const VerificationMeta('content');
  late final GeneratedColumn<String?> content = GeneratedColumn<String?>(
      'content', aliasedName, true,
      typeName: 'TEXT', requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [type, roomId, content];
  @override
  String get aliasedName => _alias ?? 'ephemeral_events';
  @override
  String get actualTableName => 'ephemeral_events';
  @override
  VerificationContext validateIntegrity(
      Insertable<EphemeralEventRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('room_id')) {
      context.handle(_roomIdMeta,
          roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta));
    } else if (isInserting) {
      context.missing(_roomIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {type, roomId};
  @override
  EphemeralEventRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    return EphemeralEventRecord.fromData(data, _db,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $EphemeralEventsTable createAlias(String alias) {
    return $EphemeralEventsTable(_db, alias);
  }
}

class DeviceRecord extends DataClass implements Insertable<DeviceRecord> {
  final String id;
  final String userId;
  final String? name;
  final DateTime? lastSeen;
  final String? lastIpAddress;
  DeviceRecord(
      {required this.id,
      required this.userId,
      this.name,
      this.lastSeen,
      this.lastIpAddress});
  factory DeviceRecord.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return DeviceRecord(
      id: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      userId: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}user_id'])!,
      name: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}name']),
      lastSeen: const DateTimeType()
          .mapFromDatabaseResponse(data['${effectivePrefix}last_seen']),
      lastIpAddress: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}last_ip_address']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String?>(name);
    }
    if (!nullToAbsent || lastSeen != null) {
      map['last_seen'] = Variable<DateTime?>(lastSeen);
    }
    if (!nullToAbsent || lastIpAddress != null) {
      map['last_ip_address'] = Variable<String?>(lastIpAddress);
    }
    return map;
  }

  DevicesCompanion toCompanion(bool nullToAbsent) {
    return DevicesCompanion(
      id: Value(id),
      userId: Value(userId),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      lastSeen: lastSeen == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeen),
      lastIpAddress: lastIpAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(lastIpAddress),
    );
  }

  factory DeviceRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return DeviceRecord(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String?>(json['name']),
      lastSeen: serializer.fromJson<DateTime?>(json['lastSeen']),
      lastIpAddress: serializer.fromJson<String?>(json['lastIpAddress']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String?>(name),
      'lastSeen': serializer.toJson<DateTime?>(lastSeen),
      'lastIpAddress': serializer.toJson<String?>(lastIpAddress),
    };
  }

  DeviceRecord copyWith(
          {String? id,
          String? userId,
          String? name,
          DateTime? lastSeen,
          String? lastIpAddress}) =>
      DeviceRecord(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        lastSeen: lastSeen ?? this.lastSeen,
        lastIpAddress: lastIpAddress ?? this.lastIpAddress,
      );
  @override
  String toString() {
    return (StringBuffer('DeviceRecord(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('lastIpAddress: $lastIpAddress')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      id.hashCode,
      $mrjc(
          userId.hashCode,
          $mrjc(name.hashCode,
              $mrjc(lastSeen.hashCode, lastIpAddress.hashCode)))));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceRecord &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.lastSeen == this.lastSeen &&
          other.lastIpAddress == this.lastIpAddress);
}

class DevicesCompanion extends UpdateCompanion<DeviceRecord> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> name;
  final Value<DateTime?> lastSeen;
  final Value<String?> lastIpAddress;
  const DevicesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.lastSeen = const Value.absent(),
    this.lastIpAddress = const Value.absent(),
  });
  DevicesCompanion.insert({
    required String id,
    required String userId,
    this.name = const Value.absent(),
    this.lastSeen = const Value.absent(),
    this.lastIpAddress = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId);
  static Insertable<DeviceRecord> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String?>? name,
    Expression<DateTime?>? lastSeen,
    Expression<String?>? lastIpAddress,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (lastSeen != null) 'last_seen': lastSeen,
      if (lastIpAddress != null) 'last_ip_address': lastIpAddress,
    });
  }

  DevicesCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String?>? name,
      Value<DateTime?>? lastSeen,
      Value<String?>? lastIpAddress}) {
    return DevicesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      lastSeen: lastSeen ?? this.lastSeen,
      lastIpAddress: lastIpAddress ?? this.lastIpAddress,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String?>(name.value);
    }
    if (lastSeen.present) {
      map['last_seen'] = Variable<DateTime?>(lastSeen.value);
    }
    if (lastIpAddress.present) {
      map['last_ip_address'] = Variable<String?>(lastIpAddress.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DevicesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('lastIpAddress: $lastIpAddress')
          ..write(')'))
        .toString();
  }
}

class $DevicesTable extends Devices
    with TableInfo<$DevicesTable, DeviceRecord> {
  final GeneratedDatabase _db;
  final String? _alias;
  $DevicesTable(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String?> id = GeneratedColumn<String?>(
      'id', aliasedName, false,
      typeName: 'TEXT', requiredDuringInsert: true);
  final VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedColumn<String?> userId = GeneratedColumn<String?>(
      'user_id', aliasedName, false,
      typeName: 'TEXT', requiredDuringInsert: true);
  final VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String?> name = GeneratedColumn<String?>(
      'name', aliasedName, true,
      typeName: 'TEXT', requiredDuringInsert: false);
  final VerificationMeta _lastSeenMeta = const VerificationMeta('lastSeen');
  late final GeneratedColumn<DateTime?> lastSeen = GeneratedColumn<DateTime?>(
      'last_seen', aliasedName, true,
      typeName: 'INTEGER', requiredDuringInsert: false);
  final VerificationMeta _lastIpAddressMeta =
      const VerificationMeta('lastIpAddress');
  late final GeneratedColumn<String?> lastIpAddress = GeneratedColumn<String?>(
      'last_ip_address', aliasedName, true,
      typeName: 'TEXT', requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, name, lastSeen, lastIpAddress];
  @override
  String get aliasedName => _alias ?? 'devices';
  @override
  String get actualTableName => 'devices';
  @override
  VerificationContext validateIntegrity(Insertable<DeviceRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('last_seen')) {
      context.handle(_lastSeenMeta,
          lastSeen.isAcceptableOrUnknown(data['last_seen']!, _lastSeenMeta));
    }
    if (data.containsKey('last_ip_address')) {
      context.handle(
          _lastIpAddressMeta,
          lastIpAddress.isAcceptableOrUnknown(
              data['last_ip_address']!, _lastIpAddressMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeviceRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    return DeviceRecord.fromData(data, _db,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $DevicesTable createAlias(String alias) {
    return $DevicesTable(_db, alias);
  }
}

abstract class _$Database extends GeneratedDatabase {
  _$Database(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  late final $MyUsersTable myUsers = $MyUsersTable(this);
  late final $RoomsTable rooms = $RoomsTable(this);
  late final $RoomEventsTable roomEvents = $RoomEventsTable(this);
  late final $EphemeralEventsTable ephemeralEvents =
      $EphemeralEventsTable(this);
  late final $DevicesTable devices = $DevicesTable(this);
  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [myUsers, rooms, roomEvents, ephemeralEvents, devices];
}
