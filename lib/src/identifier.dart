// Copyright (C) 2019  Wilko Manger
// Copyright (C) 2019  Mathieu Velten
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:meta/meta.dart';

@immutable
abstract class Id {
  final String value;

  Id(this.value);

  @override
  String toString() => value;

  String toJson() => toString();
}

/// A Matrix identifier. These values are _not_ checked, treat all of them as
/// opaque identifiers.
@immutable
abstract class MatrixId extends Id {
  MatrixId._(this.sigil, String value) : super(value);

  final String sigil;
  static final String seperator = ':';

  @override
  String toString() => value;

  List<String> get _split => value.split(seperator);

  /// Local part of the id (without [sigil]), is null if the id is
  /// not valid.
  String get localPart => _split.length == 2 ? _split[0]?.substring(1) : null;

  /// Server part of the id, is null if the id is
  /// not valid, or an event id.
  String get server => _split.length == 2 ? _split[1] : null;

  @override
  bool operator ==(Object other) {
    if (other is Id) {
      return value == other.value;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => value.hashCode;

  // Verification
  static final _localPartRegex = RegExp('^[A-z0-9\\-.=_\\/]+\$');

  static final _historicalLocalPartRegex = RegExp('^((?![:])[\x21-\x7F])*\$');

  /// Checks if it's a historically valid local part.
  ///
  /// Some old localparts have characters that are now not allowed because
  /// in the past the spec was more tolerant.
  static bool isValidHistoricalLocalPart(String input) =>
      _historicalLocalPartRegex.hasMatch(input);

  /// Check whether the given string is a valid
  /// local part of a user identifier.
  static bool isValidLocalPart(String input) => _localPartRegex.hasMatch(input);

  static bool _isValidFullyQualified(String input, String sigil) {
    if (input == null) {
      return false;
    }

    if (input.length > 255) {
      return false;
    }

    if (input.startsWith(sigil) && input.contains(seperator)) {
      String local, server;

      var seperatorIndex = input.indexOf(seperator);
      server = input.substring(seperatorIndex + 1);
      local = input.split(seperator)[0].substring(1);

      if (!isValidLocalPart(local) && !isValidHistoricalLocalPart(local)) {
        return false;
      }

      if (Uri.tryParse('https://$server') == null) {
        return false;
      }

      return true;
    } else {
      return false;
    }
  }

  static ValidId _isValid(String input, String sigil) {
    if (isValidLocalPart(input)) {
      return ValidId.local;
    }

    if (_isValidFullyQualified(input, sigil)) {
      return ValidId.full;
    }

    return ValidId.no;
  }
}

enum ValidId { no, local, full }

const _roomSigil = '!';

/// An internal room ID in the form `!something:server.tld`.
@immutable
class RoomId extends MatrixId {
  RoomId(String value) : super._(_roomSigil, value);

  /// Checks whether the given string is a valid
  /// local part of a room id.
  ///
  /// Must match the regex `[a-z0-9\\-.=_\\/]+`
  static bool isValidLocalPart(String input) =>
      MatrixId.isValidLocalPart(input);

  /// Checks whether the given string is a valid
  /// fully qualified user id, must be in the form of:
  /// `!localpart:server.tld`.
  static bool isValidFullyQualified(String input) =>
      MatrixId._isValidFullyQualified(input, _roomSigil);

  /// Checks whether the given string is either a valid localpart (returns
  /// [ValidId.local]), a valid fully qualified room id (returns
  /// [ValidId.full]) or that it's not a valid id (returns [ValidId.no]).
  static ValidId isValid(String input) => MatrixId._isValid(input, _roomSigil);

  @override
  String toJson() => toString();
}

const _roomAliasSigil = '#';

class RoomAlias extends MatrixId {
  RoomAlias(String value) : super._(_roomAliasSigil, value);

  /// Checks whether the given string is a valid
  /// local part of a room id.
  ///
  /// Must match the regex `[a-z0-9\\-.=_\\/]+`
  static bool isValidLocalPart(String input) =>
      MatrixId.isValidLocalPart(input);

  /// Checks whether the given string is a valid
  /// fully qualified user id, must be in the form of:
  /// `!localpart:server.tld`.
  static bool isValidFullyQualified(String input) =>
      MatrixId._isValidFullyQualified(input, _roomAliasSigil);

  /// Checks whether the given string is either a valid localpart (returns
  /// [ValidId.local]), a valid fully qualified room id (returns
  /// [ValidId.full]) or that it's not a valid id (returns [ValidId.no]).
  static ValidId isValid(String input) =>
      MatrixId._isValid(input, _roomAliasSigil);
}

const _eventSigil = '\$';

@immutable
class EventId extends MatrixId {
  EventId(String value) : super._(_eventSigil, value);

  @override
  String toJson() => toString();
}

const _userSigil = '@';

/// A Matrix ID in the form `@username:server.tld`.
@immutable
class UserId extends MatrixId implements UserIdentifier {
  UserId(String value) : super._(_userSigil, value);

  /// The [Username] of this ID, so in the case of `@joe:matrix.org`:
  /// `Username('joe')`.
  Username get username => Username(localPart);

  /// Checks whether the given string is a valid
  /// local part of a user identifier.
  ///
  /// Must match the regex `[a-z0-9\\-.=_\\/]+`
  static bool isValidLocalPart(String input) =>
      MatrixId.isValidLocalPart(input);

  /// Checks whether the given string is a valid
  /// fully qualified user id, must be in the form of:
  /// `@localpart:server.tld`.
  static bool isValidFullyQualified(String input) =>
      MatrixId._isValidFullyQualified(input, _userSigil);

  /// Checks whether the given string is either a valid localpart (returns
  /// [ValidId.local]), a valid fully qualified user id (returns
  /// [ValidId.full]) or that it's not a valid id (returns [ValidId.no]).
  static ValidId isValid(String input) => MatrixId._isValid(input, _userSigil);

  @override
  String toJson() => toString();

  /// Return this object represented as a user identifier, in the form
  /// of
  /// ```
  /// {
  ///   'type': 'm.id.user',
  ///   'user': '@joe:matrix.org'
  /// };
  /// ```
  @override
  Map<String, dynamic> toIdentifierJson() => {
        'type': 'm.id.user',
        'user': '$value',
      };
}

/// Localpart of a [UserId].
@immutable
class Username implements UserIdentifier {
  final String value;

  Username(this.value) {
    if (!MatrixId.isValidLocalPart(value)) {
      // throw
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is Username) {
      return value == other.value;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => value.hashCode;

  /// Checks whether the given string is a valid
  /// username.
  ///
  /// Must match the regex `[a-z0-9\\-.=_\\/]+`
  static bool isValid(String input) => MatrixId.isValidLocalPart(input);

  /// Return this object represented as a user identifier, in the form
  /// of
  /// ```
  /// {
  ///   'type': 'm.id.user',
  ///   'user': 'joe'
  /// };
  /// ```
  @override
  Map<String, dynamic> toIdentifierJson() {
    return {
      'type': 'm.id.user',
      'user': '$value',
    };
  }

  dynamic toJson() => value;

  @override
  String toString() => value;
}

/// Not to be confused with [UserId], the [UserIdentifier]
/// marks that the object can be used as a means to identify
/// a [User].
///
/// This could not only be a Matrix ID, but also a phone
/// number for example.
// ignore: one_member_abstracts
abstract class UserIdentifier {
  Map<String, dynamic> toIdentifierJson();
}

/// An object that can be identified with the [I] type of
/// identifier.
mixin Identifiable<I extends Id> {
  I get id;

  /// Returns true if [id] and [other.id] are equal. In other words,
  /// whether this object represents the same as [other], even if their current
  /// state is different.
  bool equals(Identifiable other) => id == other?.id;
}
