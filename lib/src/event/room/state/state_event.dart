// Copyright (C) 2019  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:meta/meta.dart';
import 'package:quiver/core.dart';

import '../../event.dart';
import '../room_event.dart';

abstract class StateEvent extends RoomEvent {
  EventContent get previousContent;

  final String stateKey;

  StateEvent(RoomEventArgs args, {this.stateKey = ''}) : super(args);

  @override
  bool operator ==(dynamic other) =>
      other is StateEvent &&
      super == other &&
      stateKey == other.stateKey &&
      previousContent == other.previousContent;

  @override
  int get hashCode => hashObjects([super.hashCode, stateKey, previousContent]);

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..['state_key'] = stateKey
    ..['unsigned'] = {
      'prev_content': previousContent?.toJson(),
    };
}

/// Marker interface for all diffs for a [StateEvent]s
/// [StateEvent.previousContent] and [Event.content].
///
/// A [Diff] should implement the [EventContent] of the respective
/// [StateEvent], and the properties should be `null` if there is no change,
/// or the [Event.content]'s value if there was a change.
///
/// If a property is a [Map], it will contain the keys of the previous and
/// current content combined, with values which are null if they're unchanged,
/// and the current values if they've changed.
abstract class Diff {
  @protected
  List get props;

  /// Returns all properties of this diff that are not [Unchanged]
  /// or contain [Unchanged].
  ///
  /// Items can be a [Change], `Map<dynamic, Change>` or `List<Change>`.
  List get changes => props
      .where((p) =>
          p is! Unchanged &&
          (p is Map<dynamic, Change>
              ? p.hasChanges
              : p is List<Change> ? p.hasChanges : true))
      .toList(growable: false);
}

abstract class HasDiff {
  Diff get diff;
}

@immutable
abstract class Change<T> {
  T get value;

  Change._();

  factory Change._inIterable(T previous, T current) {
    if (previous == current) {
      return Unchanged(current);
    } else if (previous == null && current != null) {
      return Added(current);
    } else if (previous != null && current == null) {
      return Removed(previous);
    } else {
      return Edited(previous, current);
    }
  }

  factory Change(T previous, T current) =>
      previous != current ? Edited(previous, current) : Unchanged(current);

  static Map<K, Change<V>> map<K, V>(Map<K, V> previous, Map<K, V> current) =>
      previous == null || previous.isEmpty
          ? current.map((key, value) => MapEntry(key, Added(value)))
          : Map.fromEntries(
              previous.keys.followedBy(current.keys).toSet().map(
                    (key) => MapEntry(
                      key,
                      Change._inIterable(previous[key], current[key]),
                    ),
                  ),
            );

  static List<Change<T>> list<T>(List<T> previous, List<T> current) {
    if (previous == null || previous.isEmpty) {
      return current.map((e) => Added(e)).toList(growable: false);
    }

    final removals =
        previous.where((e) => !current.contains(e)).map((e) => Removed(e));

    final additions =
        current.where((e) => !previous.contains(e)).map((e) => Added(e));

    final unchanged =
        previous.where((e) => current.contains(e)).map((e) => Unchanged(e));

    return [...unchanged, ...additions, ...removals];
  }

  @override
  String toString() => '$runtimeType($value)';

  @override
  bool operator ==(dynamic other) {
    if (other is Change) {
      return runtimeType == other.runtimeType && value == other.value;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => runtimeType.hashCode + value.hashCode;
}

class Unchanged<T> extends Change<T> {
  @override
  final T value;

  Unchanged(this.value) : super._();
}

class Added<T> extends Change<T> {
  @override
  final T value;

  Added(this.value) : super._();
}

class Removed<T> extends Change<T> {
  @override
  final T value;

  Removed(this.value) : super._();
}

class Edited<T> extends Change<T> {
  final T previousValue;

  @override
  final T value;

  Edited(this.previousValue, this.value) : super._();

  @override
  String toString() => '$runtimeType($previousValue -> $value)';

  @override
  bool operator ==(dynamic other) {
    if (other is Edited) {
      return value == other.value && previousValue == other.previousValue;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => runtimeType.hashCode + value.hashCode;
}

extension ChangeMapExtension<K, V> on Map<K, Change<V>> {
  bool get hasChanges => entries.any((e) => e.value is! Unchanged);

  Map<K, Change<V>> get changes =>
      Map.fromEntries(entries.where((e) => e.value is! Unchanged));
}

extension ChangeListExtension<K, V> on List<Change<V>> {
  bool get hasChanges => any((c) => c is! Unchanged);

  List<Change<V>> get changes => where((c) => c is! Unchanged);
}

/// @internal
bool hasStateKey(dynamic json) => json.containsKey('state_key');
