// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'dart:isolate';
import 'package:matrix_sdk/src/model/models.dart';
import 'package:meta/meta.dart';
import '../../homeserver.dart';
import '../proxy_http_overrides.dart';
import '../updater.dart';
import '../../store/store.dart';
import 'instruction.dart';

abstract class IsolateRunner {
  static Future<void> run(dynamic message) async {
    final receivePort = ReceivePort();
    final messageStream = receivePort.asBroadcastStream();
    final sendPort = message as SendPort;

    await runZonedGuarded(
      () async {
        final updaterAvailable = Completer<void>();

        Updater? updater;
        StreamSubscription? subscription;
        subscription = messageStream.listen((message) {
          if (message is UpdaterArgs) {
            //HttpOverrides.global = ProxyHttpOverrides("192.168.1.6", 8080);
            updater = Updater(
              message.myUser,
              Homeserver(message.homeserverUrl),
              message.storeLocation,
              saveMyUserToStore: message.saveMyUserToStore,
            );
            updaterAvailable.complete();
            subscription?.cancel();
          }
        });

        sendPort.send(receivePort.sendPort);

        await updaterAvailable.future;

        // Send updates back to main isolate
        updater?.updates.listen((u) => sendPort.send(u.minimize()));

        updater?.outApiCallStatistics.listen(sendPort.send);

        sendPort.send(IsolateInitialized());

        StreamSubscription instructionSubscription;

        instructionSubscription = messageStream.listen((message) async {
          final instruction = message as Instruction;

          if (instruction is StartSyncInstruction) {
            updater?.syncer.start(
              maxRetryAfter: instruction.maxRetryAfter,
              timelineLimit: instruction.timelineLimit,
            );
          }

          if (instruction is StopSyncInstruction) {
            await updater?.syncer.stop();
            sendPort.send(null);
          }

          if (instruction is RequestInstruction) {
            await _executeRequest(updater, sendPort, instruction);
          }
        });

        await instructionSubscription.asFuture();
        await instructionSubscription.cancel();
      },
      (error, stackTrace) {
        sendPort.send(
          ErrorWithStackTraceString(
            error.toString(),
            stackTrace.toString(),
          ),
        );
      },
    );
  }

  static Future<void> _executeRequest(
    Updater? updater,
    SendPort sendPort,
    RequestInstruction instruction,
  ) async {
    if (updater == null) {
      return Future.value();
    }

    Future<dynamic> Function() operation;

    if (instruction is KickInstruction) {
      operation = () => updater.kick(instruction.id, from: instruction.from!);
    } else if (instruction is LoadRoomEventsInstruction) {
      operation = () => updater.loadRoomEvents(
            roomId: instruction.roomId!,
            count: instruction.count,
            room: instruction.room,
          );
    } else if (instruction is LoadMembersInstruction) {
      operation = () => updater.loadMembers(
            roomId: instruction.roomId!,
            count: instruction.count,
            room: instruction.room,
          );
    } else if (instruction is LoadRoomsInstruction) {
      operation = () => updater.loadRooms(
            instruction.roomIds,
            instruction.timelineLimit,
          );
    } else if (instruction is LogoutInstruction) {
      operation = () => updater.logout();
    } else if (instruction is MarkReadInstruction) {
      operation = () => updater.markRead(
            roomId: instruction.roomId,
            until: instruction.until,
            receipt: instruction.receipt,
            room: instruction.room,
          );
    } else if (instruction is SendInstruction) {
      await updater
          .send(
        instruction.roomId,
        instruction.content,
        transactionId: instruction.transactionId,
        stateKey: instruction.stateKey,
        type: instruction.type,
        room: instruction.room,
      )
          .forEach((update) {
        sendPort.send(update);
      });

      return;
    } else if (instruction is SetIsTypingInstruction) {
      operation = () => updater.setIsTyping(
            roomId: instruction.roomId!,
            isTyping: instruction.isTyping,
            timeout: instruction.timeout,
          );
    } else if (instruction is JoinRoomInstruction) {
      operation = () => updater.joinRoom(
            id: instruction.id,
            alias: instruction.alias,
            serverUrl: instruction.serverUrl,
          );
    } else if (instruction is LeaveRoomInstruction) {
      operation = () => updater.leaveRoom(instruction.id);
    } else if (instruction is SetNameInstruction) {
      operation = () => updater.setDisplayName(name: instruction.name);
    } else if (instruction is SetPusherInstruction) {
      operation = () => updater.setPusher(instruction.pusher);
    } else if (instruction is EditTextEventInstruction) {
      operation = () => updater.edit(
            instruction.roomId,
            instruction.event,
            instruction.newContent,
            transactionId: instruction.transactionId,
            room: instruction.room,
          );
    } else if (instruction is DeleteEventInstruction) {
      operation = () => updater.delete(
            instruction.roomId,
            instruction.eventId,
            transactionId: instruction.transactionId,
            reason: instruction.reason,
            room: instruction.room,
          );
    } else {
      throw UnsupportedError(
        'Unsupported instruction: ${instruction.runtimeType}',
      );
    }

    final result = await operation();

    if (result != null &&
        (result is! Update ||
            (instruction is RequestInstruction && instruction.basedOnUpdate))) {
      sendPort.send(result is RequestUpdate ? result.minimize() : result);
    }
  }
}

@immutable
class UpdaterArgs {
  final MyUser myUser;
  final Uri homeserverUrl;
  final StoreLocation storeLocation;
  final bool saveMyUserToStore;

  UpdaterArgs({
    required this.myUser,
    required this.homeserverUrl,
    required this.storeLocation,
    required this.saveMyUserToStore,
  });
}

@immutable
class IsolateInitialized {}
