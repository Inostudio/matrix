// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'dart:isolate';

import 'package:matrix_sdk/src/event/ephemeral/ephemeral_event.dart';
import 'package:matrix_sdk/src/event/room/message_event.dart';
import 'package:matrix_sdk/src/model/sync_token.dart';
import 'package:matrix_sdk/src/updater/isolated/iso_storage_sync.dart';
import 'package:matrix_sdk/src/util/subscription.dart';
import 'package:synchronized/synchronized.dart';

import '../../event/event.dart';
import '../../event/room/room_event.dart';
import '../../homeserver.dart';
import '../../model/models.dart';
import '../../room/member/member_timeline.dart';
import '../../room/room.dart';
import '../../room/rooms.dart';
import '../../room/timeline.dart';
import '../../store/store.dart';
import '../../util/logger.dart';
import '../updater.dart';
import 'instruction.dart';
import 'iso_merge.dart';
import 'isolate_runner.dart';
import 'utils.dart';

/// Manages updates to [MyUser] in a different [Isolate].
class IsolatedUpdater extends Updater {
  static Future<IsolatedUpdater> create(
    MyUser myUser,
    Homeserver homeServer,
    StoreLocation storeLocation, {
    bool saveMyUserToStore = false,
    required int timelineLimit,
  }) async {
    final updater = IsolatedUpdater._(
      myUser,
      homeServer,
      storeLocation,
      saveMyUserToStore: saveMyUserToStore,
      timelineLimit: timelineLimit,
    );

    await updater._spawnSyncRunner();
    await updater._spawnRunner();

    await updater._syncInitialized;
    await updater._initialized;

    await updater.ensureReady();
    return updater;
  }

  IsolatedUpdater._(
    this._user,
    this._homeServer,
    StoreLocation storeLocation, {
    bool saveMyUserToStore = false,
    required int timelineLimit,
  }) : super(
          _user,
          _homeServer,
          storeLocation,
          timelineLimit: timelineLimit,
        ) {
    Updater.register(_user.id, this);

    _syncMessageStream.listen((m) async {
      final message = m as IsolateRespose;

      //On user update
      if (message.data is MinimizedUpdate) {
        final minimizedUpdate = message.data as MinimizedUpdate;
        _user = await runComputeMerge(_user, minimizedUpdate.delta);
        final update = minimizedUpdate.deminimize(_user);

        _updaterController.add(
          makeResponseData(
            null,
            update,
            instructionId: message.dataInstructionId,
          ),
        );
        return;
      }
      // on Isolate created
      else if (message is IsolateRespose<SendPort>) {
        _syncSendPort = message.data;

        _syncSendPort?.send(
          UpdaterArgs(
            myUser: _user,
            homeserverUrl: _homeServer.url,
            storeLocation: storeLocation,
            saveMyUserToStore: true,
            timelineLimit: timelineLimit,
          ),
        );
      }
      //on Isolate inited
      else if (message is IsolateRespose<SyncerInitialized>) {
        _syncerCompleter.complete();
      }
      // on Room update
      else if (message is IsolateRespose<Room>) {
        final roomId = message.data.id.value;
        _updateOneRoomSync(roomId, message);
      }

      if (message is IsolateRespose<ApiCallStatistics>) {
        _apiCallStatsSubject.add(message.data);
      }
    });

    _instructionStream.listen((m) async {
      final message = m as IsolateRespose;
      if (message.data is MinimizedUpdate) {
        final minimizedUpdate = message.data as MinimizedUpdate;
        _user = await runComputeMerge(_user, minimizedUpdate.delta);
        final update = minimizedUpdate.deminimize(_user);
        _updaterController.add(
          makeResponseData(
            null,
            update,
            instructionId: message.dataInstructionId,
          ),
        );
        return;
      }

      if (message is IsolateRespose<SendPort>) {
        _sendPort = message.data;

        _sendPort?.send(
          UpdaterArgs(
            myUser: _user,
            homeserverUrl: _homeServer.url,
            storeLocation: storeLocation,
            saveMyUserToStore: saveMyUserToStore,
            timelineLimit: timelineLimit,
          ),
        );
      }

      if (message is IsolateRespose<RunnerInitialized>) {
        _initializedCompleter.complete();
      }

      if (message is IsolateRespose<ApiCallStatistics>) {
        _apiCallStatsSubject.add(message.data);
      }

      if (message is IsolateRespose<ErrorWithStackTraceString>) {
        _errorSubject.add(message.data);
      }

      if (message is IsolateRespose<SyncToken>) {
        _tokenSubject.add(message.data);
      }
    });
  }

  Future<void> _spawnSyncRunner() async {
    await Isolate.spawn<IsolateTransferModel>(
      IsolateStorageSyncRunner.run,
      IsolateTransferModel(
        message: _syncReceivePort.sendPort,
        loggerVariant: Log.variant,
      ),
      errorsAreFatal: false,
    );
  }

  Future<void> _spawnRunner() async {
    await Isolate.spawn<IsolateTransferModel>(
      IsolateRunner.run,
      IsolateTransferModel(
        message: _instructionPort.sendPort,
        loggerVariant: Log.variant,
      ),
      errorsAreFatal: false,
    );
  }

  SendPort? _syncSendPort;
  SendPort? _sendPort;

  @override
  bool get isReady => _sendPort != null;

  //Instruction port
  final _instructionPort = ReceivePort();

  //Update for user and room port
  final _syncReceivePort = ReceivePort();

  //Instruction stream
  late final Stream<dynamic> __syncMessageStream =
      _syncReceivePort.asBroadcastStream();

  //Update stream
  late final Stream<dynamic> __instructionStream =
      _instructionPort.asBroadcastStream();

  Stream<dynamic> get _instructionStream => __instructionStream;

  Stream<dynamic> get _syncMessageStream => __syncMessageStream;

  final _errorSubject = StreamController<ErrorWithStackTraceString>.broadcast();

  @override
  Stream<ErrorWithStackTraceString> get outError => _errorSubject.stream;

  final _tokenSubject = StreamController<SyncToken>.broadcast();

  @override
  Stream<SyncToken> get outSyncToken => _tokenSubject.stream;

  // ignore: close_sinks
  final _apiCallStatsSubject = StreamController<ApiCallStatistics>.broadcast();

  @override
  Stream<ApiCallStatistics> get outApiCallStatistics =>
      _apiCallStatsSubject.stream;

  final _initializedCompleter = Completer<void>();
  final _syncerCompleter = Completer<void>();

  Future<void> get _initialized => _initializedCompleter.future;

  Future<void> get _syncInitialized => _syncerCompleter.future;

  MyUser _user;

  @override
  MyUser get user => _user;

  final Homeserver _homeServer;

  @override
  Homeserver get homeServer => _homeServer;

  // ignore: close_sinks
  late final StreamController<IsolateRespose<Update>> __updaterController =
      StreamController<IsolateRespose<Update>>.broadcast();

  //Sync with updater
  StreamController<IsolateRespose<Update>> get _updaterController =>
      __updaterController;

  @override
  Stream<Update> get updates =>
      _updaterController.stream.map((event) => event.data);

  final Map<String, StreamController<IsolateRespose<Room>>>
      _roomIdToSyncController = {};

  /// Sends an instruction to the isolate, possibly with a return value.
  Future<T?> execute<T>(
    Instruction instruction, {
    SendPort? port,
  }) async {
    try {
      final portToSent = port ?? _sendPort;
      portToSent?.send(instruction);

      if (instruction.expectsReturnValue) {
        final stream = _streamSelector(instruction);

        final streamRes = await stream
            .where((msg) => msg is IsolateRespose && msg.data is T)
            .firstWhere((event) => _checkResponse(event, instruction));
        return streamRes.data;
      }

      return null;
    } catch (e, st) {
      Log.writer.log(
        "execute Instruction: $instruction\nInstructionID ${instruction.instructionId}\nerror:$e\nStackTrace: $st",
      );
      rethrow;
    }
  }

  Stream<T> _executeStream<T>(
    Instruction instruction, {
    int? updateCount,
    SendPort? port,
  }) {
    try {
      final portToSent = port ?? _sendPort;
      portToSent?.send(instruction);

      final Stream stream = _streamSelector(instruction);

      final streamToReturn = stream
          .where((msg) => msg is IsolateRespose && msg.data is T)
          .where((msg) => _checkResponse(msg, instruction));

      if (updateCount == null) {
        return streamToReturn.map<T>((event) => event.data);
      } else {
        return streamToReturn.take(updateCount).map<T>((event) => event.data);
      }
    } catch (e, st) {
      Log.writer.log(
        "execute Instruction: $instruction\nInstructionID ${instruction.instructionId}\nerror:$e\nStackTrace: $st",
      );
      rethrow;
    }
  }

  //If any instruction id is null - false
  //If instruction id equal response instruction id - true; else - false
  bool _checkResponse(
    IsolateRespose event,
    Instruction<dynamic> instruction,
  ) {
    if (event.dataInstructionId == null || event.dataInstructionId == null) {
      return false;
    } else {
      return instruction.instructionId == event.dataInstructionId;
    }
  }

  Stream _streamSelector(
    Instruction instruction,
  ) {
    if (instruction is StorageSyncInstruction) {
      return _syncMessageStream;
    } else if (instruction is RequestInstruction) {
      return _updaterController.stream;
    } else if (instruction is OneRoomSyncInstruction) {
      return _getOneRoomUpdates(instruction.roomId);
    } else {
      return _instructionStream;
    }
  }

  void _updateOneRoomSync(String roomId, IsolateRespose<Room> room) {
    if (!_roomIdToSyncController.keys.contains(roomId)) {
      _roomIdToSyncController[roomId] =
          StreamController<IsolateRespose<Room>>.broadcast();
    }
    _roomIdToSyncController[roomId]!.add(room);
  }

  Stream<IsolateRespose<Room>> _getOneRoomUpdates(String roomId) {
    if (!_roomIdToSyncController.keys.contains(roomId)) {
      _roomIdToSyncController[roomId] =
          StreamController<IsolateRespose<Room>>.broadcast();
    }
    return _roomIdToSyncController[roomId]!.stream;
  }

  int instructionNumber = 1;
  final instructionNumberLock = Lock();

  Future<int> _getNextInstructionNumber() async {
    return instructionNumberLock.synchronized(() => instructionNumber++);
  }

  @override
  Future<List<String?>?> getRoomIDs() async => execute(
        GetRoomIDsInstruction(
          instructionId: await _getNextInstructionNumber(),
        ),
      );

  @override
  Future<void> saveRoomToDB(Room room) async => execute(
        SaveRoomToDBInstruction(
          room: room,
          instructionId: await _getNextInstructionNumber(),
        ),
      );

  @override
  Future<void> startSync({
    Duration maxRetryAfter = const Duration(seconds: 30),
    int timelineLimit = 30,
    String? syncToken,
  }) async =>
      _syncSendPort?.send(
        StartSyncInstruction(
          maxRetryAfter: maxRetryAfter,
          timelineLimit: timelineLimit,
          syncToken: syncToken,
          instructionId: await _getNextInstructionNumber(),
        ),
      );

  @override
  Future<void> stopSync() async => _syncSendPort?.send(
        StopSyncInstruction(
          instructionId: await _getNextInstructionNumber(),
        ),
      );

  @override
  Future<SyncToken?> runSyncOnce(SyncFilter filter) async => execute(
      RunSyncOnceInstruction(
        filter: filter,
        instructionId: await _getNextInstructionNumber(),
      ),
      port: _syncSendPort);

  @override
  Future<RequestUpdate<MemberTimeline>?> kick(
    UserId id, {
    RoomId? from,
  }) async =>
      execute(
        KickInstruction(
          id: id,
          from: from,
          instructionId: await _getNextInstructionNumber(),
        ),
      );

  @override
  Future<RequestUpdate<Timeline>?> loadRoomEvents({
    RoomId? roomId,
    int count = 20,
    Room? room,
  }) async =>
      execute(
        LoadRoomEventsInstruction(
          roomId: roomId,
          count: count,
          room: room,
          instructionId: await _getNextInstructionNumber(),
        ),
      );

  @override
  Future<Iterable<RoomEvent>> getAllFakeMessages() async => await execute(
        LoadFakeRoomEventsInstruction(
          instructionId: await _getNextInstructionNumber(),
        ),
      );

  @override
  Future<bool> deleteFakeEvent(String transactionId) async => await execute(
        DeleteFakeRoomEventInstruction(
          transactionId: transactionId,
          instructionId: await _getNextInstructionNumber(),
        ),
      );

  @override
  Future<RequestUpdate<Rooms>?> loadRooms(
    int limit,
    int offset,
    int timelineLimit,
  ) async =>
      execute(
        LoadRoomsInstruction(
          limit: limit,
          offset: offset,
          timelineLimit: timelineLimit,
          instructionId: await _getNextInstructionNumber(),
        ),
      );

  @override
  Future<RequestUpdate<MyUser>?> logout() async {
    final result = await execute(
      LogoutInstruction(
        instructionId: await _getNextInstructionNumber(),
      ),
    );
    _syncSendPort?.send(
      LogoutInstruction(
        instructionId: await _getNextInstructionNumber(),
      ),
    );
    await __updaterController.close();
    return result;
  }

  @override
  Future<RequestUpdate<ReadReceipts>?> markRead({
    required RoomId roomId,
    required EventId until,
    bool fullyRead = true,
    bool receipt = true,
    Room? room,
  }) async =>
      execute(
        MarkReadInstruction(
          roomId: roomId,
          until: until,
          receipt: receipt,
          room: room,
          fullyRead: fullyRead,
          instructionId: await _getNextInstructionNumber(),
        ),
      );

  @override
  Future<RoomEvent?> sendReadyEvent(
    RoomEvent roomEvent, {
    required bool isState,
  }) async {
    return execute(
      SendReadyInstruction(
        isState: isState,
        roomEvent: roomEvent,
        instructionId: await _getNextInstructionNumber(),
      ),
      // 2 updates are sent, one for local echo and one for being sent.
    );
  }

  @override
  Stream<RoomEvent?> send(
    RoomId roomId,
    EventContent content, {
    Room? room,
    String? transactionId,
    String stateKey = '',
    String type = '',
  }) async* {
    yield* _executeStream(
      SendInstruction(
        roomId: roomId,
        content: content,
        transactionId: transactionId,
        stateKey: stateKey,
        type: type,
        room: room,
        instructionId: await _getNextInstructionNumber(),
      ),
      // 2 updates are sent, one for local echo and one for being sent.
      updateCount: 2,
    );
  }

  @override
  Stream<Room> startRoomSync(String roomId) async* {
    if (!_roomIdToSyncController.keys.contains(roomId)) {
      _roomIdToSyncController[roomId] =
          StreamController<IsolateRespose<Room>>.broadcast();
    }
    yield* _executeStream(
      OneRoomSyncInstruction(
        roomId: roomId,
        context: user.context,
        userId: user.id,
        instructionId: await _getNextInstructionNumber(),
      ),
      port: _syncSendPort,
    );
  }

  @override
  Future<Room?> fetchRoomFromDB(
    String roomId, {
    Context? context,
    List<UserId>? memberIds,
  }) async =>
      execute(
        GetRoomInstruction(
          roomId: roomId,
          context: context ?? user.context,
          memberIds: memberIds ?? [user.id],
          instructionId: await _getNextInstructionNumber(),
        ),
      );

  @override
  Future<bool> closeRoomSync(String roomId) async {
    final result = (await execute(
          CloseRoomSync(
            roomId: roomId,
            instructionId: await _getNextInstructionNumber(),
          ),
          port: _syncSendPort,
        )) ??
        false;
    await _roomIdToSyncController[roomId]?.close();
    _roomIdToSyncController.remove(roomId);
    return result;
  }

  @override
  Future<bool> closeAllRoomSync() async {
    final result = (await execute(
          CloseAllRoomsSync(
            instructionId: await _getNextInstructionNumber(),
          ),
          port: _syncSendPort,
        )) ??
        false;
    await doAsyncAllSubInMap<String, StreamController<IsolateRespose<Room>>>(
      _roomIdToSyncController,
      (e) => e.value.close(),
    );
    _roomIdToSyncController.clear();
    return result;
  }

  @override
  Future<RequestUpdate<EphemeralEventFull>?> setIsTyping({
    required RoomId roomId,
    bool isTyping = false,
    Duration timeout = const Duration(seconds: 30),
  }) async =>
      execute(
        SetIsTypingInstruction(
          roomId: roomId,
          isTyping: isTyping,
          timeout: timeout,
          instructionId: await _getNextInstructionNumber(),
        ),
      );

  @override
  Future<RequestUpdate<Room>?> joinRoom({
    RoomId? id,
    RoomAlias? alias,
    required Uri serverUrl,
  }) async =>
      execute(
        JoinRoomInstruction(
          id: id,
          alias: alias,
          serverUrl: serverUrl,
          instructionId: await _getNextInstructionNumber(),
        ),
      );

  @override
  Future<RequestUpdate<Room>?> leaveRoom(RoomId id) async => execute(
        LeaveRoomInstruction(
          id: id,
          instructionId: await _getNextInstructionNumber(),
        ),
      );

  @override
  Future<bool?> setPusher(Map<String, dynamic> pusher) async => execute(
        SetPusherInstruction(
          pusher: pusher,
          instructionId: await _getNextInstructionNumber(),
        ),
      );

  @override
  Future<RequestUpdate<Timeline>?> edit(
    RoomId roomId,
    TextMessageEvent event,
    String newContent, {
    Room? room,
    String? transactionId,
  }) async {
    return execute(
      EditTextEventInstruction(
        roomId: roomId,
        event: event,
        newContent: newContent,
        transactionId: transactionId,
        room: room,
        instructionId: await _getNextInstructionNumber(),
      ),
    );
  }

  @override
  Future<RequestUpdate<Timeline>?> delete(
    RoomId roomId,
    EventId eventId, {
    String? transactionId,
    String? reason,
    Room? room,
  }) async {
    return execute(
      DeleteEventInstruction(
        roomId: roomId,
        eventId: eventId,
        transactionId: transactionId,
        reason: reason,
        room: room,
        instructionId: await _getNextInstructionNumber(),
      ),
    );
  }
}
