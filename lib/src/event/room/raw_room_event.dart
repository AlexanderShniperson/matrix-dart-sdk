// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:meta/meta.dart';

import '../event.dart';
import 'room_event.dart';
import 'state/state_event.dart';

@immutable
class RawRoomEvent extends RoomEvent {
  RawRoomEvent(
    RoomEventArgs args, {
    required this.type,
    required this.content,
  }) : super(args);

  @override
  final RawEventContent content;

  @override
  final String type;

  factory RawRoomEvent.fromJson(
    RoomEventArgs args,
    Map<String, dynamic> json,
  ) =>
      RawRoomEvent(
        args,
        type: json['type'],
        content: RawEventContent.fromJson(
          json['content'],
        ),
      );
}

/// You can use `content['some_key']` to get any value.
class RawEventContent extends EventContent {
  final Map<String, dynamic> _content;

  RawEventContent(this._content);

  factory RawEventContent.fromJson(Map<String, dynamic> json) =>
      RawEventContent(json);

  @override
  Map<String, dynamic> toJson() => _content == null ? null : Map.of(_content);

  dynamic operator [](String key) => _content[key];

  bool containsKey(String key) => _content.containsKey(key);

  bool containsValue(dynamic value) => _content.containsValue(value);

  Iterable<MapEntry<String, dynamic>> get entries => _content.entries;

  void forEach(void Function(String key, dynamic value) f) =>
      _content.forEach(f);

  bool get isEmpty => _content.isEmpty;

  /// Whether this content has any non-typed properties.
  bool get isNotEmpty => _content.isNotEmpty;

  Iterable<String> get keys => _content.keys;

  Iterable<dynamic> get values => _content.values;

  int get length => _content.length;

  Map<K, V> map<K, V>(
    MapEntry<K, V> Function(String key, dynamic value) transform,
  ) =>
      _content.map(transform);

  @override
  String toString() => _content.toString();

  @override
  bool operator ==(dynamic other) =>
      other is RawEventContent &&
      _content == other._content; // TODO: Use built_collections

  @override
  int get hashCode => _content.hashCode;
}

class RawStateEvent extends RawRoomEvent implements StateEvent {
  @override
  final RawEventContent previousContent;

  @override
  final String stateKey;

  RawStateEvent(
    RoomEventArgs args, {
    required String type,
    required RawEventContent content,
    this.previousContent,
    this.stateKey,
  }) : super(args, type: type, content: content);

  factory RawStateEvent.fromJson(
    RoomEventArgs args,
    Map<String, dynamic> json,
  ) =>
      RawStateEvent(
        args,
        type: json['type'],
        content: RawEventContent.fromJson(
          json['content'],
        ),
        previousContent: json['prev_content'] != null
            ? RawEventContent.fromJson(json['prev_content'])
            : null,
        stateKey: json['state_key'],
      );
}
