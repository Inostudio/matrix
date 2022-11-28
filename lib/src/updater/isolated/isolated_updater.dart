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

import '../../event/event.dart';
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
  }) async {
    final updater = IsolatedUpdater._(
      myUser,
      homeServer,
      storeLocation,
      saveMyUserToStore: saveMyUserToStore,
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
  }) : super(_user, _homeServer, storeLocation) {
    Updater.register(_user.id, this);

    _syncMessageStream.listen((message) async {
      //On user update
      if (message is MinimizedUpdate) {
        final minimizedUpdate = message;
        _user = await runComputeMerge(_user, minimizedUpdate.delta);
        final update = minimizedUpdate.deminimize(_user);
        _updaterController.add(update);
        return;
      }
      // on Isolate created
      else if (message is SendPort) {
        _syncSendPort = message;

        _syncSendPort?.send(
          UpdaterArgs(
            myUser: _user,
            homeserverUrl: _homeServer.url,
            storeLocation: storeLocation,
            saveMyUserToStore: true,
          ),
        );
      }
      //on Isolate inited
      else if (message is SyncerInitialized) {
        _syncerCompleter.complete();
      }
      // on Room update
      else if (message is Room) {
        _roomUpdatesController.add(message);
        return;
      }
    });

    _instructionStream.listen((message) async {
      if (message is MinimizedUpdate) {
        final minimizedUpdate = message;
        _user = await runComputeMerge(_user, minimizedUpdate.delta);

        final update = minimizedUpdate.deminimize(_user);
        _updaterController.add(update);
        return;
      }

      if (message is SendPort) {
        _sendPort = message;

        _sendPort?.send(
          UpdaterArgs(
            myUser: _user,
            homeserverUrl: _homeServer.url,
            storeLocation: storeLocation,
            saveMyUserToStore: saveMyUserToStore,
          ),
        );
      }

      if (message is RunnerInitialized) {
        _initializedCompleter.complete();
      }

      if (message is ApiCallStatistics) {
        _apiCallStatsSubject.add(message);
      }

      if (message is ErrorWithStackTraceString) {
        _errorSubject.add(message);
      }

      if (message is SyncToken) {
        _tokenSubject.add(message);
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
    );
  }

  Future<void> _spawnRunner() async {
    await Isolate.spawn<IsolateTransferModel>(
      IsolateRunner.run,
      IsolateTransferModel(
        message: _instructionPort.sendPort,
        loggerVariant: Log.variant,
      ),
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
  late final StreamController<Update> __updaterController =
      StreamController<Update>.broadcast();

  // ignore: close_sinks
  late final StreamController<Room> __roomUpdatesController =
      StreamController<Room>.broadcast();

  //Sync with updater
  StreamController<Update> get _updaterController => __updaterController;

  StreamController<Room> get _roomUpdatesController => __roomUpdatesController;

  @override
  Stream<Update> get updates => _updaterController.stream;

  @override
  Stream<Room> get roomUpdates => _roomUpdatesController.stream;

  /// Sends an instruction to the isolate, possibly with a return value.
  Future<T?> execute<T>(
    Instruction<T> instruction, {
    SendPort? port,
  }) async {
    final portToSent = port ?? _sendPort;
    portToSent?.send(instruction);

    if (instruction.expectsReturnValue) {
      final Stream stream = _streamSelector(instruction);

      return await stream.firstWhere(
        (event) => event is T?,
      ) as T?;
    }

    return null;
  }

  Stream<T> _executeStream<T>(
    Instruction<T> instruction, {
    int? updateCount,
    SendPort? port,
  }) {
    final portToSent = port ?? _sendPort;
    portToSent?.send(instruction);

    final Stream stream = _streamSelector(instruction);

    final streamToReturn =
        stream.where((msg) => msg is T).map((msg) => msg as T);

    if (updateCount == null) {
      return streamToReturn;
    } else {
      return streamToReturn.take(updateCount);
    }
  }

  Stream _streamSelector(
    Instruction instruction,
  ) {
    if (instruction is StorageSyncInstruction) {
      return _syncMessageStream;
    } else if (instruction is RequestInstruction) {
      return updates;
    } else if (instruction is OneRoomInstruction) {
      return roomUpdates;
    } else {
      return _instructionStream;
    }
  }

  @override
  Future<List<String?>?> getRoomIDs() => execute(GetRoomIDsInstruction());

  @override
  Future<void> saveRoomToDB(Room room) =>
      execute(SaveRoomToDBInstruction(room));

  @override
  Future<void> startSync({
    Duration maxRetryAfter = const Duration(seconds: 30),
    int timelineLimit = 30,
    String? syncToken,
  }) async =>
      _syncSendPort?.send(
        StartSyncInstruction(maxRetryAfter, timelineLimit, syncToken),
      );

  @override
  Future<void> stopSync() async => _syncSendPort?.send(StopSyncInstruction());

  @override
  Future<SyncToken?> runSyncOnce(SyncFilter filter) async =>
      execute(RunSyncOnceInstruction(filter), port: _syncSendPort);

  @override
  Future<RequestUpdate<MemberTimeline>?> kick(
    UserId id, {
    RoomId? from,
  }) =>
      execute(KickInstruction(id, from));

  @override
  Future<RequestUpdate<Timeline>?> loadRoomEvents({
    RoomId? roomId,
    int count = 20,
    Room? room,
  }) =>
      execute(LoadRoomEventsInstruction(roomId, count, room));

  @override
  Future<RequestUpdate<MemberTimeline>?> loadMembers({
    RoomId? roomId,
    int count = 10,
    Room? room,
  }) =>
      execute(LoadMembersInstruction(roomId, count, room));

  @override
  Future<RequestUpdate<Rooms>?> loadRoomsByIDs(
    Iterable<RoomId> roomIds,
    int timelineLimit,
  ) =>
      execute(LoadRoomsByIDsInstruction(roomIds.toList(), timelineLimit));

  @override
  Future<RequestUpdate<Rooms>?> loadRooms(
    int limit,
    int offset,
    int timelineLimit,
  ) =>
      execute(LoadRoomsInstruction(limit, offset, timelineLimit));

  @override
  Future<RequestUpdate<MyUser>?> logout() async {
    final result = await execute(LogoutInstruction());
    _syncSendPort?.send(LogoutInstruction());
    return result;
  }

  @override
  Future<RequestUpdate<ReadReceipts>?> markRead({
    required RoomId roomId,
    required EventId until,
    bool fullyRead = true,
    bool receipt = true,
    Room? room,
  }) =>
      execute(
        MarkReadInstruction(
          roomId: roomId,
          until: until,
          receipt: receipt,
          room: room,
          fullyRead: fullyRead,
        ),
      );

  @override
  Stream<RequestUpdate<Timeline>?> send(
    RoomId roomId,
    EventContent content, {
    Room? room,
    String? transactionId,
    String stateKey = '',
    String type = '',
  }) =>
      _executeStream(
        SendInstruction(
          roomId,
          content,
          transactionId,
          stateKey,
          type,
          room,
        ),
        // 2 updates are sent, one for local echo and one for being sent.
        updateCount: 2,
      );

  @override
  Stream<Room> startRoomSync(String roomId) => _executeStream(
        OneRoomSyncInstruction(
          roomId: roomId,
          context: user.context,
          userId: user.id,
        ),
        port: _syncSendPort,
      );

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
        ),
      );

  @override
  Future<bool> closeRoomSync(String roomId) async =>
      (await execute(
        CloseRoomSync(roomId: roomId),
        port: _syncSendPort,
      )) ??
      false;

  @override
  Future<bool> closeAllRoomSync() async {
    return (await execute(
          CloseAllRoomsSync(),
          port: _syncSendPort,
        )) ??
        false;
  }

  @override
  Future<RequestUpdate<EphemeralEventFull>?> setIsTyping({
    required RoomId roomId,
    bool isTyping = false,
    Duration timeout = const Duration(seconds: 30),
  }) =>
      execute(SetIsTypingInstruction(roomId, isTyping, timeout));

  @override
  Future<RequestUpdate<Room>?> joinRoom({
    RoomId? id,
    RoomAlias? alias,
    required Uri serverUrl,
  }) =>
      execute(JoinRoomInstruction(id, alias, serverUrl));

  @override
  Future<RequestUpdate<Room>?> leaveRoom(RoomId id) =>
      execute(LeaveRoomInstruction(id));

  @override
  Future<RequestUpdate<MyUser>?> setDisplayName({
    required String name,
  }) =>
      execute(SetNameInstruction(name));

  @override
  Future<void> setPusher(Map<String, dynamic> pusher) =>
      execute(SetPusherInstruction(pusher));

  @override
  Future<RequestUpdate<Timeline>?> edit(
    RoomId roomId,
    TextMessageEvent event,
    String newContent, {
    Room? room,
    String? transactionId,
  }) async {
    return execute(EditTextEventInstruction(
        roomId, event, newContent, transactionId,
        room: room));
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
        DeleteEventInstruction(roomId, eventId, transactionId, reason, room));
  }
}
