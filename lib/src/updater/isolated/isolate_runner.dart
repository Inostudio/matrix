// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'dart:isolate';

import 'package:matrix_sdk/src/model/models.dart';
import 'package:matrix_sdk/src/updater/isolated/utils.dart';
import 'package:matrix_sdk/src/util/logger.dart';
import 'package:meta/meta.dart';

import '../../homeserver.dart';
import '../../store/store.dart';
import '../updater.dart';
import 'instruction.dart';

abstract class IsolateRunner {
  static Future<void> run(IsolateTransferModel transferModel) async {
    final message = transferModel.message;
    Log.setLogger(transferModel.loggerVariant);
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
            updater = Updater(
              message.myUser,
              Homeserver(message.homeserverUrl),
              message.storeLocation,
              initSyncStorage: false, //Not create updater updater sync
            );
            updaterAvailable.complete();
            subscription?.cancel();
          }
        });

        sendPort.send(
          makeResponseData(null, receivePort.sendPort),
        );

        await updaterAvailable.future;
        await updater?.ensureReady();

        updater?.outApiCallStatistics.listen(
          (e) => sendPort.send(makeResponseData(null, e)),
        );

        sendPort.send(
          makeResponseData(null, RunnerInitialized()),
        );

        StreamSubscription instructionSubscription;

        instructionSubscription = messageStream.listen((message) async {
          final instruction = message as Instruction;

          if (instruction is StopSyncInstruction) {
            await updater?.syncer.stop();
            sendPort.send(
              makeResponseData(instruction, null),
            );
          }

          if (instruction is GetRoomIDsInstruction) {
            final result = await updater?.getRoomIDs();
            sendPort.send(
              makeResponseData(instruction, result),
            );
          }

          if (instruction is SaveRoomToDBInstruction) {
            await updater?.saveRoomToDB(instruction.room);
            sendPort.send(
              makeResponseData(instruction, null),
            );
          }
          if (instruction is GetRoomInstruction) {
            final result = await updater?.fetchRoomFromDB(
              instruction.roomId,
              context: instruction.context,
              memberIds: instruction.memberIds,
            );
            sendPort.send(
              makeResponseData(instruction, result),
            );
          }

          if (instruction is RequestInstruction) {
            await _executeRequest(updater, sendPort, instruction);
          } else if (instruction is SendInstruction) {
            await updater
                ?.send(
                  instruction.roomId,
                  instruction.content,
                  transactionId: instruction.transactionId,
                  stateKey: instruction.stateKey,
                  type: instruction.type,
                  room: instruction.room,
                )
                .forEach(
                  (update) => sendPort.send(
                    makeResponseData(instruction, update),
                  ),
                );

            return;
          } else if (instruction is SendReadyInstruction) {
            final data = await updater?.sendReadyEvent(
              instruction.roomEvent,
              isState: instruction.isState,
            );
            sendPort.send(makeResponseData(instruction, data));
            return;
          }
        });

        await instructionSubscription.asFuture();
        await instructionSubscription.cancel();
      },
      (error, stackTrace) {
        sendPort.send(
          makeResponseData(
            null,
            ErrorWithStackTraceString(
              error.toString(),
              stackTrace.toString(),
            ),
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
    } else if (instruction is LoadRoomsByIDsInstruction) {
      operation = () => updater.loadRoomsByIDs(
            instruction.roomIds,
            instruction.timelineLimit,
          );
    } else if (instruction is LoadRoomsInstruction) {
      operation = () => updater.loadRooms(
            instruction.limit,
            instruction.offset,
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
            fullyRead: instruction.fullyRead,
          );
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

    if (instruction is RunSyncOnceInstruction) {
      sendPort.send(makeResponseData(instruction, result));
      return;
    }

    if (result != null && (result is! Update || instruction.basedOnUpdate)) {
      sendPort.send(
        makeResponseData(
          instruction,
          result is RequestUpdate ? result.minimize() : result,
        ),
      );
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
class RunnerInitialized {}
