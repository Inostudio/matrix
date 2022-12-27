import 'dart:async';

import 'package:matrix_sdk/matrix_sdk.dart';
import 'package:matrix_sdk/src/services/local/base_sync_storage.dart';
import 'package:matrix_sdk/src/services/local/sync_storage.dart';
import 'package:matrix_sdk/src/updater/isolated/isolated_updater.dart';
import 'package:matrix_sdk/src/util/logger.dart';

import 'localUpdater/local_updater.dart';
import 'model/sync_token.dart';

class MatrixClient {
  final bool isIsolated;
  final bool withDebugLog;
  Uri? serverUri;
  Homeserver? _homeServer;
  final StoreLocation _storeLocation;
  final List<StreamSubscription> _streamSubscription = [];

  // ignore: close_sinks
  final _apiCallStatsSubject = StreamController<ApiCallStatistics>.broadcast();

  Stream<ApiCallStatistics> get outApiCallStatistics =>
      _apiCallStatsSubject.stream;

  // ignore: close_sinks
  final _errorSubject = StreamController<ErrorWithStackTraceString>.broadcast();

  Stream<ErrorWithStackTraceString> get outError => _errorSubject.stream;

  // ignore: close_sinks
  final _updatesSubject = StreamController<Update>.broadcast();

  Stream<Update> get outUpdates => _updatesSubject.stream;

  Updater? _updater;
  LocalUpdater? _localUpdater;
  late BaseSyncStorage _syncStorage;

  MatrixClient({
    this.isIsolated = true,
    this.withDebugLog = false,
    this.serverUri,
    required StoreLocation storeLocation,
  }) : _storeLocation = storeLocation {
    _syncStorage = SyncStorage(storeLocation: storeLocation);
    if (serverUri != null) {
      Log.setLogger(withDebugLog ? LoggerVariant.dev : LoggerVariant.none);
      _homeServer = Homeserver(serverUri!);
    }
  }

  Homeserver? get homeServer => _homeServer;

  bool? get isLocal {
    if (_updater == null && _localUpdater != null) {
      return true;
    }
    if (_updater != null && _localUpdater == null) {
      return false;
    }
    return null;
  }

  void setServerUri(Uri serverUriToSet) {
    serverUri = serverUriToSet;
    _homeServer = Homeserver(serverUriToSet);
  }

  /// Get all invites for this user. Note that for now this will load
  /// all rooms to memory.
  /*Future<List<Invite>> get invites async =>
      (await _rooms.get(where: (r) => r is InvitedRoom))
          .map((r) => Invite._(scope, r))
          .toList(growable: false);*/

  Future<void> createWithLastLocal() async {
    //Destroy remote updater
    await _updater?.stopSync();
    _updater = null;
    _clearSubs();

    //Create local updater
    _localUpdater = LocalUpdater(
      storeLocation: _storeLocation,
      isIsolated: isIsolated,
    );
    await _localUpdater?.init();

    //Make sync
    _streamSubscription.add(
      _localUpdater!.userUpdates.listen(_updatesSubject.add),
    );
    _streamSubscription.add(
      _localUpdater!.outError.listen(_errorSubject.add),
    );
  }

  Future<MyUser> createWithLoginOrLastToken(
    UserIdentifier user,
    String password, {
    Device? device,
  }) async {
    if (serverUri == null) {
      throw Exception("Server uri is empty $serverUri");
    }

    //Destroy local updater
    await _localUpdater?.close();
    _localUpdater = null;
    _clearSubs();

    await _syncStorage.ensureOpen();

    MyUser? myUser;
    final localUser = await _syncStorage.getMyUser();
    final userToken = localUser?.accessToken;

    if (localUser != null && userToken != null && userToken.isNotEmpty) {
      myUser = localUser;
    } else {
      final networkUser = await login(user, password, device: device);
      myUser = networkUser;
    }

    if (isIsolated) {
      _updater = await IsolatedUpdater.create(
        myUser,
        _homeServer!,
        _storeLocation,
        saveMyUserToStore: isIsolated,
      );
    } else {
      _updater = Updater(
        myUser,
        _homeServer!,
        _storeLocation,
        initSyncStorage: !isIsolated,
      );
    }

    //Make sync
    if (_updater != null) {
      await _updater!.ensureReady();

      _streamSubscription.add(_updater!.updates.listen(_updatesSubject.add));
      _streamSubscription
          .add(_updater!.outApiCallStatistics.listen(_apiCallStatsSubject.add));
      _streamSubscription.add(_updater!.outError.listen(_errorSubject.add));
    }

    return myUser;
  }

  Future<MyUser> createWithLogin(
    UserIdentifier user,
    String password, {
    Device? device,
  }) async {
    if (serverUri == null) {
      throw Exception("Server uri is empty $serverUri");
    }

    //Destroy local updater
    await _localUpdater?.close();
    _localUpdater = null;
    _clearSubs();

    //Perform auth and create updater
    final result = await login(user, password, device: device);

    if (isIsolated) {
      _updater = await IsolatedUpdater.create(
        result,
        _homeServer!,
        _storeLocation,
        saveMyUserToStore: isIsolated,
      );
    } else {
      _updater = Updater(
        result,
        _homeServer!,
        _storeLocation,
        initSyncStorage: !isIsolated,
      );
    }

    //Make sync
    if (_updater != null) {
      await _updater!.ensureReady();

      _streamSubscription.add(_updater!.updates.listen(_updatesSubject.add));
      _streamSubscription
          .add(_updater!.outApiCallStatistics.listen(_apiCallStatsSubject.add));
      _streamSubscription.add(_updater!.outError.listen(_errorSubject.add));
    }

    return result;
  }

  Future<MyUser> login(
    UserIdentifier user,
    String password, {
    Device? device,
  }) async {
    if (_homeServer == null) {
      throw Exception("HomeServer is null $_homeServer");
    }

    _streamSubscription
        .add(_homeServer!.outApiCallStats.listen(_apiCallStatsSubject.add));
    await _syncStorage.ensureOpen();
    final myUser = await _homeServer!.login(
      user,
      password,
      device: device,
    );
    await _syncStorage.setUserDelta(myUser);
    return myUser;
  }

  /// Invalidates the access token of the user. Makes all
  /// [MyUser] calls unusable.
  ///
  /// Returns the [Update] where [MyUser] has logged out, if successful.
  Future<RequestUpdate<MyUser>?> logout() async {
    await stopAllRoomSync();
    await stopSync();
    return _updater?.logout();
  }

  /// Send all unsent messages still in the [Store].
  /*Future<void> sendAllUnsent() async {
    for (Room room in await rooms.get()) {
      if (room is JoinedRoom) {
        for (RoomEvent event in await _store.getUnsentEvents(room)) {
          await for (final _ in room.send(
            event.content,
            transactionId: event.transactionId,
          )) {}
        }
      }
    }
  }*/

  bool isSyncing(MyUser user) =>
      user.context?.updater?.syncer.isSyncing ?? false;

  void startSync(
    MyUser user, {
    Duration maxRetryAfter = const Duration(seconds: 30),
    int timelineLimit = 30,
  }) =>
      user.context?.updater?.startSync(
        maxRetryAfter: maxRetryAfter,
        timelineLimit: timelineLimit,
        syncToken: user.syncToken,
      );

  void _clearSubs() {
    _streamSubscription.forEach((e) => e.cancel());
    _streamSubscription.clear();
  }

  Future<void> stopSync() async {
    _clearSubs();
    await _updater?.stopSync();
  }

  Future<RequestUpdate<Timeline>?> loadRoomEvents({
    required RoomId roomId,
    required int count,
    Room? room,
  }) async {
    if (_updater == null) {
      Log.writer.log("Updater not created");
      return Future.value(null);
    }

    return _updater!.loadRoomEvents(roomId: roomId, count: count, room: room);
  }

  Stream<Room> getRoomSync(String roomId) async* {
    if (isLocal == true && _localUpdater != null) {
      yield* _localUpdater!.startRoomSync(roomId);
    } else if (isLocal == false && _updater != null) {
      yield* _updater!.startRoomSync(roomId);
    } else {
      throw Exception(
        "Cant handle get room sync isLocal: $isLocal updater: $_updater, _localUpdater: $_localUpdater,",
      );
    }
  }

  Future<bool> stopOneRoomSync(String roomId) async {
    if (isLocal == true && _localUpdater != null) {
      return _localUpdater!.closeRoomSync(roomId);
    } else if (isLocal == false && _updater != null) {
      return _updater!.closeRoomSync(roomId);
    } else {
      throw Exception(
        "Cant handle room close: isLocal: $isLocal updater: $_updater, _localUpdater: $_localUpdater,",
      );
    }
  }

  Future<bool> stopAllRoomSync() async {
    if (isLocal == true && _localUpdater != null) {
      return _localUpdater!.closeAllRoomSync();
    } else if (isLocal == false && _updater != null) {
      return _updater!.closeAllRoomSync();
    } else {
      throw Exception(
        "Cant handle all room close: isLocal: $isLocal updater: $_updater, _localUpdater: $_localUpdater,",
      );
    }
  }

  Future<List<Room>> getRooms({
    int limit = 50,
    int offset = 0,
    int timelineLimit = 20,
  }) async {
    if (_updater == null) {
      return Future.value([]);
    }
    final update = await _updater!.loadRooms(limit, offset, timelineLimit);
    return update?.deltaData?.toList() ?? [];
  }

  Future<Iterable<RoomEvent>> getAllFakeMessages() {
    if (isLocal == true && _localUpdater != null) {
      return _localUpdater!.getAllFakeMessages();
    } else if (isLocal == false && _updater != null) {
      return _updater!.getAllFakeMessages();
    } else {
      throw Exception(
        "Cant handle getAllFakeMessages isLocal: $isLocal updater: $_updater, _localUpdater: $_localUpdater,",
      );
    }
  }

  Future<Room?> getRoomFromDB({
    required String roomID,
    int limit = 20,
  }) async {
    if (_updater == null) {
      return Future.value(null);
    }
    return _updater!.fetchRoomFromDB(roomID);
  }

  Future<Room?> getRoomFromNetwork({
    required String roomID,
    int limit = 20,
  }) async {
    if (_updater == null) {
      return Future.value(null);
    }
    if (_homeServer == null) {
      throw Exception("HomeServer is null $_homeServer");
    }

    final body = await homeServer!.api.rooms.messages(
      accessToken: _updater!.user.accessToken ?? '',
      roomId: roomID,
      limit: limit,
      from: '',
      filter: {
        'lazy_load_members': true,
      },
    );

    final receivedTimeline = Timeline.fromJson(
      (body['chunk'] as List<dynamic>).cast(),
      context:
          RoomContext.inherit(_updater!.user.context!, roomId: RoomId(roomID)),
      previousBatch: body['end'],
      previousBatchSetBySync: false,
    );

    final newRoom = Room(
      context: _updater!.user.context!,
      id: RoomId(roomID),
      timeline: receivedTimeline,
      memberTimeline: MemberTimeline.fromEvents([
        ...receivedTimeline,
        ...(body['state'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map((e) => RoomEvent.fromJson(e, roomId: RoomId(roomID))!),
      ]),
    );
    await _updater?.saveRoomToDB(newRoom);

    return newRoom;
  }

  //sync data is send to updater's 'updates' stream
  //sync token is send to updater's 'outSyncToken' stream
  Future<void> runSyncOnce({required SyncFilter filter}) async {
    if (_updater == null) {
      return Future.value(null);
    }
    await _updater!.runSyncOnce(filter);
  }

  Stream<SyncToken>? get outSyncToken => _updater?.outSyncToken;
}
