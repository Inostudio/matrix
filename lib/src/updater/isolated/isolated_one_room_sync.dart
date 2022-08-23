import 'dart:async';
import 'dart:isolate';

import 'package:matrix_sdk/src/updater/isolated/instruction.dart';
import 'package:meta/meta.dart';

import '../../../matrix_sdk.dart';
import '../../model/instruction.dart';
import '../../util/logger.dart';
import 'isolate_runner.dart';
import 'utils.dart';

abstract class IsolateOneRoomSyncRunner {
  static StreamSubscription<Room>? roomSyncSubscription;

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
              initSyncStorage: false, //Create sync with store
            );
            updaterAvailable.complete();
            subscription?.cancel();
          }
        });

        sendPort.send(receivePort.sendPort);

        await updaterAvailable.future;
        await updater?.ensureReady();

        updater?.updates.listen((u) => sendPort.send(u.minimize()));

        updater?.outApiCallStatistics.listen(sendPort.send);

        sendPort.send(OneRoomSyncerInitialized());

        StreamSubscription instructionSubscription;

        instructionSubscription = messageStream.listen((message) async {
          final instruction = message as Instruction;
          if (instruction is OneRoomSyncInstruction) {
            roomSyncSubscription = updater
                ?.startRoomSync(instruction.roomId)
                .listen(sendPort.send);
          } else if (instruction is CloseRoomSync) {
            await roomSyncSubscription?.cancel();
            await updater?.closeRoomSync();
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

@immutable
class OneRoomSyncerInitialized {}