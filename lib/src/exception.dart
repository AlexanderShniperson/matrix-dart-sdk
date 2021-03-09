// Copyright (C) 2019  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';

/// Any possible error response that could be returned from
/// the API.
abstract class MatrixException implements Exception {
  /// Message that is sometimes included in the response.
  /// It's not recommended that you use this message to display to end
  /// users.
  String get message;

  /// The original json body.
  Map<String, dynamic> get body;

  MatrixException();

  factory MatrixException.fromJson(Map<String, dynamic> json) {
    final code = json['errcode'];
    final message = json['error'];

    switch (code) {
      case 'M_FORBIDDEN':
        return ForbiddenException(message: message, body: json);
      case 'M_USER_IN_USE':
        return UsernameInUseException(message: message, body: json);
      case 'M_INVALID_USERNAME':
        return InvalidUsernameException(message: message, body: json);
      case 'M_EXCLUSIVE':
        return ExclusiveException(message: message, body: json);
      case 'M_UNKNOWN':
      default:
        return UnknownException(message: message, body: json);
    }
  }

  @override
  String toString() => '$runtimeType: ${json.encode(body)}';
}

/// Unknown error occured. Check the [message] for details.
class UnknownException extends MatrixException {
  UnknownException({this.message, this.body});

  @override
  final String message;

  @override
  final Map<String, dynamic> body;
}

/// Denied access. For example, wrong password, or not allowed
/// to join a room.
class ForbiddenException extends MatrixException {
  ForbiddenException({this.message, this.body});

  @override
  final String message;

  @override
  final Map<String, dynamic> body;
}

/// Username is already in use.
class UsernameInUseException extends MatrixException {
  UsernameInUseException({this.message, this.body});

  @override
  final String message;

  @override
  final Map<String, dynamic> body;
}

/// Invalid username.
class InvalidUsernameException extends MatrixException {
  InvalidUsernameException({this.message, this.body});

  @override
  final String message;

  @override
  final Map<String, dynamic> body;
}

/// The requested resource is reserved by an application service.
class ExclusiveException extends MatrixException {
  ExclusiveException({this.message, this.body});

  @override
  final String message;

  @override
  final Map<String, dynamic> body;
}
