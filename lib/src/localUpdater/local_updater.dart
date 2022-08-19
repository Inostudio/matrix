import 'dart:async';
import 'dart:isolate';

import 'package:matrix_sdk/matrix_sdk.dart';
import 'package:matrix_sdk/src/localUpdater/iso_storage_updater.dart';
import 'package:matrix_sdk/src/services/local/sink_storage.dart';
import 'package:matrix_sdk/src/util/logger.dart';

import '../services/local/base_sink_storage.dart';
import '../updater/isolated/iso_merge.dart';
import '../updater/isolated/utils.dart';

class LocalUpdater {
  final StoreLocation storeLocation;
  final bool isIsolated;

  LocalUpdater({
    required this.storeLocation,
    this.isIsolated = true,
  });

  BaseSinkStorage? _sinkStorage;

  MyUser? _user;

  final _receivePort = ReceivePort();
  Completer? _closeCompleter;
  SendPort? _sendPort;

  final StreamController<Update> _userUpdatesController =
      StreamController.broadcast();

  Stream<Update> get userUpdates => _userUpdatesController.stream;

  final _errorSubject = StreamController<ErrorWithStackTraceString>.broadcast();

  Stream<ErrorWithStackTraceString> get outError => _errorSubject.stream;

  Future init({bool withInitSinkStorage = false}) async {
    if (isIsolated) {
      await Isolate.spawn<IsolateTransferModel>(
        IsolateStorageUpdater.run,
        IsolateTransferModel(
          loggerVariant: Log.variant,
          message: _receivePort.sendPort,
        ),
      );
      _listenIsolate();
    } else {
      _sinkStorage = SinkStorage(storeLocation: storeLocation);
      if (withInitSinkStorage) {
        initSinkStorage();
      }
    }
  }

  void _listenIsolate() {
    _closeCompleter = Completer();
    _receivePort.listen((message) {
      print("_listenIsolate $message");
      if (message is SendPort) {
        _sendPort = message;
        _sendPort!.send(IsoStorageUpdaterArgs(storeLocation: storeLocation));
      }
      if (message is IsolateStorageSyncerInitialized) {
        _sendPort!.send(IsolateStorageStartSyncInstruction());
      }
      if (message is IsolateStorageSyncerStopped) {
        _closeCompleter?.complete();
      } else if (message is Update) {
        _userUpdatesController.add(message);
      }else if (message is ErrorWithStackTraceString) {
        _errorSubject.add(message);
      }
    });
  }

  Future<bool> ensureReady() async {
    return _sinkStorage != null ? await _sinkStorage!.ensureOpen() : false;
  }

  void initSinkStorage() {
    _sinkStorage?.myUserStorageSink().listen(
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
    await _userUpdatesController.close();
    await _errorSubject.close();
  }
}
