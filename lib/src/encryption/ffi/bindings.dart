// Copyright (C) 2019  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:ffi';
import 'dart:io';

/// Path to the olm dynamic library.
///
/// Note that [path] must end with a slash.
DynamicLibrary open({final String path = ''}) {
  const name = 'olm';
  final buffer = StringBuffer(path);
  if (Platform.isLinux || Platform.isAndroid) {
    buffer.write('lib$name.so');
  }
  if (Platform.isMacOS) {
    buffer.write('lib$name.dylib');
  }
  if (Platform.isWindows) {
    buffer.write('$name.dll');
  }

  // If path is still empty, we're not on a supported platform
  if (buffer.isEmpty) {
    throw UnimplementedError('OlmFFI is not implemented on this platform');
  }

  return DynamicLibrary.open(buffer.toString());
}

/// A constructor function type.
typedef Constructor = Pointer<Uint8> Function(Pointer<Uint8>);

/// A size of function type.
typedef Size = int Function();
typedef SizeNative = Uint16 Function();

typedef Creator = int Function(Pointer<Uint8>, Pointer<Uint8>, int);
typedef CreatorNative = Uint16 Function(Pointer<Uint8>, Pointer<Uint8>, Uint16);

/// Size for a specific property of a struct function type.
typedef SizeFor = int Function(Pointer<Uint8>);
typedef SizeForNative = Uint16 Function(Pointer<Uint8>);

/// Get data from a property and fill in to the second pointer function type.
typedef FillFromProperty = int Function(Pointer<Uint8>, Pointer<Uint8>, int);
typedef FillFromPropertyNative = Uint16 Function(
  Pointer<Uint8>,
  Pointer<Uint8>,
  Uint16,
);

typedef Error = int Function();
typedef ErrorNative = Uint16 Function();

/// Direct bindings to the C API of `libolm`.
///
/// All functions are the exact name as in `libolm`, except that they're
/// camelCased and not prefixed with `olm`, e.g: [account] corresponds to
/// `olm_account`.
class OlmBindings {
  final DynamicLibrary lib;

  late Error error;

  late Constructor account;
  late Size accountSize;
  late Creator createAccount;
  late SizeFor createAccountRandomLength;
  late SizeFor accountIdentityKeysLength;
  late FillFromProperty accountIdentityKeys;

  OlmBindings({String path = ''}) : lib = open(path: path) {
    error = lib.lookupFunction<ErrorNative, Error>('olm_error');

    account = lib.lookupFunction<Constructor, Constructor>('olm_account');
    accountSize = lib.lookupFunction<SizeNative, Size>('olm_account_size');
    createAccount = lib.lookupFunction<CreatorNative, Creator>(
      'olm_create_account',
    );
    createAccountRandomLength = lib.lookupFunction<SizeForNative, SizeFor>(
      'olm_create_account_random_length',
    );
    accountIdentityKeysLength = lib.lookupFunction<SizeForNative, SizeFor>(
      'olm_account_identity_keys_length',
    );
    accountIdentityKeys =
        lib.lookupFunction<FillFromPropertyNative, FillFromProperty>(
      'olm_account_identity_keys',
    );
  }
}

// Error codes, taken directly from source.
const int success = 0;
const int notEnoughRandom = 1;
const int outputBufferTooSmall = 2;
const int badMessageVersion = 3;
const int badMessageFormat = 4;
const int badMessageMac = 5;
const int badMessageKeyId = 6;
const int invalidBase64 = 7;
const int badAccountKey = 8;
const int unknownPickleVersion = 9;
const int corruptedPickle = 10;
const int badSessionKey = 11;
const int unknownMessageIndex = 12;
const int badLegacyAccountPickle = 13;
const int badSignature = 14;
const int inputBufferTooSmall = 15;
