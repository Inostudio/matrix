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
  Completer? _closeCompleter;
  SendPort? _sendPort;

  StreamSubscription? _roomSubscription;
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

    _roomSubscription = _syncStorage!
        .roomStorageSync(
          selectedRoomId: roomId,
          userId: id,
        )
        .listen(_roomUpdatesSubject.add);

    yield* roomUpdates;
  }

  Future<void> closeRoomSync() async {
    isIsolated
        ? _sendPort?.send(IsolateStorageOneRoomStopSyncInstruction())
        : _roomSubscription?.cancel();
  }

  void _listenIsolate() {
    _closeCompleter = Completer();
    _receivePort.listen((message) {
      //first isolate answer
      if (message is SendPort) {
        _sendPort = message;
        _sendPort!.send(IsoStorageUpdaterArgs(storeLocation: storeLocation));
        //on isolate ready to start sync
      } else if (message is IsolateStorageSyncerInitialized) {
        _sendPort!.send(IsolateStorageStartSyncInstruction());
        //on isolate preformed stop sync
      } else if (message is IsolateStorageSyncerStopped) {
        _closeCompleter?.complete();
        //on isolate user update
      } else if (message is Update) {
        _userUpdatesController.add(message);
        //on isolate room update
      } else if (message is Room) {
        _roomUpdatesSubject.add(message);
        //on isolate error
      } else if (message is ErrorWithStackTraceString) {
        _errorSubject.add(message);
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
    await _closeCompleter?.future;
    await _userSubscription?.cancel();
    await _roomSubscription?.cancel();
    await _userUpdatesController.close();
    await _errorSubject.close();
    await _roomUpdatesSubject.close();
  }
}
