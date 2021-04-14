// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:collection';
import 'dart:convert';

import 'package:meta/meta.dart';

import '../../identifier.dart';
import '../event.dart';
import 'ephemeral_event.dart';

class ReceiptEvent extends EphemeralEvent {
  static const matrixType = 'm.receipt';

  @override
  final String type = matrixType;

  ReceiptEvent({
    required RoomId roomId,
    required this.content,
  }) : super(roomId);

  @override
  final Receipts content;

  ReceiptEvent copyWith({
    RoomId? roomId,
    Receipts? content,
  }) {
    return ReceiptEvent(
      roomId: roomId ?? this.roomId,
      content: content ?? this.content,
    );
  }

  ReceiptEvent merge(ReceiptEvent? other) {
    if (other == null) return this;

    return copyWith(
      roomId: other.roomId,
      content: content?.merge(other?.content) ?? other.content,
    );
  }
}

@immutable
class Receipts extends EventContent {
  Receipts(this.receipts);

  @override
  bool operator ==(dynamic other) =>
      other is Receipts && receipts == other.receipts;

  @override
  int get hashCode => receipts.hashCode;

  final List<Receipt> receipts;

  factory Receipts.fromJson(Map<String, dynamic> content) {
    final receipts = <Receipt>[];

    for (final rawByEventId in content.entries) {
      final eventId = EventId(rawByEventId.key);

      for (final MapEntry<String, dynamic> rawByType
          in rawByEventId.value.entries) {
        final type = ReceiptType(rawByType.key);

        for (final MapEntry<String, dynamic> rawByUserId
            in rawByType.value.entries) {
          var value = rawByUserId.value;
          if (value is String) {
            value = json.decode(rawByUserId.value);
          }
          receipts.add(
            Receipt(
              type: type,
              eventId: eventId,
              userId: UserId(rawByUserId.key),
              time: DateTime.fromMillisecondsSinceEpoch(value['ts']),
            ),
          );
        }
      }
    }

    return Receipts(receipts);
  }

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    for (final receipt in receipts) {
      final byEventId =
          json[receipt.eventId.toString()] as Map<String, dynamic> ??
              <String, dynamic>{};

      final byType = byEventId[receipt.type.toString()] ??
          (byEventId[receipt.type.toString()] = {});

      byType[receipt.userId.toString()] = {
        'ts': receipt.time.millisecondsSinceEpoch,
      };

      json[receipt.eventId.toString()] = byEventId;
    }

    return json;
  }

  Receipts copyWith({
    List<Receipt>? receipts,
  }) {
    return Receipts(
      receipts ?? this.receipts,
    );
  }

  Receipts merge(Receipts? other) {
    if (other == null) return this;

    final set = HashSet<Receipt>(
      equals: (a, b) => a.type == b.type && a.userId == b.userId,
      hashCode: (r) => r.type.hashCode + r.userId.hashCode,
    )..addAll([...other.receipts, ...receipts]);

    return copyWith(
      receipts: set.toList(),
    );
  }
}

@immutable
class Receipt {
  final ReceiptType type;

  final UserId userId;
  final EventId eventId;
  final DateTime time;

  Receipt({
    required this.type,
    required this.userId,
    required this.eventId,
    required this.time,
  });

  @override
  bool operator ==(dynamic other) {
    if (other is Receipt) {
      return type == other.type &&
          userId == other.userId &&
          eventId == other.eventId &&
          time == other.time;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => userId.hashCode + eventId.hashCode + time.hashCode;
}

@immutable
class ReceiptType {
  final String value;

  const ReceiptType(this.value);

  static const read = ReceiptType('m.read');

  @override
  bool operator ==(dynamic other) =>
      other is ReceiptType ? value == other.value : false;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

extension ReceiptsExtension on List<Receipt> {
  List<Receipt> whereReceiptType(ReceiptType receiptType) =>
      where((receipt) => receipt.type == receiptType).toList();
}
