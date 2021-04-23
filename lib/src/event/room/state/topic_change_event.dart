// Copyright (C) 2019  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:meta/meta.dart';

import '../room_event.dart';
import 'state_event.dart';
import '../../event.dart';

class TopicChangeEvent extends StateEvent {
  static const matrixType = 'm.room.topic';

  @override
  final String type = matrixType;

  @override
  final TopicChange? content;

  @override
  final TopicChange? previousContent;

  TopicChangeEvent(
    RoomEventArgs args, {
    this.content,
    this.previousContent,
  }) : super(args, stateKey: '');
}

@immutable
class TopicChange extends EventContent {
  final String topic;

  TopicChange({
    required this.topic,
  });

  @override
  bool operator ==(dynamic other) =>
      other is TopicChange && topic == other.topic;

  @override
  int get hashCode => topic.hashCode;

  static TopicChange? fromJson(Map<String, dynamic>? content) {
    if (content == null) {
      return null;
    }

    return TopicChange(topic: content['topic']);
  }

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'topic': topic,
    });
}
