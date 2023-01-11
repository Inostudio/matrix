import 'dart:async';
import 'dart:isolate';

import 'package:matrix_sdk/matrix_sdk.dart';
import 'package:matrix_sdk/src/localUpdater/iso_storage_updater.dart';
import 'package:matrix_sdk/src/localUpdater/sync_response.dart';
import 'package:matrix_sdk/src/services/local/sync_storage.dart';
import 'package:matrix_sdk/src/util/logger.dart';

import '../services/local/base_sync_storage.dart';
import '../updater/isolated/iso_merge.dart';
import '../updater/isolated/utils.dart';
import '../util/subscription.dart';
import 'instruction.dart';

class LocalUpdater {
  final StoreLocation storeLocation;
  final bool isIsolated;

  LocalUpdater({
    required this.storeLocation,
    this.isIsolated = true,
  });

  BaseSyncStorage? _syncStorage;

  MyUser? _user;

  final _receivePort = ReceivePort();
  Completer? _stopCompleter;
  final Completer _sendPortReadyCompleter = Completer();
  SendPort? _sendPort;

  Map<String, StreamSubscription<Room>> roomIdToSyncSubscription = {};
  Map<String, Completer<bool>> roomIdToStopCompleter = {};
  StreamSubscription? _userSubscription;

  final StreamController<Room> _roomUpdatesSubject =
      StreamController<Room>.broadcast();

  Stream<Room> get roomUpdates => _roomUpdatesSubject.stream;

  final StreamController<Update> _userUpdatesController =
      StreamController.broadcast();

  Stream<Update> get userUpdates => _userUpdatesController.stream;

  final _errorSubject = StreamController<ErrorWithStackTraceString>.broadcast();

  Stream<ErrorWithStackTraceString> get outError => _errorSubject.stream;

  Future<void> init({bool withInitSyncStorage = false}) async {
    if (isIsolated) {
      await _initIsolated();
    } else {
      await _initMain(withInitSyncStorage: withInitSyncStorage);
    }
  }

  Future<void> _initIsolated() async {
    await Isolate.spawn<IsolateTransferModel>(
      IsolateStorageUpdater.run,
      IsolateTransferModel(
        loggerVariant: Log.variant,
        message: _receivePort.sendPort,
      ),
      errorsAreFatal: false,
    );
    _listenIsolate();
  }

  Future<void> _initMain({bool withInitSyncStorage = false}) async {
    _syncStorage = SyncStorage(storeLocation: storeLocation);
    if (withInitSyncStorage) {
      initSyncStorage();
    }
  }

  Stream<Room> startRoomSync(String roomId) async* {
    if (isIsolated) {
      yield* _startSyncIso(roomId);
    } else {
      yield* _startSyncMain(roomId);
    }
  }

  Completer<Iterable<RoomEvent>>? _getRoomEventsCompleter;
  Future<Iterable<RoomEvent>> getAllFakeMessages() async {
    if (isIsolated) {
      await _sendPortReadyCompleter.future;
      _getRoomEventsCompleter = Completer();
      _sendPort?.send(IsolateStorageGetAllFake());
      final result = await _getRoomEventsCompleter?.future;
      return result ?? [];
    } else {
      return await _syncStorage?.getAllFakeEvents() ?? [];
    }
  }

  Completer<bool>? _deleteRoomEventsCompleter;

  Future<bool> deleteFakeEvent(String transactionId) async {
    if (isIsolated) {
      await _sendPortReadyCompleter.future;
      _deleteRoomEventsCompleter = Completer();
      _sendPort?.send(
        IsolateStorageDeleteFakeEvent(transactionId: transactionId),
      );
      final result = await _deleteRoomEventsCompleter?.future;
      return result ?? false;
    } else {
      return await _syncStorage?.deleteFakeEvent(transactionId) ?? false;
    }
  }

  Stream<Room> _startSyncIso(String roomId) async* {
    _sendPort?.send(
      IsolateStorageOneRoomStartSyncInstruction(roomId: roomId),
    );
    yield* roomUpdates;
  }

  Stream<Room> _startSyncMain(String roomId) async* {
    UserId? id = _user?.id;
    if (id == null) {
      final user = await _syncStorage?.getMyUser();
      id = user?.id;
    }

    if (id == null || _syncStorage == null) {
      final errorString =
          "id or storage not ready id: $id, syncStorage: $_syncStorage";
      final error = ErrorWithStackTraceString(
        errorString,
        StackTrace.current.toString(),
      );
      _errorSubject.add(error);
      Log.writer.log(errorString);
      throw Exception(errorString);
    }

    roomIdToSyncSubscription[roomId] = _syncStorage!
        .roomStorageSync(
          selectedRoomId: roomId,
          userId: id,
        )
        .listen(_roomUpdatesSubject.add);

    yield* roomUpdates;
  }

  Future<bool> closeRoomSync(String roomId) async {
    try {
      if (isIsolated) {
        roomIdToStopCompleter[roomId] = Completer();
        _sendPort?.send(
          IsolateStorageOneRoomStopSyncInstruction(roomId: roomId),
        );
        final result = await roomIdToStopCompleter[roomId]?.future;
        return result ?? false;
      } else {
        final res = closeOneSubInMap(roomIdToSyncSubscription, roomId);
        roomIdToSyncSubscription.remove(roomId);
        return res;
      }
    } catch (e) {
      Log.writer.log("LOCAL: closeRoomSync", e.toString());
      return false;
    }
  }

  Future<bool> closeAllRoomSync() async {
    try {
      if (isIsolated) {
        _sendPort?.send(
          IsolateStorageOneRoomStopAllSyncInstruction(),
        );
        final result = await Future.wait(
          roomIdToStopCompleter.values.map((e) => e.future),
        );
        return result.fold<bool>(
          true,
          (previousValue, element) => previousValue && element,
        );
      } else {
        final res = closeAllSubInMap(roomIdToSyncSubscription);
        roomIdToSyncSubscription.clear();
        return res;
      }
    } catch (e) {
      Log.writer.log("LOCAL: closeRoomSync", e.toString());
      return false;
    }
  }

  void _listenIsolate() {
    _stopCompleter = Completer();
    _receivePort.listen((message) {
      //first isolate answer
      if (message is SendPort) {
        _sendPort = message;
        _sendPort!.send(IsoStorageUpdaterArgs(storeLocation: storeLocation));
        _sendPortReadyCompleter.complete();
        //on isolate ready to start sync
      } else if (message is IsolateStorageSyncerInitialized) {
        _sendPort!.send(IsolateStorageStartSyncInstruction());
        //on isolate preformed stop sync
      } else if (message is IsolateStorageSyncerStopped) {
        _stopCompleter?.complete();
        //on isolate user update
      } else if (message is Update) {
        _userUpdatesController.add(message);
        //on isolate room update
      } else if (message is Room) {
        _roomUpdatesSubject.add(message);
        //on isolate error
      } else if (message is ErrorWithStackTraceString) {
        _errorSubject.add(message);
      } else if (message is IsoStorageUpdateClose) {
        //on close one room sync
        if (message.all) {
          doAllSubInMap<String, Completer>(
            roomIdToStopCompleter,
            (p0) => p0.value.complete(message.result),
          );
        } else {
          roomIdToStopCompleter[message.roomId]?.complete(message.result);
        }
      } else if (message is IsolateStorageGetAllFakeResp) {
        _getRoomEventsCompleter?.complete(message.fakes);
      } else if (message is IsolateStorageDeleteFakeResp) {
        _deleteRoomEventsCompleter?.complete(message.result);
      }
    });
  }

  Future<bool> ensureReady() async {
    return _syncStorage != null ? await _syncStorage!.ensureOpen() : false;
  }

  void initSyncStorage() {
    _userSubscription = _syncStorage?.myUserStorageSync().listen(
          (storeUpdate) => _notifyWithUpdate(
            storeUpdate,
            SyncUpdate.new,
          ),
        );
  }

  Future<void> _notifyWithUpdate<U extends Update>(
    MyUser delta,
    U Function(MyUser user, MyUser delta) createUpdate,
  ) async {
    if (_user == null) {
      _user = delta;
    } else {
      _user = await runComputeMerge(_user!, delta);
    }
    final update = createUpdate(_user!, delta);
    _userUpdatesController.add(update);
  }

  Future<void> close() async {
    _sendPort?.send(IsolateStorageStopSyncInstruction());
    await _stopCompleter?.future;
    await _userSubscription?.cancel();
    await closeAllSubInMap(roomIdToSyncSubscription);
    await _userUpdatesController.close();
    await _errorSubject.close();
    await _roomUpdatesSubject.close();
  }
}
