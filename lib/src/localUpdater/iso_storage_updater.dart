import 'dart:async';
import 'dart:isolate';

import 'package:matrix_sdk/src/localUpdater/sync_response.dart';

import '../../../matrix_sdk.dart';
import '../updater/isolated/utils.dart';
import '../util/logger.dart';
import '../util/subscription.dart';
import 'instruction.dart';
import 'local_updater.dart';

//Isolate for no internet-updates
abstract class IsolateStorageUpdater {
  static Map<String, StreamSubscription<Room>> roomIdToSyncSubscription = {};

  static Future<void> run(IsolateTransferModel transferModel) async {
    final message = transferModel.message;
    Log.setLogger(transferModel.loggerVariant);
    final receivePort = ReceivePort();
    final messageStream = receivePort.asBroadcastStream();
    final sendPort = message as SendPort;

    await runZonedGuarded(
      () async {
        late LocalUpdater updater;
        StreamSubscription? subscription;
        StreamSubscription? updateSubscription;
        final updaterAvailable = Completer<void>();

        sendPort.send(receivePort.sendPort);

        subscription = messageStream.listen((message) async {
          //first sync, after [receivePort.sendPort] send
          if (message is IsoStorageUpdaterArgs) {
            updater = LocalUpdater(
              storeLocation: message.storeLocation,
              isIsolated: false,
            );
            await updater.init();
            await updater.ensureReady();
            updaterAvailable.complete();
            await subscription?.cancel();
          }
        });

        await updaterAvailable.future;
        await updater.ensureReady();
        updateSubscription = updater.userUpdates.listen(sendPort.send);
        sendPort.send(IsolateStorageSyncerInitialized());

        StreamSubscription? instructionSubscription;
        instructionSubscription = messageStream.listen((message) async {
          if (message is IsolateStorageStartSyncInstruction) {
            updater.initSyncStorage();
            //On stop sync
          } else if (message is IsolateStorageStopSyncInstruction) {
            await updater.close();
            await updateSubscription?.cancel();
            await instructionSubscription?.cancel();
            sendPort.send(IsolateStorageSyncerStopped());
            //On one room sync start
          } else if (message is IsolateStorageOneRoomStartSyncInstruction) {
            roomIdToSyncSubscription[message.roomId] =
                updater.startRoomSync(message.roomId).listen(
                      sendPort.send,
                    );
            //On one room sync stop
          } else if (message is IsolateStorageOneRoomStopSyncInstruction) {
            final resUpd = await updater.closeRoomSync(message.roomId);
            final resLocal = await closeOneSubInMap(
                roomIdToSyncSubscription, message.roomId);
            sendPort.send(
              IsoStorageUpdateClose.oneRoom(
                roomId: message.roomId,
                result: resUpd && resLocal,
              ),
            );
          } else if (message is IsolateStorageOneRoomStopAllSyncInstruction) {
            final resUpd = await updater.closeAllRoomSync();
            final resLocal = await closeAllSubInMap(roomIdToSyncSubscription);
            roomIdToSyncSubscription.clear();
            sendPort.send(
              IsoStorageUpdateClose.allRoom(
                result: resUpd && resLocal,
              ),
            );
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

class IsoStorageUpdaterArgs {
  final StoreLocation storeLocation;

  const IsoStorageUpdaterArgs({
    required this.storeLocation,
  });
}

class IsoStorageUpdateClose {
  final String? roomId;
  final bool all;
  final bool result;

  const IsoStorageUpdateClose({
    this.roomId,
    required this.all,
    required this.result,
  });

  factory IsoStorageUpdateClose.allRoom({required bool result}) =>
      IsoStorageUpdateClose(
        result: result,
        roomId: null,
        all: true,
      );

  factory IsoStorageUpdateClose.oneRoom({
    required bool result,
    required String roomId,
  }) =>
      IsoStorageUpdateClose(
        result: result,
        roomId: roomId,
        all: false,
      );
}
