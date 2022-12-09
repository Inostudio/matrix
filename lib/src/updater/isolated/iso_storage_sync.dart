import 'dart:async';
import 'dart:isolate';

import 'package:matrix_sdk/src/updater/isolated/instruction.dart';
import 'package:meta/meta.dart';

import '../../../matrix_sdk.dart';
import '../../model/instruction.dart';
import '../../util/logger.dart';
import '../../util/subscription.dart';
import 'isolate_runner.dart';
import 'utils.dart';

abstract class IsolateStorageSyncRunner {
  static Map<String, StreamSubscription<Room>> roomIdToSyncSubscription = {};

  static Future<void> run(IsolateTransferModel transferModel) async {
    final message = transferModel.message;
    Log.setLogger(transferModel.loggerVariant);
    final receivePort = ReceivePort();
    final messageStream = receivePort.asBroadcastStream();
    final sendPort = message as SendPort;

    await runZonedGuarded(
      () async {
        final updaterAvailable = Completer<void>();

        late Updater updater;
        StreamSubscription? subscription;
        subscription = messageStream.listen((message) {
          if (message is UpdaterArgs) {
            updater = Updater(
              message.myUser,
              Homeserver(message.homeserverUrl),
              message.storeLocation,
              initSyncStorage: true, //Create sync with store
            );
            updaterAvailable.complete();
            subscription?.cancel();
          }
        });

        sendPort.send(makeResponseData(null, receivePort.sendPort));
        await updaterAvailable.future;
        await updater.ensureReady();
        updater.updates.listen(
          (u) => sendPort.send(makeResponseData(null, u.minimize())),
        );
        updater.outApiCallStatistics.listen(
          (e) => sendPort.send(makeResponseData(null, e)),
        );
        sendPort.send(
          makeResponseData(null, SyncerInitialized()),
        );

        StreamSubscription? instructionSubscription;
        instructionSubscription = messageStream.listen((message) async {
          final instruction = message as Instruction;
          if (instruction is StartSyncInstruction) {
            await updater.startSync(
              maxRetryAfter: instruction.maxRetryAfter,
              timelineLimit: instruction.timelineLimit,
              syncToken: instruction.syncToken,
            );
          }
          if (instruction is StopSyncInstruction) {
            await instructionSubscription?.cancel();
            await updater.stopSync();
          } else if (instruction is RunSyncOnceInstruction) {
            final syncResult = await updater.runSyncOnce(instruction.filter);
            sendPort.send(
              makeResponseData(instruction, syncResult),
            );
          } else if (instruction is LogoutInstruction) {
            await instructionSubscription?.cancel();
            await updater.logout();
          } else if (instruction is OneRoomSyncInstruction) {
            roomIdToSyncSubscription[instruction.roomId] =
                updater.startRoomSync(instruction.roomId).listen(
                      (e) => sendPort.send(
                        makeResponseData(instruction, e),
                      ),
                    );
          } else if (instruction is CloseRoomSync) {
            final resLocal = await closeOneSubInMap(
              roomIdToSyncSubscription,
              instruction.roomId,
            );
            roomIdToSyncSubscription.remove(instruction.roomId);
            final resUpd = await updater.closeRoomSync(instruction.roomId);
            sendPort.send(
              makeResponseData(instruction, resUpd && resLocal),
            );
          } else if (instruction is CloseAllRoomsSync) {
            final resLocal = await closeAllSubInMap(roomIdToSyncSubscription);
            final resUpd = await updater.closeAllRoomSync();
            roomIdToSyncSubscription.clear();
            sendPort.send(
              makeResponseData(instruction, resUpd && resLocal),
            );
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
}

@immutable
class SyncerInitialized {}
