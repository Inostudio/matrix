// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:image/image.dart';
import 'package:matrix_sdk/src/model/sync_token.dart';
import 'package:matrix_sdk/src/services/local/sync_storage.dart';
import 'package:matrix_sdk/src/services/network/base_network.dart';
import 'package:matrix_sdk/src/updater/syncer.dart';
import 'package:matrix_sdk/src/util/logger.dart';
import 'package:matrix_sdk/src/util/subscription.dart';
import 'package:mime/mime.dart';
import 'package:synchronized/synchronized.dart';

import '../event/ephemeral/ephemeral_event.dart';
import '../event/event.dart';
import '../event/room/message_event.dart';
import '../event/room/redaction_event.dart';
import '../event/room/room_event.dart';
import '../event/room/state/state_event.dart';
import '../homeserver.dart';
import '../model/models.dart';
import '../room/member/member_timeline.dart';
import '../room/member/membership.dart';
import '../room/room.dart';
import '../room/rooms.dart';
import '../room/timeline.dart';
import '../services/local/base_sync_storage.dart';
import '../services/network/home_server_network.dart';
import '../store/store.dart';
import '../util/random.dart';
import 'isolated/iso_merge.dart';

/// Manages updates to [MyUser].
class Updater {
  static final _register = <UserId, Updater>{};

  static Updater? get(UserId id) {
    return _register[id];
  }

  static void register(UserId id, Updater updater) {
    _register[id] = updater;
  }

  final Homeserver homeServer;

  late BaseNetwork _networkService;
  late BaseSyncStorage _syncStorage;

  /// Most up to date instance of our user.
  MyUser get user => _user;

  MyUser _user;
  String? _currentSyncToken;
  final int timelineLimit;

  late final Syncer _syncer = Syncer(this);

  Syncer get syncer => _syncer;

  final _lock = Lock();

  Map<String, StreamSubscription<Room>> roomIdToSyncSubscription = {};
  final Map<String, StreamController<Room>> _roomIdToSyncController = {};

  final _updatesSubject = StreamController<Update>.broadcast();

  Stream<Update> get updates => _updatesSubject.stream;

  final _errorSubject = StreamController<ErrorWithStackTraceString>.broadcast();

  Stream<ErrorWithStackTraceString> get outError => _errorSubject.stream;

  Sink<ErrorWithStackTraceString> get inError => _errorSubject.sink;

  final _tokenSubject = StreamController<SyncToken>.broadcast();

  Stream<SyncToken> get outSyncToken => _tokenSubject.stream;

  Stream<ApiCallStatistics> get outApiCallStatistics =>
      homeServer.outApiCallStats;

  bool get isReady => _syncStorage.isReady() && !_updatesSubject.isClosed;

  final bool initSyncStorage;

  /// Initializes the [myUser] with a valid [Context], and will also
  /// initialize it's properties that need the context, such as [Rooms].
  ///
  /// Will also make the [_store] ready to use.
  Updater(
    this._user,
    this.homeServer,
    StoreLocation storeLocation, {
    this.initSyncStorage = false,
    required this.timelineLimit,
  }) {
    Updater.register(_user.id, this);
    _initHomeServer();
    _syncStorage = SyncStorage(storeLocation: storeLocation);

    if (initSyncStorage) {
      _initSyncStorage();
    }
  }

  void _initHomeServer() {
    _networkService = HomeServerNetworking(homeServer: homeServer);
  }

  void _initSyncStorage() {
    _syncStorage.myUserStorageSync(timelineLimit: timelineLimit).listen(
          (storeUpdate) => _notifyWithUpdate(
            storeUpdate,
            SyncUpdate.new,
          ),
        );
  }

  Future<bool> ensureReady() async {
    return (await _syncStorage.ensureOpen()) && isReady;
  }

  Stream<Room> startRoomSync(String roomId) {
    if (!_roomIdToSyncController.keys.contains(roomId)) {
      _roomIdToSyncController[roomId] = StreamController<Room>.broadcast();
    }

    roomIdToSyncSubscription[roomId] = _syncStorage
        .roomStorageSync(
          selectedRoomId: roomId,
          userId: user.id,
          context: user.context,
        )
        .listen((room) => _updateOneRoomSync(roomId, room));
    return _getOneRoomUpdates(roomId);
  }

  void _updateOneRoomSync(String roomId, Room room) {
    if (!_roomIdToSyncController.keys.contains(roomId)) {
      _roomIdToSyncController[roomId] = StreamController<Room>.broadcast();
    }
    _roomIdToSyncController[roomId]!.add(room);
  }

  Stream<Room> _getOneRoomUpdates(String roomId) {
    if (!_roomIdToSyncController.keys.contains(roomId)) {
      _roomIdToSyncController[roomId] = StreamController<Room>.broadcast();
    }
    return _roomIdToSyncController[roomId]!.stream;
  }

  Future<Room?> fetchRoomFromDB(
    String roomId, {
    Context? context,
    List<UserId>? memberIds,
  }) async {
    return _syncStorage.getRoom(
      RoomId(roomId),
      context: context ?? user.context,
      memberIds: memberIds ?? [user.id],
    );
  }

  Future<bool> closeRoomSync(String roomId) async {
    try {
      final res = await closeOneSubInMap(roomIdToSyncSubscription, roomId);
      roomIdToSyncSubscription.remove(roomId);
      await _roomIdToSyncController[roomId]?.close();
      _roomIdToSyncController.remove(roomId);
      return res;
    } catch (e) {
      Log.writer.log("closeRoomSync", e.toString());
      return false;
    }
  }

  Future<bool> closeAllRoomSync() async {
    try {
      final res = await closeAllSubInMap(roomIdToSyncSubscription);
      roomIdToSyncSubscription.clear();
      await doAsyncAllSubInMap<String, StreamController<Room>>(
        _roomIdToSyncController,
        (e) => e.value.close(),
      );
      _roomIdToSyncController.clear();
      return res;
    } catch (e) {
      Log.writer.log("closeAllRoomSync", e.toString());
      return false;
    }
  }

  Future<void> saveRoomToDB(Room room) => _syncStorage.setRoom(room);

  Future<List<String?>?> getRoomIDs() => _syncStorage.getRoomIds();

  Future<void> startSync({
    Duration maxRetryAfter = const Duration(seconds: 30),
    int timelineLimit = 30,
    String? syncToken,
  }) async {
    String? token = syncToken ?? _currentSyncToken;
    if (token == null || token.isEmpty) {
      token = await _syncStorage.getToken();
    }

    await _syncer.start(
      maxRetryAfter: maxRetryAfter,
      timelineLimit: timelineLimit,
      syncToken: token,
      withLoadFakes: true,
    );
  }

  Future<void> stopSync() async => _syncer.stop();

  Future<SyncToken?> runSyncOnce(SyncFilter filter) async =>
      _syncer.runSyncOnce(
        filter: filter,
      );

  ///Notify out sync with new update with data
  Future<void> _notifyWithUpdate<U extends Update>(
    MyUser delta,
    U Function(MyUser user, MyUser delta) createUpdate,
  ) async {
    _user = await runComputeMerge(_user, delta);
    final update = createUpdate(_user, delta);
    _updatesSubject.add(update);
  }

  /// Send out an update, with a new user which is the current [user]
  /// merged with [delta].
  Future<U> _createUpdate<U extends Update>(
    MyUser delta,
    U Function(MyUser user, MyUser delta) createUpdate, {
    bool withSaveInStore = false,
  }) async {
    return _lock.synchronized(() async {
      _user = await runComputeMerge(_user, delta);
      if (withSaveInStore) {
        //TODO add comparing user with delta to avoid save duplicate
        await _syncStorage.setUserDelta(delta.copyWith(id: _user.id));
      }
      return createUpdate(_user, delta);
    });
  }

  Future<RequestUpdate<MemberTimeline>?> kick(
    UserId id, {
    required RoomId from,
  }) async {
    if (_user.rooms?[from]?.members?[id]?.membership == Membership.kicked) {
      return RequestUpdate.fromUpdate(
        await _getRelevantUpdate(),
        data: (u) => u.rooms?[from]?.memberTimeline,
        deltaData: (u) => u.rooms?[from]?.memberTimeline,
        type: RequestType.kick,
      );
    }

    await _networkService.kickFromRoom(
      accessToken: _user.accessToken!,
      roomId: from.toString(),
      userId: id.toString(),
    );

    return RequestUpdate.fromUpdate(
      await _getRelevantUpdate(
        firstWhere: (u) =>
            u.delta.rooms?[from]?.members?.current.kicked.any(
              (m) => m.id == id,
            ) ??
            false,
      ),
      data: (u) => u.rooms?[from]?.memberTimeline,
      deltaData: (u) => u.rooms?[from]?.memberTimeline,
      type: RequestType.kick,
    );
  }

  //Perform [send] request and then mapping it's stream into Update
  Stream<RequestUpdate<Timeline>?> makeTimeLineFromSend(
    RoomId roomId,
    EventContent content, {
    Room? room,
    String? transactionId,
    String stateKey = '',
    String type = '',
  }) async* {
    send(
      roomId,
      content,
      room: room,
      transactionId: transactionId,
      stateKey: stateKey,
      type: type,
    ).map(
      (event) async {
        if (event == null) {
          return null;
        }

        final Room? currentRoom = room ??= _user.rooms![roomId];

        final timelineDelta = currentRoom?.timeline?.delta(
          events: [event],
        );
        if (timelineDelta == null) {
          return null;
        }

        final roomDelta = currentRoom?.delta(
          timeline: timelineDelta,
        );

        if (roomDelta == null) {
          return null;
        }

        return _createUpdate(
          _user.delta(rooms: [roomDelta]),
          (user, delta) => RequestUpdate(
            user,
            delta,
            data: currentRoom?.timeline,
            deltaData: currentRoom?.timeline,
            type: RequestType.sendRoomEvent,
          ),
        );
      },
    );
  }

  Future<RoomEvent?> sendReadyEvent(
    RoomEvent roomEvent, {
    required bool isState,
  }) async {
    if (roomEvent.content != null ||
        roomEvent.transactionId == null ||
        roomEvent.roomId == null) {
      return null;
    } else {
      try {
        final eventArgs = RoomEventArgs(
          networkId: roomEvent.transactionId!,
          id: EventId(roomEvent.transactionId!),
          roomId: roomEvent.roomId,
          time: DateTime.now(),
          senderId: _user.id,
          sentState: SentState.unsent,
          transactionId: roomEvent.transactionId,
        );

        final fileEvent = await _handleSendFile(roomEvent, eventArgs);
        if (fileEvent != null) {
          roomEvent = fileEvent;
        }

        final Map<String, dynamic> body =
            await _sendRoomNetwork(roomEvent, roomEvent.roomId!);
        final eventId = EventId(body['event_id']);

        final sentEvent = RoomEvent.fromContent(
          roomEvent.content!,
          eventArgs.copyWith(
            id: eventId,
            sentState: SentState.sent,
          ),
          type: roomEvent.type,
          isState: isState,
        );

        return sentEvent;
      } catch (e) {
        final eventArgs = RoomEventArgs(
          networkId: roomEvent.transactionId!,
          id: EventId(roomEvent.transactionId!),
          roomId: roomEvent.roomId,
          time: DateTime.now(),
          senderId: _user.id,
          sentState: SentState.unsent,
          transactionId: roomEvent.transactionId,
        );

        final errorEvent = RoomEvent.fromContent(
          roomEvent.content!,
          eventArgs.copyWith(
            id: EventId(roomEvent.transactionId!),
            sentState: SentState.sent,
          ),
          type: roomEvent.type,
          isState: isState,
        );
        return errorEvent;
      }
    }
  }

  Stream<RoomEvent?> send(
    RoomId roomId,
    EventContent content, {
    Room? room,
    String? transactionId,
    String stateKey = '',
    String type = '',
  }) async* {
    transactionId ??= randomString();

    final eventArgs = RoomEventArgs(
      networkId: transactionId,
      id: EventId(transactionId),
      roomId: roomId,
      time: DateTime.now(),
      senderId: _user.id,
      sentState: SentState.unsent,
      transactionId: transactionId,
    );

    var fakeEvent = RoomEvent.fromContent(
      content,
      eventArgs,
      type: type,
      isState: stateKey.isNotEmpty,
    );

    yield fakeEvent;

    if (fakeEvent != null) {
      await _syncStorage.addFakeEvent(fakeEvent);
    }

    if (fakeEvent != null) {
      final fileEvent = await _handleSendFile(fakeEvent, eventArgs);
      if (fileEvent != null) {
        fakeEvent = fileEvent;
      }
    }

    if (fakeEvent == null) {
      return;
    }

    try {
      final Map<String, dynamic> body =
          await _sendRoomNetwork(fakeEvent, roomId);
      final eventId = EventId(body['event_id']);

      final sentEvent = RoomEvent.fromContent(
        content,
        eventArgs.copyWith(
          id: eventId,
          networkId: eventId.value,
          sentState: SentState.sent,
          transactionId: transactionId,
        ),
        type: type,
        isState: stateKey.isNotEmpty,
      );

      yield sentEvent;

      if (fakeEvent.transactionId != null) {
        await _syncStorage.deleteFakeEvent(fakeEvent.transactionId!);
      }
    } catch (e) {
      final eventArgs = RoomEventArgs(
        networkId: transactionId,
        id: EventId(transactionId),
        roomId: roomId,
        time: DateTime.now(),
        senderId: _user.id,
        sentState: SentState.sentError,
        transactionId: transactionId,
      );

      final errorEvent = RoomEvent.fromContent(
        content,
        eventArgs,
        type: type,
        isState: stateKey.isNotEmpty,
      );

      yield errorEvent;
      if (errorEvent != null) {
        await _syncStorage.addFakeEvent(errorEvent);
      }
    }
  }

  Future<Uri?> uploadFile(String fileURI) async {
    final uri = Uri.parse(fileURI);
    final file = File(
      uri.toFilePath(windows: Platform.isWindows),
    );
    final fileName = file.path.split(Platform.pathSeparator).last;
    return _networkService.uploadImage(
      as: _user,
      bytes: file.openRead(),
      length: await file.length(),
      contentType: lookupMimeType(file.path) ?? '',
      fileName: fileName,
    );
  }

  Future<RoomEvent?> _handleSendFile(
    RoomEvent roomEvent,
    RoomEventArgs args,
  ) async {
    // TODO: Support for web
    // Upload images from image message events that have a file uri
    List<File> imgs = [];
    final uploaded = <Uri, Image>{};

    if (roomEvent is TextMessageEvent &&
        (roomEvent.content.attachments?.isNotEmpty ?? false)) {
      imgs.addAll(roomEvent.content.attachments!.map((e) => File(e.imgURL)));
    } else if (roomEvent is ImageMessageEvent &&
        roomEvent.content?.url?.scheme == 'file') {
      final file = File(
        roomEvent.content!.url!.toFilePath(windows: Platform.isWindows),
      );
      imgs = [file];
    }

    for (final file in imgs) {
      final fileName = file.path.split(Platform.pathSeparator).last;
      final matrixUrl = await _networkService.uploadImage(
        as: _user,
        bytes: file.openRead(),
        length: await file.length(),
        contentType: lookupMimeType(file.path) ?? '',
        fileName: fileName,
      );
      final image = decodeImage(file.readAsBytesSync());
      if (matrixUrl != null && image != null) {
        uploaded[matrixUrl] = image;
      }
    }

    if (uploaded.isEmpty) {
      return null;
    }

    if (uploaded.isNotEmpty && roomEvent is TextMessageEvent) {
      final a = <Attachment>[];
      uploaded.forEach((key, value) {
        a.add(Attachment(
            imgURL: key.toString(),
            info: ImageInfo(
              width: value.width,
              height: value.height,
            )));
      });
      return RoomEvent.fromContent(
        TextMessage(
          body: roomEvent.content.body,
          formattedBody: roomEvent.content.formattedBody,
          inReplyToId: roomEvent.content.inReplyToId,
          inReplacementToId: roomEvent.content.inReplacementToId,
          attachments: a,
        ),
        args,
      );
    } else if (roomEvent is ImageMessageEvent) {
      final url = uploaded.keys.first;
      final image = uploaded[url];
      return RoomEvent.fromContent(
        ImageMessage(
          url: url,
          body: roomEvent.content!.body,
          inReplyToId: roomEvent.content!.inReplyToId,
          info: ImageInfo(
            width: image?.width ?? 0,
            height: image?.height ?? 0,
          ),
        ),
        args,
        type: "",
      );
    }
    return null;
  }

  Future<Map<String, dynamic>> _sendRoomNetwork(
    RoomEvent roomEvent,
    RoomId roomId,
  ) async {
    Map<String, dynamic> body;

    if (roomEvent is StateEvent) {
      body = await _networkService.sendRoomsState(
        accessToken: _user.accessToken!,
        roomId: roomId.toString(),
        eventType: roomEvent.type,
        stateKey: roomEvent.stateKey ?? "",
        content: roomEvent.content?.toJson() ?? {},
      );
    } else {
      body = await _networkService.roomsSend(
        accessToken: _user.accessToken!,
        roomId: roomId.toString(),
        eventType: roomEvent.type,
        transactionId: roomEvent.transactionId ?? "",
        content: roomEvent.content?.toJson() ?? {},
      );
    }
    return body;
  }

  Future<RequestUpdate<Timeline>?> edit(
    RoomId roomId,
    TextMessageEvent event,
    String newContent, {
    Room? room,
    String? transactionId,
  }) async {
    final Room? currentRoom = room ??=
        _user.rooms?.firstWhereOrNull((element) => element.id == roomId);

    if (currentRoom == null) {
      throw ArgumentError('Room not found in users list');
    }

    transactionId ??= randomString();

    await _networkService.roomEdit(
      accessToken: _user.accessToken ?? "",
      roomId: roomId.value,
      transactionId: transactionId,
      event: event,
      newContent: newContent,
    );

    final relevantUpdate = await updates.cast<Update?>().firstWhere(
            (update) => update?.delta.rooms?[roomId] != null,
            orElse: () => null) ??
        await _getRelevantUpdate();

    return _createUpdate(
      relevantUpdate.delta,
      (user, delta) => RequestUpdate(
        user,
        delta,
        data: user.rooms?[roomId]?.timeline,
        deltaData: delta.rooms?[roomId]?.timeline,
        type: RequestType.sendRoomEvent,
        basedOnUpdate: true,
      ),
    );
  }

  Future<RequestUpdate<Timeline>?> delete(
    RoomId roomId,
    EventId eventId, {
    String? transactionId,
    String? reason,
    Room? room,
  }) async {
    final Room? currentRoom = room ??=
        _user.rooms?.firstWhereOrNull((element) => element.id == roomId);

    if (currentRoom == null) {
      throw ArgumentError('Room not found in users list');
    }

    transactionId ??= randomString();

    await _networkService.roomsRedact(
      accessToken: _user.accessToken ?? '',
      roomId: roomId.value,
      eventId: eventId.value,
      transactionId: transactionId,
      reason: reason,
    );

    final relevantUpdate = await updates.cast<Update?>().firstWhere(
              (update) =>
                  update?.delta.rooms?[roomId]?.timeline?.toList().any(
                      (element) =>
                          element is RedactionEvent &&
                          element.redacts == eventId) ==
                  true,
              orElse: () => null,
            ) ??
        await _getRelevantUpdate();

    return _createUpdate(
      relevantUpdate.delta,
      (user, delta) => RequestUpdate(
        user,
        delta,
        data: user.rooms?[roomId]?.timeline,
        deltaData: delta.rooms?[roomId]?.timeline,
        type: RequestType.sendRoomEvent,
        basedOnUpdate: true,
      ),
    );
  }

  Future<RequestUpdate<ReadReceipts>?> markRead({
    required RoomId roomId,
    required EventId until,
    bool fullyRead = true,
    bool receipt = true,
    Room? room,
  }) async {
    if (receipt) {
      final Room? currentRoom = room ??=
          _user.rooms?.firstWhereOrNull((element) => element.id == roomId);
      final isReadAlready = currentRoom?.readReceipts.any(
            (receipt) => receipt.eventId == until && receipt.userId == _user.id,
          ) ??
          false;

      if (isReadAlready) {
        return RequestUpdate.fromUpdate(
          await _getRelevantUpdate(),
          data: (u) => u.rooms?[roomId]?.readReceipts,
          deltaData: (u) => u.rooms?[roomId]?.readReceipts,
          type: RequestType.markRead,
        );
      }
    }

    await _networkService.setRoomsReadMarkers(
      accessToken: _user.accessToken!,
      roomId: roomId.toString(),
      fullyRead: fullyRead ? until.toString() : null,
      read: receipt ? until.toString() : null,
    );

    return RequestUpdate.fromUpdate(
      await _getRelevantUpdate(),
      data: (u) => u.rooms?[roomId]?.readReceipts,
      deltaData: (u) => u.rooms?[roomId]?.readReceipts,
      type: RequestType.markRead,
    );
  }

  Future<RequestUpdate<MyUser>?> logout() async {
    await syncer.stop();
    await _networkService.logout(accessToken: _user.accessToken!);

    final update = await _createUpdate(
      _user.delta(isLoggedOut: true),
      (user, delta) => RequestUpdate(
        user,
        delta,
        data: user,
        deltaData: delta,
        type: RequestType.logout,
        basedOnUpdate: true,
      ),
    );

    await _syncStorage.wipeAllData();

    await _syncStorage.close();

    return update;
  }

  Future<void> close() async {
    await doAsyncAllSubInMap<String, StreamController<Room>>(
      _roomIdToSyncController,
      (e) => e.value.close(),
    );
    _roomIdToSyncController.clear();
    await _errorSubject.close();
    await _tokenSubject.close();
    await _updatesSubject.close();
  }

  Future<RequestUpdate<Rooms>?> loadRooms(
    int limit,
    int offset,
    int timelineLimit,
  ) async {
    final rooms = await _syncStorage.getRooms(
      timelineLimit: timelineLimit,
      context: _user.context!,
      memberIds: [_user.id],
      limit: limit,
      offset: offset,
    );

    final update = RequestUpdate(
      _user,
      _user.delta(rooms: rooms),
      data: Rooms(rooms, context: _user.context),
      deltaData: Rooms(rooms, context: _user.context),
      type: RequestType.loadRooms,
    );

    _updatesSubject.add(update);

    return update;
  }

  Future<RequestUpdate<Timeline>?> loadRoomEvents({
    required RoomId roomId,
    int count = 20,
    Room? room,
  }) async {
    final Room? currentRoom = room ??=
        _user.rooms?.firstWhereOrNull((element) => element.id == roomId);

    if (currentRoom?.timeline == null) {
      return Future.value(null);
    }

    final body = await _networkService.getRoomMessages(
      accessToken: _user.accessToken ?? '',
      roomId: roomId.toString(),
      limit: count,
      from: currentRoom?.timeline?.previousBatch ?? '',
      filter: {
        'lazy_load_members': true,
      },
    );

    final timeline = Timeline.fromJson(
      (body['chunk'] as List<dynamic>).cast(),
      context: currentRoom?.context,
      previousBatch: body['end'],
      startBatch: body['start'],
      previousBatchSetBySync: false,
    );

    final memberTimeline = MemberTimeline.fromEvents([
      ...timeline,
      if (body.containsKey('state'))
        ...(body['state'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map((e) => RoomEvent.fromJson(e, roomId: roomId)!),
    ]);

    final newRoom = Room(
      context: _user.context!,
      id: currentRoom!.id,
      timeline: timeline,
      memberTimeline: memberTimeline,
    );

    return _createUpdate(
      _user.delta(rooms: [newRoom]),
      withSaveInStore: true,
      (user, delta) => RequestUpdate(user, delta,
          data: user.rooms?[newRoom.id]?.timeline,
          deltaData: delta.rooms?[newRoom.id]?.timeline,
          type: RequestType.loadRoomEvents,
          basedOnUpdate: true),
    );
  }

  Future<Iterable<RoomEvent>> getAllFakeMessages() {
    return _syncStorage.getAllFakeEvents();
  }

  Future<bool> deleteFakeEvent(String transactionId) {
    return _syncStorage.deleteFakeEvent(transactionId);
  }

  Future<RequestUpdate<EphemeralEventFull>?> setIsTyping({
    required RoomId roomId,
    required bool isTyping,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    await _networkService.setRoomTyping(
      accessToken: _user.accessToken ?? '',
      roomId: roomId.toString(),
      userId: _user.id.toString(),
      typing: isTyping,
      timeout: timeout.inMilliseconds,
    );

    final updates = _user.context?.updater?.updates;

    if (updates == null) {
      return null;
    } else {
      return RequestUpdate.fromUpdate(
        await _getRelevantUpdate(
          firstWhere: (u) {
            final containsMe = u
                .delta.rooms?[roomId]?.ephemeral?.typingEvents.content?.typerIds
                .whereNotNull()
                .contains(_user.id);
            return containsMe == null
                ? false
                : isTyping
                    ? containsMe
                    : !containsMe;
          },
        ),
        data: (u) => u.rooms?[roomId]?.ephemeral!,
        deltaData: (u) => u.rooms?[roomId]?.ephemeral,
        type: RequestType.setIsTyping,
      );
    }
  }

  Future<RequestUpdate<Room>?> joinRoom({
    RoomId? id,
    RoomAlias? alias,
    required Uri serverUrl,
  }) async {
    final body = await _networkService.joinToRoom(
      accessToken: _user.accessToken ?? '',
      roomIdOrAlias: id?.toString() ?? alias?.toString() ?? '',
      serverName: serverUrl.host,
    );

    final roomId = RoomId(body['room_id']);

    return RequestUpdate.fromUpdate(
      await _getRelevantUpdate(
        firstWhere: (u) =>
            u.user.rooms?[roomId]?.me?.membership == Membership.joined,
      ),
      data: (u) => u.rooms?[roomId],
      deltaData: (u) => u.rooms?[roomId],
      type: RequestType.joinRoom,
    );
  }

  Future<RequestUpdate<Room>?> leaveRoom(RoomId id) async {
    await _networkService.leaveRoom(
      accessToken: _user.accessToken ?? '',
      roomId: id.toString(),
    );

    return RequestUpdate.fromUpdate(
      await _getRelevantUpdate(
        firstWhere: (u) => u.delta.rooms?[id]?.me?.hasLeft ?? false,
      ),
      data: (u) => u.rooms?[id],
      deltaData: (u) => u.rooms?[id],
      type: RequestType.leaveRoom,
    );
  }

  /// Note: Will return RequestUpdate<Pushers> in the future.
  Future<bool?> setPusher(Map<String, dynamic> pusher) async {
    final pusherIsSet = await _networkService.setPusher(
      accessToken: _user.accessToken ?? '',
      body: pusher,
    );

    return pusherIsSet;
  }

  Future<SyncUpdate?> processSync(Map<String, dynamic> body) async {
    final roomDeltas = await _processRooms(body);

    String? syncToken;

    final String? nextToken = body["next_batch"];
    if (nextToken != null && nextToken.isNotEmpty) {
      syncToken = nextToken;
    }

    if (roomDeltas.isNotEmpty ||
        (syncToken != null &&
            syncToken.isNotEmpty &&
            syncToken != _currentSyncToken)) {
      _currentSyncToken = syncToken;

      return _createUpdate(
        _user.delta(
          syncToken: body['next_batch'],
          rooms: roomDeltas,
          hasSynced: !(_user.hasSynced ?? false) ? true : null,
        ),
        SyncUpdate.new,
        withSaveInStore: true,
      );
    }
    return null;
  }

  ///Get last update
  ///if store is synchronized return last from [update]
  ///else - perform request to db
  Future<Update> _getRelevantUpdate({
    Function(Update)? firstWhere,
  }) async {
    if (initSyncStorage) {
      return firstWhere == null
          ? updates.first
          : updates.firstWhere((e) => firstWhere(e));
    } else {
      final update = await _syncStorage.getMyUser();
      return _createUpdate(
        update ?? user,
        (user, delta) => RequestUpdate(
          user,
          delta,
          data: user,
          deltaData: delta,
          type: RequestType.logout,
          basedOnUpdate: true,
        ),
      );
    }
  }

  /// Returns list of room delta.
  Future<List<Room>> _processRooms(Map<String, dynamic> body) async {
    final jRooms = body['rooms'];

    const join = 'join';
    const invite = 'invite';
    const leave = 'leave';

    Future<List<Room>?> process(
      Map<String, dynamic>? rooms, {
      required String type,
    }) async {
      final roomDeltas = <Room>[];

      if (rooms != null) {
        for (final entry in rooms.entries) {
          final roomId = RoomId(entry.key);
          final json = entry.value;

          var currentRoom = _user.rooms?[roomId];

          /// Room is from store or newly joined/invited.
          var isNewRoom = false;
          if (currentRoom == null) {
            isNewRoom = true;
            currentRoom = user.rooms?[roomId] ??
                await _syncStorage.getRoom(
                  roomId,
                  context: _user.context!,
                  memberIds: [_user.id],
                ) ??
                Room.base(
                  context: Context(myId: _user.id),
                  id: roomId,
                );
          }

          var roomDelta = Room.fromJson(json, context: currentRoom.context!);

          // Set previous batch to null if it wasn't set by sync before
          if (!(currentRoom.timeline?.previousBatchSetBySync ?? true)) {
            roomDelta = roomDelta.copyWith(
              // We can't use copyWith because we're setting previousBatch to
              // null again
              timeline: Timeline(
                roomDelta.timeline!,
                context: roomDelta.context,
                previousBatch: null,
                previousBatchSetBySync: false,
              ),
            );
          }

          final accountData = body['account_data'];
          // Process account data
          if (accountData != null) {
            final events = accountData['events'] as List<dynamic>;

            final event = events.firstWhere(
              (event) => event['type'] == 'm.direct',
              orElse: () => null,
            );

            if (event != null) {
              final content = event['content'] as Map<String, dynamic>;

              for (final entry in content.entries) {
                final userId = entry.key;
                final roomIds = entry.value;

                if (UserId.isValidFullyQualified(userId) &&
                    roomIds.contains(roomId.toString())) {
                  roomDelta = roomDelta.copyWith(directUserId: UserId(userId));
                  break;
                }
              }
            }
          }

          if (isNewRoom) {
            roomDelta = currentRoom.merge(roomDelta);
          }

          roomDeltas.add(roomDelta);
        }

        return roomDeltas;
      }

      return null;
    }

    final joins =
        jRooms == null ? [] : ((await process(jRooms[join], type: join)) ?? []);
    final invites = jRooms == null
        ? []
        : ((await process(jRooms[invite], type: invite)) ?? []);
    final leaves = jRooms == null
        ? []
        : ((await process(jRooms[leave], type: leave)) ?? []);
    return [
      ...joins,
      ...invites,
      ...leaves,
    ];
  }
}
