import 'dart:async';

import 'package:collection/collection.dart';
import 'package:matrix_sdk/matrix_sdk.dart';
import 'package:matrix_sdk/src/updater/isolated/isolated_updater.dart';
import 'package:matrix_sdk/src/util/logger.dart';

import 'model/sync_token.dart';

class MatrixClient {
  final bool isIsolated;
  final bool withDebugLog;
  final Uri serverUri;
  final Homeserver _homeServer;
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

  MatrixClient({
    this.isIsolated = true,
    this.withDebugLog = false,
    required this.serverUri,
    required StoreLocation storeLocation,
  })  : _homeServer = Homeserver(serverUri),
        _storeLocation = storeLocation {
    Log.setLogger(withDebugLog ? LoggerVariant.dev : LoggerVariant.none);
  }

  Homeserver get homeServer => _homeServer;

  /// Get all invites for this user. Note that for now this will load
  /// all rooms to memory.
  /*Future<List<Invite>> get invites async =>
      (await _rooms.get(where: (r) => r is InvitedRoom))
          .map((r) => Invite._(scope, r))
          .toList(growable: false);*/

  Future<MyUser> login(
    UserIdentifier user,
    String password, {
    Device? device,
  }) async {
    _streamSubscription
        .add(_homeServer.outApiCallStats.listen(_apiCallStatsSubject.add));
    final result = await _homeServer.login(
      user,
      password,
      device: device,
    );

    if (isIsolated) {
      _updater = await IsolatedUpdater.create(
        result,
        _homeServer,
        _storeLocation,
        saveMyUserToStore: isIsolated,
      );
    } else {
      _updater = Updater(
        result,
        _homeServer,
        _storeLocation,
        initSinkStorage: !isIsolated,
      );
    }

    if (_updater != null) {
      await _updater!.ensureReady();

      _streamSubscription.add(_updater!.updates.listen(_updatesSubject.add));
      _streamSubscription
          .add(_updater!.outApiCallStatistics.listen(_apiCallStatsSubject.add));
      _streamSubscription.add(_updater!.outError.listen(_errorSubject.add));
    }

    return result;
  }

  /// Invalidates the access token of the user. Makes all
  /// [MyUser] calls unusable.
  ///
  /// Returns the [Update] where [MyUser] has logged out, if successful.
  Future<RequestUpdate<MyUser>?> logout() async {
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

  Future<void> stopSync() async {
    _streamSubscription.forEach((e) {
      e.cancel();
    });
    _streamSubscription.clear();
    await _updater?.stopSync();
  }

  Future<Room?> getRoom({
    required String roomID,
    int limit = 20,
  }) async {
    if (_updater == null) {
      return Future.value(null);
    }
    final update = await _updater!.loadRoomsByIDs([RoomId(roomID)], limit);
    return update?.data?.firstWhereOrNull((e) => e.id.value == roomID);
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

  @Deprecated("Use [uotUpdates instead]")
  Future<List<Room?>> getRoomsByIDs({
    required Iterable<RoomId> roomIDs,
    int limit = 40,
    int offset = 0,
    int timelineLimit = 20,
  }) async {
    if (_updater == null) {
      return Future.value([]);
    }
    final update = await _updater!.loadRoomsByIDs(roomIDs, timelineLimit);
    return update?.data?.toList() ?? [];
  }

  @Deprecated("Use [uotUpdates instead]")
  Future<Room?> loadRoomEvents({
    required String roomID,
    int limit = 20,
  }) async {
    if (_updater == null) {
      return Future.value(null);
    }

    final body = await homeServer.api.rooms.messages(
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
  @Deprecated("Remove later")
  Future<void> runSyncOnce({required SyncFilter filter}) async {
    if (_updater == null) {
      return Future.value(null);
    }
    await _updater!.runSyncOnce(filter);
  }

  Stream<SyncToken>? get outSyncToken => _updater?.outSyncToken;

  @Deprecated("Remove later")
  Future<List<String?>> getRoomIDs() async {
    final result = await _updater?.getRoomIDs();
    return result ?? [];
  }
}
