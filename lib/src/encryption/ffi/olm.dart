// Copyright (C) 2019  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../account.dart';
import 'bindings.dart' hide Error;

import '../olm.dart';

/// Implementation of `libolm` via FFI. C code is called directly.
class OlmFFI implements Olm {
  final OlmBindings olm;

  /// Will look for a appropriate file (e.g. `libolm.so` on Linux,
  /// but `olm.dll` on Windows) in [libraryPath].
  OlmFFI({String libraryPath = ''}) : olm = OlmBindings(path: libraryPath);

  void _throwIfError(int result) {
    if (result != olm.error()) {
      return;
    }

    // TODO: Throw from error, must be per resource type
  }

  String _pointerToString(Pointer<Uint8> pointer, int length) {
    final str = StringBuffer();
    for (var i = 0; i < length; i++) {
      str.write(String.fromCharCode(pointer.elementAt(i).value));
    }
    return str.toString();
  }

  @override
  Account account() {
    // Reuse result from calls which can return error codes.
    int result;
    // Create pointer.
    final accountSize = olm.accountSize();
    final memory = malloc.allocate<Uint8>(accountSize);
    final accountPointer = olm.account(memory);

    // Initialize random memory.
    final randomMemorySize = olm.createAccountRandomLength(accountPointer);
    final randomMemory = malloc.allocate<Uint8>(randomMemorySize);

    // Create account.
    // TODO: Check result for errors
    result = olm.createAccount(accountPointer, randomMemory, randomMemorySize);
    _throwIfError(result);

    // Create identity keys pointer.
    final identityKeysSize = olm.accountIdentityKeysLength(accountPointer);
    final identityKeysPointer = calloc.allocate<Uint8>(identityKeysSize);

    result = olm.accountIdentityKeys(
      accountPointer,
      identityKeysPointer,
      identityKeysSize,
    );
    _throwIfError(result);

    final keys = IdentityKeys.fromJson(json.decode(_pointerToString(
      identityKeysPointer,
      identityKeysSize,
    )));

    return Account(keys);
  }
}

// Errors and exceptions.
// Which classes are errors and which are exceptions may change while pre-1.0.
class NotEnoughRandomError extends Error {}

class OutputBufferTooSmallError extends Error {}

class BadMessageVersionException implements Exception {}

class BadMessageFormatException implements Exception {}

class BadMessageMacException implements Exception {}

class BadMessageKeyIdException implements Exception {}

class InvalidBase64Error extends Error {}

class BadAccountKeyException implements Exception {}

class CorruptedPickleException implements Exception {}

class BadSessionKeyError extends Error {}

class BadLegacyAccountPickleException implements Exception {}

class BadSignatureException implements Exception {}

class InputBufferTooSmallError extends Error {}
