// Copyright (C) 2020  Mathieu Velten
// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

library matrix_sdk_moor;

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:moor/backends.dart';
import 'package:moor/ffi.dart';
import 'package:moor/moor.dart';
import 'package:pedantic/pedantic.dart';

import '../../../matrix_sdk.dart';
import '../../context.dart';
import '../../room/member/member.dart';
import '../../my_user.dart';
import '../../room/rooms.dart';
import '../../room/timeline.dart';

import '../../event/room/raw_room_event.dart';

import '../../event/ephemeral/ephemeral.dart';
import '../../event/ephemeral/ephemeral_event.dart';
import '../../event/ephemeral/receipt_event.dart';
import '../../event/ephemeral/typing_event.dart';

import '../../event/room/state/canonical_alias_change_event.dart';

import 'database.dart' hide Rooms;
import 'package:collection/collection.dart';

class MoorStore extends Store {
  final DelegatedDatabase _executor;

  MoorStore(this._executor);

  bool _isOpen = false;

  @override
  bool get isOpen => _isOpen;

  Database? _db;

  @override
  void open() {
    if (!isOpen) {
      _db = Database(_executor);
      _isOpen = true;
    }
  }

  @override
  Future<void> close() async {
    await _db?.close();
    _db = null;
    _isOpen = false;
  }

  // Keep track of the invites to delete invite state when the room is joined
  final _invites = <RoomId>{};

  void _setInvites(Iterable<Room?> rooms) {
    _invites.addAll(
      rooms
          .where((room) => room?.me?.membership == Membership.invited)
          .whereNotNull()
          .map((r) => r.id),
    );
  }

  /// If [isolated] is true, will create an [IsolatedUpdater] to manage
  /// the user's updates.
  @override
  Future<MyUser?> getMyUser({
    required Iterable<RoomId> roomIds,
    int timelineLimit = 15,
    bool isolated = false,
    required StoreLocation storeLocation,
  }) async {
    final myUserWithDeviceRecord = await _db?.getMyUserRecord();

    if (myUserWithDeviceRecord == null) {
      return null;
    }

    final myUserRecord = myUserWithDeviceRecord.myUserRecord;
    final deviceRecord = myUserWithDeviceRecord.deviceRecord;

    final myId = UserId(myUserRecord.id!);

    final homeserver = Homeserver(Uri.parse(myUserRecord.homeserver!));

    final context = Context(myId: myId);

    final user = MyUser(
      id: myId,
      name: myUserRecord.name!,
      avatarUrl: myUserRecord.avatarUrl != null
          ? Uri.parse(myUserRecord.avatarUrl!)
          : null,
      accessToken: myUserRecord.accessToken,
      syncToken: myUserRecord.syncToken!,
      currentDevice: deviceRecord.toDevice(),
      rooms: Rooms(
        await getRooms(
          roomIds,
          timelineLimit: timelineLimit,
          context: context,
          memberIds: [myId],
        ),
        context: context,
      ),
      hasSynced: myUserRecord.hasSynced ?? false,
      isLoggedOut: myUserRecord.isLoggedOut ?? true,
    );

    await close();

    Updater updater;
    if (isolated) {
      updater = await Updater.isolated(user, homeserver, storeLocation);
    } else {
      updater = Updater(user, homeserver, storeLocation);
    }

    return updater.user;
  }

  @override
  Future<void> setMyUserDelta(MyUser myUser) async {
    await _db?.setMyUser(
      MyUsersCompanion(
        homeserver: myUser.context?.homeServer != null
            ? Value(myUser.context?.homeServer?.url.toString())
            : Value.absent(),
        id: myUser.id.value.isEmpty
            ? Value(myUser.id.toString())
            : Value.absent(),
        name: Value(myUser.name),
        avatarUrl: myUser.avatarUrl != null
            ? Value(myUser.avatarUrl.toString())
            : Value.absent(),
        accessToken: myUser.accessToken != null
            ? Value(myUser.accessToken.toString())
            : Value.absent(),
        syncToken:
            myUser.syncToken != null ? Value(myUser.syncToken) : Value.absent(),
        currentDeviceId: myUser.currentDevice?.id != null
            ? Value(myUser.currentDevice?.id.toString())
            : Value.absent(),
        hasSynced:
            myUser.hasSynced != null ? Value(myUser.hasSynced) : Value.absent(),
        isLoggedOut: myUser.isLoggedOut != null
            ? Value(myUser.isLoggedOut)
            : Value.absent(),
      ),
    );

    if (myUser.currentDevice != null) {
      await _db?.setDeviceRecords([myUser.currentDevice!.toCompanion()]);
    }

    if (myUser.rooms != null) {
      _setInvites(myUser.rooms!);

      final previouslyInvitedIds = myUser.rooms
          ?.where((room) =>
              room.me?.membership == Membership.joined &&
              _invites.contains(room.id))
          .map((room) => room.id.toString())
          .toList();

      if (previouslyInvitedIds?.isNotEmpty == true) {
        unawaited(
          _db?.deleteInviteStates(previouslyInvitedIds!),
        );
      }

      await _db!.setRooms(
          myUser.rooms!.map((r) => r.toCompanion()).whereNotNull().toList());

      // Set room state
      await _db?.setRoomEventRecords(
        myUser.rooms!
            .map((room) => room.stateEvents)
            .whereNotNull()
            .expand((stateEvents) => [
                  stateEvents.nameChange,
                  stateEvents.avatarChange,
                  stateEvents.topicChange,
                  stateEvents.powerLevelsChange,
                  stateEvents.joinRulesChange,
                  stateEvents.canonicalAliasChange,
                  stateEvents.creation,
                  stateEvents.upgrade,
                ])
            .whereNotNull()
            .map((event) => event.toRecord(inTimeline: false))
            .toList(),
      );

      await _db?.setEphemeralEventRecords(
        myUser.rooms!
            .map((room) => room.ephemeral)
            .whereNotNull()
            .expand((ephemeral) => ephemeral)
            .where((e) => e is! TypingEvent)
            .map((e) => e.toRecord())
            .toList(),
      );

      // Set member states
      await _db?.setRoomEventRecords(
        myUser.rooms!
            .map((room) => room.memberTimeline?.map((m) => m.event) ?? [])
            .expand((events) => events)
            .whereNotNull()
            .map((event) => event.toRecord(inTimeline: false))
            .toList(),
      );

      // Set timeline. If any of the (member) state events were just set,
      // they'll be overridden with inTimeline = true.
      await _db?.setRoomEventRecords(
        myUser.rooms!
            .map((room) => room.timeline)
            .whereNotNull()
            .expand((timeline) => timeline)
            .map((event) => event.toRecord(inTimeline: true))
            .toList(),
      );
    }
  }

  @override
  Future<Iterable<Room>> getRooms(
    Iterable<RoomId>? roomIds, {
    Context? context,
    required int timelineLimit,
    Iterable<UserId>? memberIds,
  }) async {
    final roomRecords = (await _db?.getRoomRecords(
          roomIds?.map((id) => id.toString()),
        )) ??
        [];

    // TODO: Optimize?
    final rooms = await Future.wait(roomRecords.map((record) async {
      final roomRecord = record.roomRecord;
      final roomId = RoomId(roomRecord.id);

      final roomContext = context != null
          ? RoomContext.inherit(
              context,
              roomId: roomId,
            )
          : null;

      var timeline = Timeline.empty(context: roomContext);
      var memberTimeline = MemberTimeline.empty(context: roomContext);
      if (timelineLimit > 0) {
        final messages = await getMessages(
          roomId,
          count: timelineLimit,
          memberIds: memberIds,
        );

        timeline = Timeline(
          messages.events,
          context: roomContext,
          previousBatch: roomRecord.timelinePreviousBatch,
          previousBatchSetBySync: roomRecord.timelinePreviousBatchSetBySync,
        );

        memberTimeline = MemberTimeline(
          messages.state,
          context: roomContext,
        );
      }

      final ephemeral = Ephemeral(
        await _db!.getEphemeralEventRecords(roomId.toString()).then(
              (records) => records
                  .map((record) => record.toEphemeralEvent())
                  .whereNotNull(),
            ),
      );

      return Room(
        context: context,
        id: RoomId(roomRecord.id),
        stateEvents: RoomStateEvents(
          nameChange: record.nameChangeRecord.toRoomEvent(),
          avatarChange: record.avatarChangeRecord.toRoomEvent(),
          topicChange: record.topicChangeRecord.toRoomEvent(),
          powerLevelsChange: record.powerLevelsChangeRecord.toRoomEvent(),
          joinRulesChange: record.joinRulesChangeRecord.toRoomEvent(),
          canonicalAliasChange: record.canonicalAliasChangeRecord.toRoomEvent(),
          creation: record.creationRecord.toRoomEvent(),
          upgrade: record.upgradeRecord.toRoomEvent(),
        ),
        timeline: timeline,
        memberTimeline: memberTimeline,
        summary: RoomSummary(
          joinedMembersCount: roomRecord.summaryJoinedMembersCount,
          invitedMembersCount: roomRecord.summaryInvitedMembersCount,
        ),
        directUserId: roomRecord.directUserId != null
            ? UserId(roomRecord.directUserId ?? '')
            : null,
        highlightedUnreadNotificationCount:
            roomRecord.highlightedUnreadNotificationCount,
        totalUnreadNotificationCount: roomRecord.totalUnreadNotificationCount,
        ephemeral: ephemeral,
      );
    }));

    _setInvites(rooms);

    return rooms;
  }

  @override
  Future<Messages> getMessages(
    RoomId roomId, {
    int count = 20,
    DateTime? fromTime,
    Iterable<UserId>? memberIds,
  }) async {
    final events = (await _db
            ?.getRoomEventRecords(
              roomId.toString(),
              count: count,
              fromTime: fromTime,
              inTimeline: true,
            )
            .then((records) =>
                records.map((r) => r.toRoomEvent()).whereNotNull())) ??
        [];

    var relevantUserIds = events
        .whereNotNull()
        .map((e) => [e.senderId, if (e is MemberChangeEvent) e.subjectId])
        .expand((ids) => ids);

    if (memberIds != null) {
      relevantUserIds = relevantUserIds.followedBy(memberIds);
    }

    final uniqueIdStrings = Set.of(relevantUserIds.map((id) => id.toString()));

    Future<Iterable<Member>> getMembers(Iterable<String> ids) async {
      return _db!
          .getMemberEventRecordsOfSenders(
            roomId.toString(),
            ids,
          )
          .then(
            (records) => records.map((r) => r.toRoomEvent()).whereNotNull().map(
                  (r) => Member.fromEvent(r as MemberChangeEvent),
                ),
          );
    }

    var members = await getMembers(uniqueIdStrings);

    final missingIdStrings = <String>{
      ...members
          .where((m) => !uniqueIdStrings.contains(m.event.subjectId.toString()))
          .map((m) => m.event.subjectId.toString()),
      ...members
          .where((m) => !uniqueIdStrings.contains(m.event.senderId.toString()))
          .map((m) => m.event.senderId.toString()),
    };

    if (missingIdStrings.isNotEmpty) {
      members = LinkedHashSet(
        equals: (a, b) => a.event.equals(b.event),
        hashCode: (m) => m.event.id.hashCode,
      )..addAll([
          ...members,
          ...await getMembers(missingIdStrings),
        ]);
    }

    return Messages(events, members);
  }

  @override
  Future<Iterable<RoomEvent>> getUnsentEvents() async {
    // TODO
    return [];
  }

  @override
  Future<Iterable<Member>> getMembers(
    RoomId roomId, {
    int count = 20,
    DateTime? fromTime,
  }) async {
    return _db!
        .getRoomEventRecords(
          roomId.toString(),
          count: count,
          fromTime: fromTime,
          onlyMemberChanges: true,
        )
        .then(
          (records) => records.map(
              (e) => Member.fromEvent(e.toRoomEvent() as MemberChangeEvent)),
        );
  }
}

abstract class MoorStoreLocation extends StoreLocation<MoorStore> {
  MoorStoreLocation();

  factory MoorStoreLocation.file(File file) => MoorStoreFileLocation(file);
}

/// TODO: Move to dart:io only file/library
class MoorStoreFileLocation extends MoorStoreLocation {
  final File file;

  MoorStoreFileLocation(this.file);

  @override
  MoorStore create() => MoorStore(VmDatabase(file));
}

/// TODO: Move to dart:io only file/library
class MoorStoreMemoryLocation extends MoorStoreLocation {
  MoorStoreMemoryLocation();

  @override
  MoorStore create() => MoorStore(VmDatabase.memory());
}

extension on DeviceRecord {
  Device toDevice() {
    return Device(
      id: DeviceId(id),
      userId: UserId(userId),
      name: name,
      lastSeen: lastSeen,
      lastIpAddress: lastIpAddress,
    );
  }
}

extension on Device {
  DevicesCompanion toCompanion() {
    return DevicesCompanion(
      id: id != null ? Value(id.toString()) : Value.absent(),
      userId: userId != null ? Value(userId.toString()) : Value.absent(),
      name: name != null ? Value(name) : Value.absent(),
      lastSeen: lastSeen != null ? Value(lastSeen) : Value.absent(),
      lastIpAddress:
          lastIpAddress != null ? Value(lastIpAddress) : Value.absent(),
    );
  }
}

extension on Room {
  RoomsCompanion toCompanion() {
    return RoomsCompanion(
      id: Value(id.toString()),
      timelinePreviousBatch: timeline?.previousBatch != null
          ? Value(timeline?.previousBatch)
          : Value.absent(),
      timelinePreviousBatchSetBySync: timeline?.previousBatchSetBySync != null
          ? Value(timeline?.previousBatchSetBySync)
          : Value.absent(),
      summaryJoinedMembersCount: summary?.joinedMembersCount != null
          ? Value(summary?.joinedMembersCount)
          : Value.absent(),
      summaryInvitedMembersCount: summary?.invitedMembersCount != null
          ? Value(summary?.invitedMembersCount)
          : Value.absent(),
      highlightedUnreadNotificationCount:
          highlightedUnreadNotificationCount != null
              ? Value(highlightedUnreadNotificationCount)
              : Value.absent(),
      totalUnreadNotificationCount: totalUnreadNotificationCount != null
          ? Value(totalUnreadNotificationCount)
          : Value.absent(),
      directUserId: directUserId != null
          ? Value(directUserId.toString())
          : Value.absent(),
      nameChangeEventId: stateEvents?.nameChange?.storedId != null
          ? Value(stateEvents?.nameChange?.storedId)
          : Value.absent(),
      avatarChangeEventId: stateEvents?.avatarChange?.storedId != null
          ? Value(stateEvents?.avatarChange?.storedId)
          : Value.absent(),
      topicChangeEventId: stateEvents?.topicChange?.storedId != null
          ? Value(stateEvents?.topicChange?.storedId)
          : Value.absent(),
      powerLevelsChangeEventId: stateEvents?.powerLevelsChange?.storedId != null
          ? Value(stateEvents?.powerLevelsChange?.storedId)
          : Value.absent(),
      joinRulesChangeEventId: stateEvents?.joinRulesChange?.storedId != null
          ? Value(stateEvents?.joinRulesChange?.storedId)
          : Value.absent(),
      canonicalAliasChangeEventId:
          stateEvents?.canonicalAliasChange?.storedId != null
              ? Value(stateEvents?.canonicalAliasChange?.storedId)
              : Value.absent(),
      creationEventId: stateEvents?.creation?.storedId != null
          ? Value(stateEvents?.creation?.storedId)
          : Value.absent(),
      upgradeEventId: stateEvents?.upgrade?.storedId != null
          ? Value(stateEvents?.upgrade?.storedId)
          : Value.absent(),
    );
  }
}

extension on RoomEvent {
  RoomEventRecord toRecord({
    required bool inTimeline,
  }) {
    String? stateKey, previousContent;
    if (this is StateEvent) {
      final it = this as StateEvent;
      // Automatic cast doesn't seem to work on this
      stateKey = it.stateKey;

      previousContent = it.previousContent != null
          ? json.encode(it.previousContent!.toJson())
          : null;
    }

    String? redacts;
    if (this is RedactionEvent) {
      redacts = (this as RedactionEvent).redacts.toString();
    }

    return RoomEventRecord(
      id: storedId,
      type: type,
      roomId: roomId.toString(),
      senderId: senderId.toString(),
      time: time,
      content: content != null ? json.encode(content?.toJson()) : null,
      previousContent: previousContent,
      sentState: sentState?.toShortString(),
      transactionId: transactionId,
      stateKey: stateKey,
      redacts: redacts,
      inTimeline: inTimeline,
    );
  }

  String get storedId {
    var id = this.id.toString();

    if (this is StateEvent) {
      final it = this as StateEvent;
      id = '$roomId:$runtimeType:${it.stateKey}';
    }

    return id;
  }
}

extension on RoomEventRecord {
  T? toRoomEvent<T extends RoomEvent>() {
    final args = RoomEventArgs(
      id: EventId(id),
      senderId: UserId(senderId),
      time: time,
      roomId: RoomId(roomId),
      sentState: sentState?.toSentState(),
      transactionId: transactionId,
    );

    dynamic decodedContent, decodedPreviousContent;
    if (content != null) {
      decodedContent = json.decode(content!);
    }

    if (previousContent != null) {
      decodedPreviousContent = json.decode(previousContent!);
    }

    switch (type) {
      case MessageEvent.matrixType:
        return MessageEvent.instance(
          args,
          content: MessageEventContent.fromJson(decodedContent),
        ) as T;
      case MemberChangeEvent.matrixType:
        return MemberChangeEvent(
          args,
          content: MemberChange.fromJson(decodedContent),
          previousContent: MemberChange.fromJson(decodedPreviousContent),
          stateKey: stateKey ?? '',
        ) as T;
      case RedactionEvent.matrixType:
        return RedactionEvent(
          args,
          content: Redaction.fromJson(decodedContent),
          redacts: EventId(redacts ?? ''),
        ) as T;
      case RoomAvatarChangeEvent.matrixType:
        return RoomAvatarChangeEvent(
          args,
          content: RoomAvatarChange.fromJson(decodedContent),
          previousContent: RoomAvatarChange.fromJson(decodedPreviousContent),
        ) as T;
      case RoomNameChangeEvent.matrixType:
        return RoomNameChangeEvent(
          args,
          content: RoomNameChange.fromJson(decodedContent),
          previousContent: RoomNameChange.fromJson(decodedPreviousContent),
        ) as T;
      case RoomCreationEvent.matrixType:
        return RoomCreationEvent(
          args,
          content: RoomCreation.fromJson(decodedContent),
          previousContent: RoomCreation.fromJson(decodedPreviousContent),
        ) as T;
      case RoomUpgradeEvent.matrixType:
        return RoomUpgradeEvent(
          args,
          content: RoomUpgrade.fromJson(decodedContent),
          previousContent: RoomUpgrade.fromJson(decodedPreviousContent),
        ) as T;
      case TopicChangeEvent.matrixType:
        return TopicChangeEvent(
          args,
          content: TopicChange.fromJson(decodedContent),
          previousContent: TopicChange.fromJson(decodedPreviousContent),
        ) as T;
      case PowerLevelsChangeEvent.matrixType:
        return PowerLevelsChangeEvent.instance(
          args,
          content: PowerLevelsChange.fromJson(decodedContent),
          previousContent: PowerLevelsChange.fromJson(decodedPreviousContent),
        ) as T;
      case JoinRulesChangeEvent.matrixType:
        return JoinRulesChangeEvent(
          args,
          content: JoinRules.fromJson(decodedContent),
          previousContent: JoinRules.fromJson(decodedPreviousContent),
        ) as T;
      case CanonicalAliasChangeEvent.matrixType:
        return CanonicalAliasChangeEvent(
          args,
          content: CanonicalAliasChange.fromJson(decodedContent),
          previousContent: CanonicalAliasChange.fromJson(
            decodedPreviousContent,
          ),
        ) as T;
      default:
        return stateKey != null
            ? RawStateEvent(
                args,
                type: type,
                content: RawEventContent.fromJson(decodedContent),
                previousContent:
                    RawEventContent.fromJson(decodedPreviousContent),
                stateKey: stateKey,
              ) as T
            : RawRoomEvent(
                args,
                type: type,
                content: RawEventContent.fromJson(decodedContent),
              ) as T;
    }
  }
}

extension on EphemeralEvent {
  EphemeralEventRecord toRecord() {
    return EphemeralEventRecord(
      type: type,
      roomId: roomId.toString(),
      content: content != null ? json.encode(content!.toJson()) : null,
    );
  }
}

extension on EphemeralEventRecord {
  EphemeralEvent? toEphemeralEvent() {
    switch (type) {
      case ReceiptEvent.matrixType:
        return ReceiptEvent(
          roomId: RoomId(roomId),
          content: Receipts.fromJson(
            content != null ? json.decode(content!) : null,
          ),
        );
      case TypingEvent.matrixType:
        return TypingEvent(
          roomId: RoomId(roomId),
          content: Typers.fromJson(
            content != null ? json.decode(content!) : null,
          ),
        );
      default:
        // TODO: Custom ephemeral events
        return null;
    }
  }
}

extension on SentState {
  String toShortString() => toString().split('.')[1];
}

extension on String {
  SentState? toSentState() {
    switch (this) {
      case 'unsent':
        return SentState.unsent;
      case 'sent':
        return SentState.sent;
      default:
        return null;
    }
  }
}
