import 'dart:async';
import 'dart:isolate';

import 'package:meta/meta.dart';

import '../../../matrix_sdk.dart';
import '../updater/isolated/utils.dart';
import '../util/logger.dart';
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

        sendPort.send(receivePort.sendPort);

        subscription = messageStream.listen((message) async {
          if (message is IsoStorageUpdaterArgs) {
            updater = LocalUpdater(
              storeLocation: message.storeLocation,
              isIsolated: false,
            );
            await updater?.init();
            await updater?.ensureReady();
            updateSubscription = updater?.userUpdates.listen(sendPort.send);
            sendPort.send(IsolateStorageSyncerInitialized());
          }
          if (message is IsolateStorageStartSyncInstruction) {
            updater?.initSinkStorage();
          }
          if (message is IsolateStorageStopSyncInstruction) {
            await updater?.close();
            await updateSubscription?.cancel();
            sendPort.send(IsolateStorageSyncerStopped());
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

@immutable
class IsolateStorageSyncerInitialized {}

@immutable
class IsolateStorageSyncerStopped {}

@immutable
class IsolateStorageStartSyncInstruction {}

@immutable
class IsolateStorageStopSyncInstruction {}
