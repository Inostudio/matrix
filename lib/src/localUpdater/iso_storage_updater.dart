import 'dart:async';
import 'dart:isolate';

import 'package:matrix_sdk/src/localUpdater/sink_response.dart';

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
        StreamSubscription<Room>? roomSinkSubscription;

        sendPort.send(receivePort.sendPort);

        subscription = messageStream.listen((message) async {
          //first sink, after [receivePort.sendPort] send
          if (message is IsoStorageUpdaterArgs) {
            updater = LocalUpdater(
              storeLocation: message.storeLocation,
              isIsolated: false,
            );
            await updater?.init();
            await updater?.ensureReady();
            updateSubscription = updater?.userUpdates.listen(sendPort.send);
            sendPort.send(IsolateStorageSyncerInitialized());
            //On start sink
          } else if (message is IsolateStorageStartSyncInstruction) {
            updater?.initSinkStorage();
            //On stop sink
          } else if (message is IsolateStorageStopSyncInstruction) {
            await updater?.close();
            await updateSubscription?.cancel();
            sendPort.send(IsolateStorageSyncerStopped());
            //On one room sink start
          } else if (message is IsolateStorageOneRoomStartSyncInstruction) {
            roomSinkSubscription =
                updater?.startRoomSink(message.roomId).listen(
                      sendPort.send,
                    );
            //On one room sink stop
          } else if (message is IsolateStorageOneRoomStopSyncInstruction) {
            await updater?.closeRoomSink();
            await roomSinkSubscription?.cancel();
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
