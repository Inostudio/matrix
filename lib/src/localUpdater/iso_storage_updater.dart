import 'dart:async';
import 'dart:isolate';

import 'package:matrix_sdk/src/localUpdater/sync_response.dart';

import '../../../matrix_sdk.dart';
import '../updater/isolated/utils.dart';
import '../util/logger.dart';
import 'instruction.dart';
import 'local_updater.dart';

abstract class IsolateStorageUpdater {
  static Future<void> run(IsolateTransferModel transferModel) async {
    final message = transferModel.message;
    Log.setLogger(transferModel.loggerVariant);
    final receivePort = ReceivePort();
    final messageStream = receivePort.asBroadcastStream();
    final sendPort = message as SendPort;

    await runZonedGuarded(
      () async {
        LocalUpdater? updater;
        StreamSubscription? subscription;
        StreamSubscription? updateSubscription;
        StreamSubscription<Room>? roomSyncSubscription;

        sendPort.send(receivePort.sendPort);

        subscription = messageStream.listen((message) async {
          //first sync, after [receivePort.sendPort] send
          if (message is IsoStorageUpdaterArgs) {
            updater = LocalUpdater(
              storeLocation: message.storeLocation,
              isIsolated: false,
            );
            await updater?.init();
            await updater?.ensureReady();
            updateSubscription = updater?.userUpdates.listen(sendPort.send);
            sendPort.send(IsolateStorageSyncerInitialized());
            //On start sync
          } else if (message is IsolateStorageStartSyncInstruction) {
            updater?.initSyncStorage();
            //On stop sync
          } else if (message is IsolateStorageStopSyncInstruction) {
            await updater?.close();
            await updateSubscription?.cancel();
            sendPort.send(IsolateStorageSyncerStopped());
            //On one room sync start
          } else if (message is IsolateStorageOneRoomStartSyncInstruction) {
            roomSyncSubscription =
                updater?.startRoomSync(message.roomId).listen(
                      sendPort.send,
                    );
            //On one room sync stop
          } else if (message is IsolateStorageOneRoomStopSyncInstruction) {
            await updater?.closeRoomSync();
            await roomSyncSubscription?.cancel();
          }
        });

        await subscription.asFuture();
        await subscription.cancel();
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

class IsoStorageUpdaterArgs {
  final StoreLocation storeLocation;

  const IsoStorageUpdaterArgs({
    required this.storeLocation,
  });
}
