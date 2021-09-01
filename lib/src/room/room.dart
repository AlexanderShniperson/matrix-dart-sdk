// Copyright (C) 2019  Wilko Manger
// Copyright (C) 2019  Mathieu Velten
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:collection/collection.dart';
import 'package:matrix_sdk/src/model/request_update.dart';
import 'package:matrix_sdk/src/model/update.dart';
import 'package:meta/meta.dart';
import '../model/context.dart';
import '../event/event.dart';
import '../event/room/message_event.dart';
import '../event/room/room_event.dart';
import '../event/ephemeral/ephemeral_event.dart';
import '../event/ephemeral/receipt_event.dart';
import '../event/room/state/join_rules_change_event.dart';
import '../event/room/state/power_levels_change_event.dart';
import '../event/room/state/room_creation_event.dart';
import '../event/room/state/room_upgrade_event.dart';
import '../event/room/state/state_event.dart';
import '../event/room/state/topic_change_event.dart';
import '../event/room/state/room_avatar_change_event.dart';
import '../event/room/state/room_name_change_event.dart';
import '../event/room/state/canonical_alias_change_event.dart';
import '../event/room/raw_room_event.dart';
import '../event/ephemeral/ephemeral.dart';
import '../homeserver.dart';
import '../model/identifier.dart';
import '../model/matrix_user.dart';
import 'member/member.dart';
import 'member/member_timeline.dart';
import 'member/membership.dart';
import '../model/my_user.dart';
import 'timeline.dart';

@immutable
class Room with Identifiable<RoomId> implements Contextual<Room> {
  @override
  final RoomContext? context;

  /// Most recent state of the associated [MyUser] (via [context]) in this room.
  final Member? me;

  @override
  final RoomId id;

  int lastMessageTimeInterval;

  /// Events timeline.
  final Timeline? timeline;

  final MemberTimeline? memberTimeline;

  /// Most recent user states of currently loaded members.
  ///
  /// Note that these are not only joined members, but also the ones who
  /// left, are invited, banned or kicked. Use [joined] on [members] to get
  /// the currently loaded joined members.
  ///
  /// If [members.joined.length] matches [summary.joinedMembersCount], all
  /// joined members are loaded. Same goes for [members.invited.length] and
  /// [summary.invitedMembersCount].
  final Iterable<Member>? members;

  final RoomSummary? summary;

  /// The latest [StateEvent]s of this room.
  final RoomStateEvents? stateEvents;

  String? get name => stateEvents?.nameChange?.content?.name;

  Uri? get avatarUrl => stateEvents?.avatarChange?.content?.url;

  String? get topic => stateEvents?.topicChange?.content?.topic;

  /// Power levels for this room to do a certain action or send
  /// certain events.
  ///
  /// Also defaults and info of which user has which power level.
  final PowerLevels? powerLevels;

  JoinRule? get joinRule => stateEvents?.joinRulesChange?.content?.rule;

  RoomAlias? get canonicalAlias =>
      stateEvents?.canonicalAliasChange?.content?.canonicalAlias;

  Iterable<RoomAlias>? get alternativeAliases =>
      stateEvents?.canonicalAliasChange?.content?.alternativeAliases;

  /// [MatrixUser] that created this room.
  UserId? get creatorId => stateEvents?.creation?.creatorId;

  /// Whether this room is a replacement for another room.
  ///
  /// See [replacesId] to see which room was replaced by this room.
  bool get isReplacement => replacesId != null;

  /// The [RoomId] of the room that was replaced by this room.
  RoomId? get replacesId => stateEvents?.creation?.content?.previousRoomId;

  /// Whether this room is upgraded to another room.
  ///
  /// See [replacementId] to see which room this was upgraded.
  bool get isUpgraded => replacementId != null;

  /// The [RoomId] of the room that replaced this room.
  RoomId? get replacementId => stateEvents?.upgrade?.content?.replacementRoomId;

  final Ephemeral? ephemeral;

  Iterable<UserId> get typingUserIds =>
      ephemeral?.typingEvent?.content?.typerIds ?? [];

  // TODO: Make not-lazy?
  ReadReceipts get readReceipts => ReadReceipts(
        ephemeral?.receiptEvent?.content?.receipts.whereReceiptType(
              ReceiptType.read,
            ) ??
            [],
        context: context,
      );

  final int? highlightedUnreadNotificationCount;

  final int? totalUnreadNotificationCount;

  /// If this room is direct, this is the id of the user the conversation is
  /// with.
  final UserId? directUserId;

  bool get isDirect => directUserId != null;

  Room({
    Context? context,
    required this.id,
    this.stateEvents,
    this.timeline,
    this.memberTimeline,
    this.summary,
    this.directUserId,
    this.highlightedUnreadNotificationCount,
    this.totalUnreadNotificationCount,
    this.ephemeral,
    this.lastMessageTimeInterval = 0,
  })  : context =
            context != null ? RoomContext.inherit(context, roomId: id) : null,
        powerLevels = stateEvents?.powerLevelsChange != null
            ? PowerLevels._(stateEvents?.powerLevelsChange)
            : null,
        members = memberTimeline
            ?.map((m) => m.id)
            .toSet()
            .map(memberTimeline.get)
            .whereNotNull()
            .toList(growable: false),
        me = context != null && memberTimeline != null
            ? memberTimeline.get(context.myId!)
            : null;

  /// Creates a room with default values.
  Room.base({
    required Context context,
    required RoomId id,
  }) : this(
          context: context,
          id: id,
          stateEvents: const RoomStateEvents(),
          timeline: Timeline.empty(
            context: RoomContext.inherit(context, roomId: id),
          ),
          memberTimeline: MemberTimeline.empty(
            context: RoomContext.inherit(context, roomId: id),
          ),
          summary: const RoomSummary(),
          directUserId: null,
          highlightedUnreadNotificationCount: 0,
          totalUnreadNotificationCount: 0,
          ephemeral: Ephemeral([]),
        );

  /// Create a room (delta) from json, specifically from a sync's response.
  factory Room.fromJson(
    Map<String, dynamic> body, {
    required RoomContext context,
  }) {
    final responseTimeline = body['timeline'];

    final notifications = body['unread_notifications'];

    int? highlightedUnreadNotificationCount, totalUnreadNotificationCount;
    if (notifications != null) {
      highlightedUnreadNotificationCount = notifications['highlight_count'];
      totalUnreadNotificationCount = notifications['notification_count'];
    }

    final responseState = body['state'] ?? body['invite_state'];

    var stateEvents = (responseState['events'] as List<dynamic>?)
        ?.map(
          (json) => RoomEvent.fromJson(json, roomId: context.roomId),
        )
        .whereNotNull();
    if (stateEvents?.isEmpty == true) {
      stateEvents = null;
    }

    final timeline = responseTimeline != null
        ? Timeline.fromJson(
            (responseTimeline['events'] as List<dynamic>).cast(),
            context: context,
            previousBatch: responseTimeline['prev_batch'],
            previousBatchSetBySync: true,
          )
        : Timeline.empty(context: context);

    RoomStateEvents? state = RoomStateEvents.fromEvents(stateEvents);
    state = state.merge(RoomStateEvents.fromEvents(timeline));
    if (state.nameChange == null &&
        state.avatarChange == null &&
        state.topicChange == null &&
        state.powerLevelsChange == null &&
        state.joinRulesChange == null &&
        state.creation == null &&
        state.upgrade == null) {
      // If all properties are empty, set state to null
      state = null;
    }

    MemberTimeline? members = MemberTimeline.fromEvents([
      ...stateEvents ?? [],
      ...timeline,
    ]);
    if (members.isEmpty) {
      members = null;
    }

    final ephemeral = body['ephemeral'] != null
        ? Ephemeral.fromJson(
            body['ephemeral'],
            context: context,
          )
        : null;

    RoomSummary? summary = body['summary'] != null
        ? RoomSummary.fromJson(body['summary'])
        : RoomSummary();
    if (summary.joinedMembersCount == null &&
        summary.invitedMembersCount == null) {
      summary = null;
    }

    return Room(
      context: context,
      id: context.roomId,
      stateEvents: state,
      timeline: timeline,
      memberTimeline: members,
      summary: summary,
      highlightedUnreadNotificationCount: highlightedUnreadNotificationCount,
      totalUnreadNotificationCount: totalUnreadNotificationCount,
      ephemeral: ephemeral,
    );
  }

  Room copyWith({
    Context? context,
    RoomId? id,
    Membership? myMembership,
    RoomStateEvents? stateEvents,
    Timeline? timeline,
    RoomSummary? summary,
    MemberTimeline? memberTimeline,
    UserId? directUserId,
    int? highlightedUnreadNotificationCount,
    int? totalUnreadNotificationCount,
    Ephemeral? ephemeral,
  }) {
    id ??= this.id;
    timeline ??= this.timeline;
    memberTimeline ??= this.memberTimeline;

    // Make sure all contexts are changed
    if (context != null && context != this.context) {
      final roomContext = RoomContext.inherit(context, roomId: id);

      timeline = timeline?.copyWith(
        context: roomContext,
      );

      memberTimeline = memberTimeline?.copyWith(
        context: roomContext,
      );
    }

    return Room(
      context: context ?? this.context,
      id: id,
      stateEvents: stateEvents ?? this.stateEvents,
      timeline: timeline,
      memberTimeline: memberTimeline,
      summary: summary ?? this.summary,
      directUserId: directUserId ?? this.directUserId,
      highlightedUnreadNotificationCount: highlightedUnreadNotificationCount ??
          this.highlightedUnreadNotificationCount,
      totalUnreadNotificationCount:
          totalUnreadNotificationCount ?? this.totalUnreadNotificationCount,
      ephemeral: ephemeral ?? this.ephemeral,
    );
  }

  Room merge(Room? other) {
    if (other == null) {
      return this;
    }

    RoomStateEvents? stateEvents;
    MemberTimeline? memberTimeline;

    // If we joined a room, don't keep previous state
    if (me?.membership == Membership.invited &&
        other.me?.membership == Membership.joined) {
      stateEvents = other.stateEvents;
      memberTimeline = other.memberTimeline;
    } else {
      stateEvents =
          this.stateEvents?.merge(other.stateEvents) ?? other.stateEvents;
      memberTimeline = this.memberTimeline?.merge(other.memberTimeline) ??
          other.memberTimeline;
    }

    return copyWith(
      context: other.context,
      id: other.id,
      stateEvents: stateEvents,
      timeline: timeline?.merge(other.timeline) ?? other.timeline,
      memberTimeline: memberTimeline,
      summary: summary?.merge(other.summary) ?? other.summary,
      directUserId: other.directUserId,
      highlightedUnreadNotificationCount:
          other.highlightedUnreadNotificationCount,
      totalUnreadNotificationCount: other.totalUnreadNotificationCount,
      ephemeral: ephemeral?.merge(other.ephemeral) ?? other.ephemeral,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Room && runtimeType == other.runtimeType && id.value == other.id.value;

  @override
  int get hashCode => id.value.hashCode;

  @override
  Room? delta({
    Membership? myMembership,
    RoomStateEvents? stateEvents,
    Timeline? timeline,
    RoomSummary? summary,
    Iterable<Member>? memberTimeline,
    UserId? directUserId,
    int? highlightedUnreadNotificationCount,
    int? totalUnreadNotificationCount,
    Iterable<EphemeralEvent>? ephemeral,
  }) {
    return Room(
      context: context,
      id: id,
      stateEvents: stateEvents,
      timeline: this.timeline?.delta(
            events: timeline,
            previousBatch: timeline?.previousBatch,
            previousBatchSetBySync: timeline?.previousBatchSetBySync,
          ),
      summary: summary,
      memberTimeline: this.memberTimeline?.delta(members: memberTimeline),
      directUserId: directUserId,
      highlightedUnreadNotificationCount: highlightedUnreadNotificationCount,
      totalUnreadNotificationCount: totalUnreadNotificationCount,
      ephemeral: this.ephemeral?.delta(events: ephemeral),
    );
  }

  /// Whether the user can kick a user with [kickeeId].
  ///
  /// If [kickeeId] is null, returns true if user with [kickerId]
  /// can kick someone with a default power level.
  bool canKick(
    UserId kickerId, {
    UserId? kickeeId,
  }) {
    if (me?.membership is! Joined) {
      return false;
    }

    final kickerLevel = (powerLevels?.of(kickerId)) ?? 0;
    final kickeeLevel = (kickeeId != null
            ? powerLevels?.of(kickeeId)
            : powerLevels?.defaults.users) ??
        0;

    return kickerLevel > kickeeLevel && kickerLevel >= (powerLevels?.kick ?? 0);
  }

  /// Kicks the user with [kickeeId] from this room, if you ([context.user])
  /// have the power to do so.
  ///
  /// You can check whether you have the power to do so using [canKick].
  ///
  /// Returns the update where the kick has been processed, if successful.
  ///
  /// If the user with [kickeeeId] has already been kicked, does nothing and
  /// just returns the next update.
  Future<RequestUpdate<MemberTimeline>?> kick(UserId kickeeId) {
    if (context?.updater != null) {
      return context!.updater!.kick(kickeeId, from: id);
    } else {
      return Future.value(null);
    }
  }

  /// Whether the user can ban a user with [banneeId].
  ///
  /// If [banneeId] is null, returns true if user with [bannerId]
  /// can ban someone with a default power level.
  bool canBan(
    UserId bannerId, {
    UserId? banneeId,
  }) {
    if (me?.membership is! Joined) {
      return false;
    }

    final bannerLevel = (powerLevels?.of(bannerId)) ?? 0;
    final banneeLevel = (banneeId != null
            ? powerLevels?.of(banneeId)
            : powerLevels?.defaults.users) ??
        0;

    return bannerLevel > banneeLevel && bannerLevel >= (powerLevels?.ban ?? 0);
  }

  /// Whether the user can invite a user with [inviteeId].
  ///
  /// If [inviteeId] is null, returns true if user with [inviterId]
  /// can invite someone with a default power level.
  bool canInvite(
    UserId inviterId, {
    UserId? inviteeId,
  }) {
    final inviterLevel = (powerLevels?.of(inviterId)) ?? 0;
    final inviteeLevel = (inviteeId != null
            ? powerLevels?.of(inviteeId)
            : powerLevels?.defaults.users) ??
        0;

    return inviterLevel > inviteeLevel &&
        inviterLevel >= (powerLevels?.invite ?? 0);
  }

  /// Whether the user can redact a message of a user with [eventSenderId].
  ///
  /// If [eventSenderId] is null, returns true if user with [redacterId] can
  /// redact a message of someone with a default power level.
  bool canRedact(
    UserId redacterId, {
    UserId? eventSenderId,
  }) {
    final redacterLevel = (powerLevels?.of(redacterId)) ?? 0;
    final eventSenderLevel = (eventSenderId != null
            ? powerLevels?.of(eventSenderId)
            : powerLevels?.defaults.users) ??
        0;

    return redacterLevel > eventSenderLevel &&
        redacterLevel >= (powerLevels?.redact ?? 0);
  }

  /// Whether the user can send the event of type [E].
  bool canSend<E extends RoomEvent>(UserId senderId) {
    final senderLevel = (powerLevels?.of(senderId)) ?? 0;
    final defaultLevel = (RoomEvent.isState(E)
            ? powerLevels?.defaults.stateEvents
            : powerLevels?.defaults.events) ??
        0;

    return senderLevel >= (powerLevels?.events?[E] ?? defaultLevel);
  }

  /// Whether the user with [senderId] can change the name of this room.
  bool canChangeName(UserId senderId) => canSend<RoomNameChangeEvent>(senderId);

  /// Whether the user with [senderId] can change the avatar of this room.
  bool canChangeAvatar(UserId senderId) =>
      canSend<RoomAvatarChangeEvent>(senderId);

  /// Whether the user with [senderId] can change the topic of this room.
  bool canChangeTopic(UserId senderId) => canSend<TopicChangeEvent>(senderId);

  /// Whether the user with [senderId] can change the power levels of this room.
  ///
  /// If [userId] is provided, returns whether the user with [senderId] can
  /// change the power level of [userId].
  bool canChangePowerLevels(
    UserId senderId, {
    UserId? userId,
  }) =>
      canSend<PowerLevelsChangeEvent>(senderId) && userId != null
          ? (powerLevels?.of(userId) ?? 0) < (powerLevels?.of(senderId) ?? 0)
          : true;

  /// Whether the user with [senderId] can upgrade this room.
  bool canUpgrade(UserId senderId) => canSend<RoomUpgradeEvent>(senderId);

  /// Whether the user with [senderId] can message to this room.
  bool canMessage(UserId senderId) => canSend<MessageEvent>(senderId);

  /// Whether someone (not you) is typing.
  bool get isSomeoneElseTyping =>
      typingUserIds.isNotEmpty &&
      !typingUserIds.any(
        (id) => id == context?.updater?.user.id,
      );

  /// Whether someone is typing.
  bool get isSomeoneTyping => typingUserIds.isNotEmpty;

  /// Sends a [PowerLevelsChangeEvent], changing the power level of the user
  /// with [id] to [to]. Use [canChangePowerLevel] using [userId] to check if
  /// the [MyUser] can actually change the power level of the user with [id].
  ///
  /// Returns the [Update] when the power level change is processed, if
  /// successful.
  Future<Update?> changePowerLevelOf(
    UserId id, {
    required int to,
  }) async {
    if (stateEvents?.powerLevelsChange?.content == null) {
      return Future.value(null);
    }
    final userLevels = Map<UserId, int>.from(
      stateEvents!.powerLevelsChange!.content!.userLevels ?? {},
    );
    userLevels[id] = to;
    return send(
      stateEvents!.powerLevelsChange!.content!.copyWith(
        userLevels: userLevels,
      ),
    ).last;
  }

  /// Send an [Event] to the [Room]. Can be any [RoomEvent]
  /// including [StateEvent]s.
  ///
  /// However, it's recommended to use the
  /// methods in [Room] to alter the state.
  ///
  /// Returns the update where the send state of this event is updated, this
  /// will be twice: once when the event has been put in the timeline, and once
  /// when the event has actually been sent.
  ///
  /// If you send an [ImageMessage] with a `file://` [Uri], it will
  /// automatically be uploaded.
  ///
  /// If a [RawEventContent] is being send, [type] must not be null. Unused
  /// otherwise.
  Stream<RequestUpdate<Timeline>?> send(
    EventContent content, {
    String? transactionId,
    String stateKey = '',
    String type = '',
  }) {
    if (context?.updater == null) {
      return Future.value(null).asStream();
    }
    return context!.updater!.send(id, content,
        transactionId: transactionId,
        stateKey: stateKey,
        type: type,
        room: this);
  }

  Future<RequestUpdate<Timeline>?> edit(
    TextMessageEvent event,
    String newContent, {
    String? transactionId,
  }) async {
    final result = context?.updater
        ?.edit(id, event, newContent, transactionId: transactionId, room: this);
    return result ?? Future.value();
  }

  Future<RequestUpdate<Timeline>?> delete(
    EventId eventId, {
    String? transactionId,
    String? reason,
  }) {
    final result = context?.updater?.delete(
      id,
      eventId,
      transactionId: transactionId,
      reason: reason,
      room: this,
    );
    return result ?? Future.value(null);
  }

  Future<Update?> setName(String name) => send(RoomNameChange(name: name)).last;

  Future<Update?> setAvatarUri(Uri avatarUrl) =>
      send(RoomAvatarChange(url: avatarUrl)).last;

  Future<Update?> setTopic(String topic) =>
      send(TopicChange(topic: topic)).last;

  Future<Update?> upgrade({
    required RoomId replacementRoomId,
    required String message,
  }) =>
      send(RoomUpgrade(
        replacementRoomId: replacementRoomId,
        body: message,
      )).last;

  /// Notify whether the user is typing.
  ///
  /// If [isTyping] is true, a [timeout] can be specified
  /// to notify how long the server should assume that the user is
  /// typing.
  Future<RequestUpdate<Ephemeral>?> setIsTyping(
    // ignore: avoid_positional_boolean_parameters
    bool isTyping, {
    Duration timeout = const Duration(seconds: 30),
  }) {
    if (context?.updater == null) {
      return Future.value(null);
    }
    return context!.updater!.setIsTyping(
      roomId: id,
      isTyping: isTyping,
      timeout: timeout,
    );
  }

  /// Will mark all messages as read until [until]. Will also
  /// send a read receipt, if [receipt] is true (default).
  ///
  /// If the event with [until] id is already marked as read and [receipt]
  /// is true, this will just return the next update with an
  /// the current read receipt list for `data` it's delta for `deltaData`.
  Future<RequestUpdate<ReadReceipts>?> markRead({
    required EventId until,
    bool receipt = true,
  }) {
    if (context?.updater == null) {
      return Future.value(null);
    }
    return context!.updater!.markRead(
      roomId: id,
      until: until,
      receipt: receipt,
      room: this,
    );
  }

  /// Join this room, if not joined already.
  ///
  /// Use [through] to specify the server to join through.
  Future<RequestUpdate<Room>?> join({
    Homeserver? through,
  }) {
    assert(!(me?.hasJoined ?? false));
    if (context?.updater == null) {
      return Future.value(null);
    }
    return context!.updater!.joinRoom(
      id: id,
      serverUrl: through?.wellKnownUrl ?? through?.url ?? Uri(),
    );
  }

  /// Leave this room, if not left already.
  Future<RequestUpdate<Room>?> leave() {
    assert(!(me?.hasLeft ?? false));
    final result = context?.updater?.leaveRoom(id);
    return result ?? Future.value(null);
  }

  /// Receive updates that contain a change to this room.
  Stream<Update>? get updates {
    return context?.updater?.updates
        .where((u) => u.delta.rooms?.containsWithId(id) == true);
  }

  @override
  Room? propertyOf(MyUser user) {
    if (context?.roomId != null) {
      return user.rooms?[context!.roomId];
    } else {
      return null;
    }
  }
}

/// Class that contains the most recent state events of each type.
///
/// Use the [] operator to get custom state events by type, and then by state
/// state key.
///
/// This operator only works on _custom_ types, not types that are defined in
/// the spec, so `stateEvents['m.room.upgrade`] will **not** work, use
/// `stateEvents.upgrade` or equivelant getters for those.
///
/// If there's only one type of that state event allowed, it will have an
/// empty state key, and can also be found as such:
///
/// ```dart
/// room.stateEvents['im.pattle.app.some_state'][''].content;
/// ```
/// or
///
/// ```dart
/// room.stateEvents['im.pattle.app.some_state'].single.content;
/// ```
///
/// The `single` usage asserts that there's only element, otherwise it
/// throws.
@immutable
class RoomStateEvents {
  final RoomNameChangeEvent? nameChange;
  final RoomAvatarChangeEvent? avatarChange;
  final TopicChangeEvent? topicChange;
  final PowerLevelsChangeEvent? powerLevelsChange;
  final JoinRulesChangeEvent? joinRulesChange;
  final CanonicalAliasChangeEvent? canonicalAliasChange;
  final RoomCreationEvent? creation;
  final RoomUpgradeEvent? upgrade;

  /// Custom state events by type, and then by state key.
  ///
  /// If there's only one type of that state event allowed, it will have an
  /// empty state key, and can also be found as such:
  ///
  /// ```dart
  /// room.stateEvents.custom['im.pattle.app.some_state'][''].content;
  /// ```
  /// or
  ///
  /// ```dart
  /// room.stateEvents.custom['im.pattle.app.some_state'].single.content;
  /// ```
  ///
  /// The `single` usage asserts that there's only element, otherwise it
  /// throws.
  ///
  /// Will be null if there are no custom state events.
  final Map<String, Map<String, RawStateEvent>>? custom;

  Map<String, RawStateEvent>? operator [](String type) => custom?[type];

  const RoomStateEvents({
    this.nameChange,
    this.avatarChange,
    this.topicChange,
    this.powerLevelsChange,
    this.joinRulesChange,
    this.canonicalAliasChange,
    this.creation,
    this.upgrade,
    this.custom,
  });

  factory RoomStateEvents.fromEvents(Iterable<RoomEvent>? events) {
    events ??= [];

    RoomNameChangeEvent? nameChange;
    RoomAvatarChangeEvent? avatarChange;
    TopicChangeEvent? topicChange;
    PowerLevelsChangeEvent? powerLevelsChange;
    JoinRulesChangeEvent? joinRulesChange;
    CanonicalAliasChangeEvent? canonicalAliasChange;
    RoomCreationEvent? creation;
    RoomUpgradeEvent? upgrade;

    Map<String, Map<String, RawStateEvent>>? custom = {};

    for (final event in events) {
      if (event is RoomNameChangeEvent) {
        nameChange = event;
      } else if (event is RoomAvatarChangeEvent) {
        avatarChange = event;
      } else if (event is TopicChangeEvent) {
        topicChange = event;
      } else if (event is PowerLevelsChangeEvent) {
        powerLevelsChange = event;
      } else if (event is JoinRulesChangeEvent) {
        joinRulesChange = event;
      } else if (event is CanonicalAliasChangeEvent) {
        canonicalAliasChange = event;
      } else if (event is RoomCreationEvent) {
        creation = event;
      } else if (event is RoomUpgradeEvent) {
        upgrade = event;
      } else if (event is RawStateEvent) {
        custom[event.type] ??= {};
        custom[event.type]![event.stateKey!] = event;
      }
    }

    if (custom.isEmpty) {
      custom = null;
    }

    return RoomStateEvents(
      nameChange: nameChange,
      avatarChange: avatarChange,
      topicChange: topicChange,
      powerLevelsChange: powerLevelsChange,
      joinRulesChange: joinRulesChange,
      canonicalAliasChange: canonicalAliasChange,
      creation: creation,
      upgrade: upgrade,
      custom: custom,
    );
  }

  RoomStateEvents copyWith({
    RoomNameChangeEvent? nameChange,
    RoomAvatarChangeEvent? avatarChange,
    TopicChangeEvent? topicChange,
    PowerLevelsChangeEvent? powerLevelsChange,
    JoinRulesChangeEvent? joinRulesChange,
    CanonicalAliasChangeEvent? canonicalAliasChange,
    RoomCreationEvent? creation,
    RoomUpgradeEvent? upgrade,
    Map<String, Map<String, RawStateEvent>>? custom,
  }) {
    return RoomStateEvents(
      nameChange: nameChange ?? this.nameChange,
      avatarChange: avatarChange ?? this.avatarChange,
      topicChange: topicChange ?? this.topicChange,
      powerLevelsChange: powerLevelsChange ?? this.powerLevelsChange,
      joinRulesChange: joinRulesChange ?? this.joinRulesChange,
      canonicalAliasChange: canonicalAliasChange ?? this.canonicalAliasChange,
      creation: creation ?? this.creation,
      upgrade: upgrade ?? this.upgrade,
      custom: custom ?? this.custom,
    );
  }

  RoomStateEvents merge(RoomStateEvents? other) {
    if (other == null) {
      return this;
    }

    return copyWith(
      nameChange: other.nameChange,
      avatarChange: other.avatarChange,
      topicChange: other.topicChange,
      powerLevelsChange: other.powerLevelsChange,
      joinRulesChange: other.joinRulesChange,
      canonicalAliasChange: other.canonicalAliasChange,
      creation: other.creation,
      upgrade: other.upgrade,
      custom: other.custom,
    );
  }
}

@immutable
class RoomSummary {
  final int? joinedMembersCount;
  final int? invitedMembersCount;

  const RoomSummary({
    this.joinedMembersCount,
    this.invitedMembersCount,
  });

  factory RoomSummary.fromJson(Map<String, dynamic> json) {
    return RoomSummary(
      joinedMembersCount: json['m.joined_member_count'],
      invitedMembersCount: json['m.invited_member_count'],
    );
  }

  RoomSummary copyWith({
    int? joinedMembersCount,
    int? invitedMembersCount,
  }) {
    return RoomSummary(
      joinedMembersCount: joinedMembersCount ?? this.joinedMembersCount,
      invitedMembersCount: invitedMembersCount ?? this.invitedMembersCount,
    );
  }

  RoomSummary merge(RoomSummary? other) {
    if (other == null) {
      return this;
    }

    return copyWith(
      joinedMembersCount: other.joinedMembersCount,
      invitedMembersCount: other.invitedMembersCount,
    );
  }
}

@immutable
class PowerLevels {
  int? get ban => _content?.banLevel;
  int? get invite => _content?.inviteLevel;
  int? get kick => _content?.kickLevel;
  int? get redact => _content?.redactLevel;

  int? get roomNotification => _content?.roomNotificationLevel;

  Map<Type, int>? get events => _content?.eventLevels;

  Map<UserId, int>? get users => _content?.userLevels;

  final PowerLevelDefaults defaults;

  final PowerLevelsChange? _content;

  PowerLevels._(PowerLevelsChangeEvent? event)
      : _content = event?.content,
        defaults = PowerLevelDefaults(event);

  int of(UserId userId) => users?[userId] ?? defaults.users ?? 0;
}

@immutable
class PowerLevelDefaults {
  int? get stateEvents => _content?.stateEventsDefaultLevel;
  int? get events => _content?.eventsDefaultLevel;

  int? get users => _content?.userDefaultLevel;

  final PowerLevelsChange? _content;

  PowerLevelDefaults(PowerLevelsChangeEvent? event) : _content = event?.content;
}

class ReadReceipts extends DelegatingIterable<Receipt>
    implements Contextual<ReadReceipts> {
  ReadReceipts(Iterable<Receipt> base, {this.context}) : super(base);

  @override
  final RoomContext? context;

  @override
  ReadReceipts? delta({Iterable<Receipt>? receipts}) {
    return ReadReceipts(
      receipts ?? [],
      context: context,
    );
  }

  @override
  ReadReceipts? propertyOf(MyUser user) {
    if (context?.roomId != null) {
      return user.rooms?[context!.roomId]?.readReceipts;
    } else {
      return null;
    }
  }
}

class RoomContext extends Context {
  final RoomId roomId;

  RoomContext.inherit(
    Context context, {
    required this.roomId,
  }) : super(myId: context.myId);
}

extension _MapMerge<K, V> on Map<K, V> {
  Map<K, V> merge(Map<K, V>? other) {
    if (other == null) {
      return this;
    }

    return {...this, ...other};
  }
}
