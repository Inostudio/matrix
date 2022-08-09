import 'dart:async';
import 'dart:isolate';

import 'package:matrix_sdk/src/updater/isolated/instruction.dart';

import '../../../matrix_sdk.dart';
import '../../model/instruction.dart';
import '../../util/logger.dart';
import 'isolate_runner.dart';

abstract class IsolateStorageSinkRunner {
  static StreamSubscription<Room>? roomSinkSubscription;

  static Future<void> run(IsolateRunnerTransferModel transferModel) async {
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
              initSinkStorage: true, //Create sink with store
            );
            updaterAvailable.complete();
            subscription?.cancel();
          }
        });

        sendPort.send(receivePort.sendPort);

        await updaterAvailable.future;
        await updater?.ensureReady();

        await updater?.startSync();

        updater?.updates.listen((u) => sendPort.send(u.minimize()));

        updater?.outApiCallStatistics.listen(sendPort.send);

        sendPort.send(SyncerInitialized());

        StreamSubscription instructionSubscription;

        instructionSubscription = messageStream.listen((message) async {
          final instruction = message as Instruction;

          if (instruction is StartSyncInstruction) {
            await updater?.startSync(
              maxRetryAfter: instruction.maxRetryAfter,
              timelineLimit: instruction.timelineLimit,
              syncToken: instruction.syncToken,
            );
          }
          if (instruction is StopSyncInstruction) {
            await updater?.stopSync();
          } else if (instruction is RunSyncOnceInstruction) {
            await updater?.runSyncOnce(instruction.filter);
          } else if (instruction is LogoutInstruction) {
            await updater?.logout();
          } else if (instruction is OneRoomSinkInstruction) {
            roomSinkSubscription = updater
                ?.startRoomSink(instruction.roomId)
                .listen(sendPort.send);
          } else if (instruction is CloseRoomSink) {
            await roomSinkSubscription?.cancel();
            await updater?.closeRoomSink();
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
}
