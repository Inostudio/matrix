// Copyright (C) 2020  Mathieu Velten
// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

library matrix_sdk_moor;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:drift/backends.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:rxdart/rxdart.dart';

import '../../../matrix_sdk.dart';
import '../../event/ephemeral/ephemeral_event.dart';
import '../../event/ephemeral/typing_event.dart';
import '../../event/room/state/request_type.dart';
import '../../model/context.dart';
import 'database.dart' hide Rooms;

class MoorStore extends Store {
  final DelegatedDatabase _executor;

  MoorStore(this._executor);

  bool _isOpen = false;

  @override
  bool get isOpen => _isOpen;

  Database? _db;

  @override
  Future<void> open() async {
    if (!isOpen) {
      _db = Database(_executor);
      _isOpen = true;
      await ensureOpen();
    }
  }

  @override
  Future<bool> ensureOpen() async {
    if (_db == null) {
      return false;
    }
    return _executor.ensureOpen(_db!);
  }

  @override
  Future<void> close() async {
    await _db?.close();
    _db = null;
    _isOpen = false;
  }

  // Keep track of the invites to delete invite state when the room is joined
  final _invites = <RoomId>{};

  void _setInvites(Iterable<Room?> rooms) {
    _invites.addAll(
      rooms
          .where((room) => room?.me?.membership == Membership.invited)
          .whereNotNull()
          .map((r) => r.id),
    );
  }

  @override
  Stream<Room> roomStorageSync({
    required String selectedRoomId,
    required UserId userId,
    Context? context,
  }) =>
      _db!
          .selectRoomRecordsByIDs([selectedRoomId])
          .watchSingleOrNull()
          .debounceTime(Duration(milliseconds: 200))
          .where((event) => event != null)
          .cast<RoomRecordWithStateRecords>()
          .asyncMap(
            (record) async {
              final roomId = RoomId(selectedRoomId);
              final roomRecord = record.roomRecord;

              final roomContext = context != null
                  ? RoomContext.inherit(
                      context,
                      roomId: RoomId(roomRecord.id),
                    )
                  : null;

              final ephemeralResult = await _db!.getEphemeralEventRecords(
                selectedRoomId,
              );
              final ephemeral = EphemeralEventFull(
                roomId: roomId,
                typingEvents: ephemeralResult.getTypingEvent(),
                receiptEvents: ephemeralResult.getReceiveEvent(),
                context: roomContext,
              );

              final messageEventResult = await getRoomEventsWithIDs(
                [roomRecord.id],
                inTimeLine: null, //get all
                memberIds: [userId],
                requestType: RoomEventRequestType.all,
              ).then((value) => value.toList());

              final relevantUserIds = messageEventResult
                  .whereNotNull()
                  .map((e) =>
                      [e.senderId, if (e is MemberChangeEvent) e.subjectId])
                  .expand((ids) => ids)
                  .map((e) => e.value);

              final uniqueUserIDs = {...relevantUserIds, userId.value};
              final members = await getMessagesMembersWithIds(
                roomIds: [roomRecord.id],
                userIds: uniqueUserIDs,
              );

              final timeline = Timeline(
                messageEventResult,
                context: roomContext,
                previousBatch: roomRecord.timelinePreviousBatch,
                previousBatchSetBySync:
                    roomRecord.timelinePreviousBatchSetBySync,
              );

              final memberTimeline = MemberTimeline(
                members,
                context: roomContext,
              );

              return Room(
                context: context,
                id: RoomId(roomRecord.id),
                stateEvents: RoomStateEvents(
                  nameChange: record.nameChangeRecord?.toRoomEvent(),
                  avatarChange: record.avatarChangeRecord?.toRoomEvent(),
                  topicChange: record.topicChangeRecord?.toRoomEvent(),
                  powerLevelsChange:
                      record.powerLevelsChangeRecord?.toRoomEvent(),
                  joinRulesChange: record.joinRulesChangeRecord?.toRoomEvent(),
                  canonicalAliasChange:
                      record.canonicalAliasChangeRecord?.toRoomEvent(),
                  creation: record.creationRecord?.toRoomEvent(),
                  upgrade: record.upgradeRecord?.toRoomEvent(),
                ),
                timeline: timeline,
                memberTimeline: memberTimeline,
                summary: RoomSummary(
                  joinedMembersCount: roomRecord.summaryJoinedMembersCount,
                  invitedMembersCount: roomRecord.summaryInvitedMembersCount,
                ),
                directUserId: roomRecord.directUserId != null
                    ? UserId(roomRecord.directUserId!)
                    : null,
                highlightedUnreadNotificationCount:
                    roomRecord.highlightedUnreadNotificationCount,
                totalUnreadNotificationCount:
                    roomRecord.totalUnreadNotificationCount,
                ephemeral: ephemeral,
              );
            },
          );

  @override
  Stream<MyUser> myUserStorageSync({
    Iterable<RoomId>? roomIds,
    int timelineLimit = 100,
  }) {
    return _db!
        .getUserSync()
        .where((userRecord) => userRecord != null)
        .cast<MyUserRecordWithDeviceRecord>()
        .asyncMap(
          (user) async => _userRecordToUser(
            user,
            roomIds: roomIds,
            timelineLimit: timelineLimit,
          ),
        );
  }

  @override
  Future<String?> getToken() async => _db!.getUserSyncToken();

  /// If [isolated] is true, will create an [IsolatedUpdater] to manage
  /// the user's updates.
  @override
  Future<MyUser?> getMyUser({
    Iterable<RoomId>? roomIds,
    int timelineLimit = 100,
  }) async {
    final myUserWithDeviceRecord = await _db!.getMyUserRecord();

    if (myUserWithDeviceRecord == null) {
      return null;
    }
    return _userRecordToUser(
      myUserWithDeviceRecord,
      roomIds: roomIds,
      timelineLimit: timelineLimit,
    );
  }

  Future<MyUser> _userRecordToUser(
    MyUserRecordWithDeviceRecord myUserWithDeviceRecord, {
    Iterable<RoomId>? roomIds,
    int timelineLimit = 100,
  }) async {
    final myUserRecord = myUserWithDeviceRecord.myUserRecord;
    final deviceRecord = myUserWithDeviceRecord.deviceRecord;
    final myId = UserId(myUserRecord.id!);
    final context = Context(myId: myId);

    return MyUser(
      id: myId,
      name: myUserRecord.name!,
      avatarUrl: myUserRecord.avatarUrl != null
          ? Uri.parse(myUserRecord.avatarUrl!)
          : null,
      accessToken: myUserRecord.accessToken,
      syncToken: myUserRecord.syncToken!,
      currentDevice: deviceRecord?.toDevice(),
      rooms: Rooms(
        await getRoomsByIDs(
          roomIds,
          timelineLimit: timelineLimit,
          context: context,
          memberIds: [myId],
        ),
        context: context,
      ),
      hasSynced: myUserRecord.hasSynced ?? false,
      isLoggedOut: myUserRecord.isLoggedOut ?? true,
    );
  }

  @override
  //Set data into rooms, than set data into user.
  //Setting data into user trigger user sink, that get all room records
  Future<void> setMyUserDelta(MyUser myUser) async {
    if (myUser.rooms != null) {
      _setInvites(myUser.rooms!);

      final previouslyInvitedIds = myUser.rooms
          ?.where((room) =>
              room.me?.membership == Membership.joined &&
              _invites.contains(room.id))
          .map((room) => room.id.toString())
          .toList();

      if (previouslyInvitedIds?.isNotEmpty == true) {
        await _db?.deleteInviteStates(previouslyInvitedIds!);
      }

      await _db?.setRooms(
        myUser.rooms!.map((r) => r.toCompanion()).whereNotNull().toList(),
      );

      // Set room state
      await _db?.setRoomEventRecords(
        myUser.rooms!
            .map((room) => room.stateEvents)
            .whereNotNull()
            .expand((stateEvents) => [
                  stateEvents.nameChange,
                  stateEvents.avatarChange,
                  stateEvents.topicChange,
                  stateEvents.powerLevelsChange,
                  stateEvents.joinRulesChange,
                  stateEvents.canonicalAliasChange,
                  stateEvents.creation,
                  stateEvents.upgrade,
                ])
            .whereNotNull()
            .map((event) => event.toRecord(inTimeline: false))
            .toList(),
      );

      await _db?.setEphemeralEventRecords(
        myUser.rooms!
            .map((room) => room.ephemeral?.toEventRecord())
            .whereNotNull()
            .toList(),
      );

      await _db?.setEphemeralReceiveEventRecords(
        myUser.rooms!
            .map((room) => room.ephemeral?.toReceiveRecord())
            .whereNotNull()
            .expand((e) => e)
            .toList(),
      );

      // Set member states
      await _db?.setRoomEventRecords(
        myUser.rooms!
            .map((room) => room.memberTimeline?.map((m) => m.event) ?? [])
            .expand((events) => events)
            .whereNotNull()
            .map((event) => event.toRecord(inTimeline: false))
            .toList(),
      );

      // Set timeline. If any of the (member) state events were just set,
      // they'll be overridden with inTimeline = true.
      final eventsList = myUser.rooms!
          .map((room) => room.timeline)
          .whereNotNull()
          .expand((timeline) => timeline)
          .map((event) => event.toRecord(inTimeline: true))
          .toList();
      await _db?.setRoomEventRecords(
        eventsList,
      );

      //Find latest message and save time interval to room
      final Map<String, int> result =
          eventsList.fold(<String, int>{}, (previousValue, element) {
        if (element.time != null) {
          final roomID = element.roomId;
          if (previousValue.containsKey(roomID) &&
              previousValue[roomID] != null) {
            if (previousValue[roomID]! < element.time!.millisecondsSinceEpoch) {
              previousValue[roomID] = element.time!.millisecondsSinceEpoch;
            }
          } else {
            previousValue[roomID] = element.time!.millisecondsSinceEpoch;
          }
        }
        return previousValue;
      });
      if (result.isNotEmpty) {
        await _db?.setRoomsLatestMessages(result);
      }
    }
    await _db?.setMyUser(
      MyUsersCompanion(
        homeserver: myUser.context?.updater?.homeServer != null
            ? Value(myUser.context?.updater?.homeServer.url.toString())
            : Value.absent(),
        id: myUser.id.value.isNotEmpty
            ? Value(myUser.id.toString())
            : Value.absent(),
        name: Value(myUser.name),
        avatarUrl: myUser.avatarUrl != null
            ? Value(myUser.avatarUrl.toString())
            : Value.absent(),
        accessToken:
            myUser.accessToken != null && myUser.accessToken!.isNotEmpty
                ? Value(myUser.accessToken.toString())
                : Value.absent(),
        syncToken:
            myUser.syncToken != null ? Value(myUser.syncToken) : Value.absent(),
        currentDeviceId: myUser.currentDevice?.id != null
            ? Value(myUser.currentDevice?.id.toString())
            : Value.absent(),
        hasSynced:
            myUser.hasSynced != null ? Value(myUser.hasSynced) : Value.absent(),
        isLoggedOut: myUser.isLoggedOut != null
            ? Value(myUser.isLoggedOut)
            : Value.absent(),
      ),
    );

    if (myUser.currentDevice != null) {
      await _db?.setDeviceRecords([myUser.currentDevice!.toCompanion()]);
    }
  }

  @override
  Future<void> setRoom(Room room) async {
    await _db
        ?.setRooms([room].map((r) => r.toCompanion()).whereNotNull().toList());

    // Set room state
    await _db?.setRoomEventRecords(
      [room]
          .map((room) => room.stateEvents)
          .whereNotNull()
          .expand((stateEvents) => [
                stateEvents.nameChange,
                stateEvents.avatarChange,
                stateEvents.topicChange,
                stateEvents.powerLevelsChange,
                stateEvents.joinRulesChange,
                stateEvents.canonicalAliasChange,
                stateEvents.creation,
                stateEvents.upgrade,
              ])
          .whereNotNull()
          .map((event) => event.toRecord(inTimeline: false))
          .toList(),
    );

    if (room.typingUserIds.isNotEmpty == true) {
      await _db?.setEphemeralEventRecords([room]
          .map(
            (room) => room.ephemeral!.toEventRecord(),
          )
          .toList());
    }

    await _db?.setEphemeralReceiveEventRecords(
      [room]
          .map((room) => room.ephemeral?.toReceiveRecord())
          .whereNotNull()
          .expand((e) => e)
          .toList(),
    );

    // Set member states
    await _db?.setRoomEventRecords(
      [room]
          .map((room) => room.memberTimeline?.map((m) => m.event) ?? [])
          .expand((events) => events)
          .whereNotNull()
          .map((event) => event.toRecord(inTimeline: false))
          .toList(),
    );

    // Set timeline. If any of the (member) state events were just set,
    // they'll be overridden with inTimeline = true.
    final eventsList = [room]
        .map((room) => room.timeline)
        .whereNotNull()
        .expand((timeline) => timeline)
        .map((event) => event.toRecord(inTimeline: true))
        .toList();
    await _db?.setRoomEventRecords(
      eventsList,
    );

    //Find latest message and save time interval to room
    final Map<String, int> result =
        eventsList.fold(<String, int>{}, (previousValue, element) {
      if (element.time != null) {
        final roomID = element.roomId;
        if (previousValue.containsKey(roomID) &&
            previousValue[roomID] != null) {
          if (previousValue[roomID]! < element.time!.millisecondsSinceEpoch) {
            previousValue[roomID] = element.time!.millisecondsSinceEpoch;
          }
        } else {
          previousValue[roomID] = element.time!.millisecondsSinceEpoch;
        }
      }
      return previousValue;
    });
    if (result.isNotEmpty) {
      await _db?.setRoomsLatestMessages(result);
    }
  }

  @override
  Future<bool> addFakeEvent(RoomEvent fakeRoomEvent) async {
    return _db!.addOneFakeMessage(
      fakeRoomEvent.toFakeRecord(inTimeline: false),
    );
  }

  @override
  Future<bool> deleteFakeMessage(String transactionId) async {
    return _db!.deleteFakeMessage(transactionId);
  }

  @override
  Future<List<RoomEvent>> getAllFakeEvents() async {
    final data = await _db!.getAllFakeMessages();
    return data.map((e) => e.toRoomFakeEvent()).toList();
  }

  Future<Iterable<Room>> getRoomsByIDsOptimized(
    Iterable<RoomId>? roomIds, {
    Context? context,
    required int timelineLimit,
    Iterable<UserId>? memberIds,
  }) async {
    final roomRecords = (await _db?.getRoomRecordsByIDs(
          roomIds?.map((id) => id.toString()),
        )) ??
        [];
    return _processRoomRecordsRequestsOptimized(
      roomRecords,
      timelineLimit,
      memberIds,
      context,
    );
  }

  @override
  Future<Iterable<Room>> getRoomsByIDs(
    Iterable<RoomId>? roomIds, {
    Context? context,
    required int timelineLimit,
    Iterable<UserId>? memberIds,
  }) async {
    final roomRecords = (await _db?.getRoomRecordsByIDs(
          roomIds?.map((id) => id.toString()),
        )) ??
        [];
    return _processRoomRecords(roomRecords, timelineLimit, memberIds, context);
  }

  @override
  Future<List<String?>> getRoomIDs() async {
    final result = await _db?.getRoomIDs();
    return result ?? [];
  }

  Map<String?, List<int>> _createMapIdToList(List<String> ids) {
    final Map<String?, List<int>> buf = {};

    for (var i = 0; i < ids.length; i++) {
      final id = ids[i];
      if (buf.containsKey(id)) {
        buf[id]!.add(i);
      } else {
        buf[id] = [i];
      }
    }
    return buf;
  }

  @override
  Future<Iterable<Room>> getRooms({
    Context? context,
    required int limit,
    required int offset,
    required int timelineLimit,
    Iterable<UserId>? memberIds,
  }) async {
    final roomRecords = (await _db?.getRoomRecords(limit, offset)) ?? [];
    return _processRoomRecords(roomRecords, timelineLimit, memberIds, context);
  }

  Future<Iterable<Room>> _processRoomRecordsRequestsOptimized(
    List<RoomRecordWithStateRecords> roomRecords,
    int timelineLimit,
    Iterable<UserId>? memberIds,
    Context? context,
  ) async {
    final ids = roomRecords.map((r) => r.roomRecord.id).toList();

    //Get all ephemeral events with ids, create Map<id, [indexes]>
    final ephemeralEventData = await _db!.getEphemeralEventRecordsWithIds(
      roomIds: ids,
      count: timelineLimit,
    );
    final ephemeralEventReceiveResult =
        ephemeralEventData.map((e) => e.getReceiveEvent()).toList();
    final ephemeralEventTypingResult =
        ephemeralEventData.map((e) => e.getTypingEvent()).toList();

    final Map<String?, List<int>> ephemeralTypingMap = _createMapIdToList(
      ephemeralEventTypingResult
          .where((element) => element.roomId?.value != null)
          .map((e) => e.roomId!.value)
          .toList(),
    );

    final Map<String?, List<int>> ephemeralReceiveMap = _createMapIdToList(
      ephemeralEventReceiveResult
          .where((element) => element.roomId?.value != null)
          .map((e) => e.roomId!.value)
          .toList(),
    );
    //Get all message events with ids, create Map<id, [indexes]>

    final messageEventResult = await getRoomEventsWithIDs(
      ids,
      count: timelineLimit,
      memberIds: memberIds,
      requestType: RoomEventRequestType.onlyMessages,
    ).then((value) => value.toList());

    final Map<String?, List<int>> messageEventMap = _createMapIdToList(
      messageEventResult
          .where((element) => element.roomId?.value != null)
          .map((e) => e.roomId!.value)
          .toList(),
    );

    //Make unique id, Get all message all members, create Map<id, [indexes]>

    var relevantUserIds = messageEventResult
        .whereNotNull()
        .map((e) => [e.senderId, if (e is MemberChangeEvent) e.subjectId])
        .expand((ids) => ids);

    if (memberIds != null) {
      relevantUserIds = relevantUserIds.followedBy(memberIds);
    }

    final uniqueIdStrings = Set.of(relevantUserIds.map((id) => id.toString()));

    final messageMembers = await getMessagesMembersWithIds(
      roomIds: ids,
      userIds: uniqueIdStrings,
    ).then((value) => value.toList());

    final Map<String?, List<int>> messagesMembersMap = _createMapIdToList(
      messageMembers
          .where((element) => element.roomId?.value != null)
          .map((e) => e.roomId!.value)
          .toList(),
    );

    final List<Room> roomsResult = [];
    for (final record in roomRecords) {
      final roomRecord = record.roomRecord;
      final roomId = roomRecord.id;
      final roomContext = context != null
          ? RoomContext.inherit(
              context,
              roomId: RoomId(roomId),
            )
          : null;

      //Make Timeline with messagesEventFiltered from messageEventMap and messageEventResult
      final messagesIndexes = messageEventMap[roomId] ?? [];
      final List<RoomEvent> messagesEventFiltered = [];
      for (final i in messagesIndexes) {
        messagesEventFiltered.add(messageEventResult[i]);
      }
      final Timeline? timeline = Timeline(
        messagesEventFiltered,
        context: roomContext,
        previousBatch: roomRecord.timelinePreviousBatch,
        previousBatchSetBySync: roomRecord.timelinePreviousBatchSetBySync,
      );

      //Make MemberTimeline with messageMembersFiltered from messagesMembersMap and messageMembers
      final membersIndexes = messagesMembersMap[roomId] ?? [];

      final List<Member> messageMembersFiltered = [];
      for (final i in membersIndexes) {
        messageMembersFiltered.add(messageMembers[i]);
      }

      final MemberTimeline? memberTimeline = MemberTimeline(
        messageMembersFiltered,
        context: roomContext,
      );

      //Make Ephemeral with ephemeralEventsFiltered from ephemeralMap and ephemeralEventResult
      final ephemeralEventsTypingIndexes = ephemeralTypingMap[roomId] ?? [];
      final ephemeralEventsReceiveIndexes = ephemeralReceiveMap[roomId] ?? [];

      final List<TypingEvent> ephemeralEventsTypingFiltered = [];
      for (final i in ephemeralEventsTypingIndexes) {
        ephemeralEventsTypingFiltered.add(ephemeralEventTypingResult[i]);
      }

      final typerIds = ephemeralEventsTypingFiltered
          .map((e) => e.content?.typerIds)
          .whereNotNull()
          .expand((e) => e)
          .toList();

      final List<ReceiptEvent> ephemeralEventsReceiveFiltered = [];
      for (final i in ephemeralEventsReceiveIndexes) {
        ephemeralEventsReceiveFiltered.add(ephemeralEventReceiveResult[i]);
      }

      final receipts = ephemeralEventsReceiveFiltered
          .map((e) => e.content?.receipts)
          .whereNotNull()
          .expand((e) => e)
          .toList();

      final ephemeral = EphemeralEventFull(
        typingEvents: TypingEvent(
          roomId: RoomId(roomRecord.id),
          content: Typers(typerIds: typerIds),
        ),
        receiptEvents: ReceiptEvent(
          roomId: RoomId(roomRecord.id),
          content: Receipts(receipts),
        ),
        roomId: RoomId(roomRecord.id),
      );

      final room = Room(
        context: context,
        id: RoomId(roomRecord.id),
        stateEvents: RoomStateEvents(
          nameChange: record.nameChangeRecord?.toRoomEvent(),
          avatarChange: record.avatarChangeRecord?.toRoomEvent(),
          topicChange: record.topicChangeRecord?.toRoomEvent(),
          powerLevelsChange: record.powerLevelsChangeRecord?.toRoomEvent(),
          joinRulesChange: record.joinRulesChangeRecord?.toRoomEvent(),
          canonicalAliasChange:
              record.canonicalAliasChangeRecord?.toRoomEvent(),
          creation: record.creationRecord?.toRoomEvent(),
          upgrade: record.upgradeRecord?.toRoomEvent(),
        ),
        timeline: timeline,
        memberTimeline: memberTimeline,
        summary: RoomSummary(
          joinedMembersCount: roomRecord.summaryJoinedMembersCount,
          invitedMembersCount: roomRecord.summaryInvitedMembersCount,
        ),
        directUserId: roomRecord.directUserId != null
            ? UserId(roomRecord.directUserId!)
            : null,
        highlightedUnreadNotificationCount:
            roomRecord.highlightedUnreadNotificationCount,
        totalUnreadNotificationCount: roomRecord.totalUnreadNotificationCount,
        ephemeral: ephemeral,
      );
      roomsResult.add(room);
    }

    return roomsResult;
  }

  Future<Iterable<Room>> _processRoomRecords(
    List<RoomRecordWithStateRecords> roomRecords,
    int timelineLimit,
    Iterable<UserId>? memberIds,
    Context? context,
  ) async {
    // TODO: Optimize?
    final rooms = await Future.wait(
      roomRecords.map(
        (record) async {
          final roomRecord = record.roomRecord;
          final roomId = RoomId(roomRecord.id);

          final roomContext = context != null
              ? RoomContext.inherit(
                  context,
                  roomId: roomId,
                )
              : null;

          var timeline = Timeline.empty(context: roomContext);
          var memberTimeline = MemberTimeline.empty(context: roomContext);
          if (timelineLimit > 0) {
            final messages = await getMessages(
              roomId,
              count: timelineLimit,
              memberIds: memberIds,
            );

            timeline = Timeline(
              messages.events,
              context: roomContext,
              previousBatch: roomRecord.timelinePreviousBatch,
              previousBatchSetBySync: roomRecord.timelinePreviousBatchSetBySync,
            );

            memberTimeline = MemberTimeline(
              messages.state,
              context: roomContext,
            );
          }
          final ephemeralResult = await _db!.getEphemeralEventRecords(
            roomId.value,
          );
          final ephemeral = EphemeralEventFull(
            roomId: roomId,
            typingEvents: ephemeralResult.getTypingEvent(),
            receiptEvents: ephemeralResult.getReceiveEvent(),
            context: roomContext,
          );

          return Room(
            context: context,
            id: RoomId(roomRecord.id),
            stateEvents: RoomStateEvents(
              nameChange: record.nameChangeRecord?.toRoomEvent(),
              avatarChange: record.avatarChangeRecord?.toRoomEvent(),
              topicChange: record.topicChangeRecord?.toRoomEvent(),
              powerLevelsChange: record.powerLevelsChangeRecord?.toRoomEvent(),
              joinRulesChange: record.joinRulesChangeRecord?.toRoomEvent(),
              canonicalAliasChange:
                  record.canonicalAliasChangeRecord?.toRoomEvent(),
              creation: record.creationRecord?.toRoomEvent(),
              upgrade: record.upgradeRecord?.toRoomEvent(),
            ),
            timeline: timeline,
            memberTimeline: memberTimeline,
            summary: RoomSummary(
              joinedMembersCount: roomRecord.summaryJoinedMembersCount,
              invitedMembersCount: roomRecord.summaryInvitedMembersCount,
            ),
            directUserId: roomRecord.directUserId != null
                ? UserId(roomRecord.directUserId ?? '')
                : null,
            highlightedUnreadNotificationCount:
                roomRecord.highlightedUnreadNotificationCount,
            totalUnreadNotificationCount:
                roomRecord.totalUnreadNotificationCount,
            ephemeral: ephemeral,
          );
        },
      ),
    );

    _setInvites(rooms);

    return rooms;
  }

  Future<Iterable<Member>> getMessagesMembersWithIds({
    required List<String> roomIds,
    required Iterable<String> userIds,
  }) async {
    return _db!
        .getMemberEventRecordsOfSendersWithIds(
          roomIds: roomIds,
          userIds: userIds,
        )
        .then(
          (records) => records.map((r) => r.toRoomEvent()).whereNotNull().map(
                (r) => Member.fromEvent(r as MemberChangeEvent),
              ),
        );
  }

  @override
  Future<Messages> getMessages(
    RoomId roomId, {
    int count = 20,
    DateTime? fromTime,
    Iterable<UserId>? memberIds,
  }) async {
    final events = (await _db
            ?.getRoomEventRecords(
              roomId.toString(),
              count: count,
              fromTime: fromTime,
              inTimeline: true,
            )
            .then((records) =>
                records.map((r) => r.toRoomEvent()).whereNotNull())) ??
        [];

    var relevantUserIds = events
        .whereNotNull()
        .map((e) => [e.senderId, if (e is MemberChangeEvent) e.subjectId])
        .expand((ids) => ids);

    if (memberIds != null) {
      relevantUserIds = relevantUserIds.followedBy(memberIds);
    }

    final uniqueIdStrings = Set.of(relevantUserIds.map((id) => id.toString()));

    Future<Iterable<Member>> getMembers(Iterable<String> ids) async {
      return _db!
          .getMemberEventRecordsOfSenders(
            roomId.toString(),
            ids,
          )
          .then(
            (records) => records.map((r) => r.toRoomEvent()).whereNotNull().map(
                  (r) => Member.fromEvent(r as MemberChangeEvent),
                ),
          );
    }

    var members = await getMembers(uniqueIdStrings);

    final missingIdStrings = <String>{
      ...members
          .where((m) => !uniqueIdStrings.contains(m.event.subjectId.toString()))
          .map((m) => m.event.subjectId.toString()),
      ...members
          .where((m) => !uniqueIdStrings.contains(m.event.senderId.toString()))
          .map((m) => m.event.senderId.toString()),
    };

    if (missingIdStrings.isNotEmpty) {
      members = LinkedHashSet(
        equals: (a, b) => a.event.equals(b.event),
        hashCode: (m) => m.event.id.hashCode,
      )..addAll([
          ...members,
          ...await getMembers(missingIdStrings),
        ]);
    }

    return Messages(events, members);
  }

  Future<Iterable<RoomEvent>> getRoomEventsWithIDs(
    List<String> roomIds, {
    int? count,
    bool? inTimeLine = true,
    DateTime? fromTime,
    required RoomEventRequestType requestType,
    Iterable<UserId>? memberIds,
  }) async {
    return (await _db
            ?.getRoomEventRecordsWithIDs(
              roomIds,
              requestType: requestType,
              count: count,
              fromTime: fromTime,
              inTimeline: inTimeLine,
            )
            .then(
              (records) => records.map((r) => r.toRoomEvent()).whereNotNull(),
            )) ??
        [];
  }

  @override
  Future<Iterable<RoomEvent>> getUnsentEvents() async {
    // TODO
    return [];
  }

  @override
  Future<Iterable<Member>> getMembers(
    RoomId roomId, {
    int count = 20,
    DateTime? fromTime,
  }) async {
    return _db!
        .getRoomEventRecords(
          roomId.toString(),
          count: count,
          fromTime: fromTime,
          onlyMemberChanges: true,
        )
        .then(
          (records) => records.map(
              (e) => Member.fromEvent(e.toRoomEvent() as MemberChangeEvent)),
        );
  }

  @override
  Future<void> wipeAllData() => _db!.wipeAllData();
}

abstract class MoorStoreLocation extends StoreLocation<MoorStore> {
  MoorStoreLocation();

  factory MoorStoreLocation.file(File file) => MoorStoreFileLocation(file);
}

/// TODO: Move to dart:io only file/library
class MoorStoreFileLocation extends MoorStoreLocation {
  final File file;

  MoorStoreFileLocation(this.file);

  @override
  MoorStore create() => MoorStore(
        NativeDatabase(
          file,
          setup: (rawDb) => rawDb.execute('PRAGMA journal_mode=WAL;'),
        ),
      );
}

extension on DeviceRecord {
  Device toDevice() {
    return Device(
      id: DeviceId(id),
      userId: UserId(userId),
      name: name,
      lastSeen: lastSeen,
      lastIpAddress: lastIpAddress,
    );
  }
}

extension on Device {
  DevicesCompanion toCompanion() {
    return DevicesCompanion(
      id: id != null ? Value(id.toString()) : Value.absent(),
      userId: userId != null ? Value(userId.toString()) : Value.absent(),
      name: name != null ? Value(name) : Value.absent(),
      lastSeen: lastSeen != null ? Value(lastSeen) : Value.absent(),
      lastIpAddress:
          lastIpAddress != null ? Value(lastIpAddress) : Value.absent(),
    );
  }
}

extension on Room {
  RoomsCompanion toCompanion() {
    return RoomsCompanion(
      id: Value(id.toString()),
      timelinePreviousBatch: timeline?.previousBatch != null
          ? Value(timeline?.previousBatch)
          : Value.absent(),
      timelinePreviousBatchSetBySync: timeline?.previousBatchSetBySync != null
          ? Value(timeline?.previousBatchSetBySync)
          : Value.absent(),
      summaryJoinedMembersCount: summary?.joinedMembersCount != null
          ? Value(summary?.joinedMembersCount)
          : Value.absent(),
      summaryInvitedMembersCount: summary?.invitedMembersCount != null
          ? Value(summary?.invitedMembersCount)
          : Value.absent(),
      highlightedUnreadNotificationCount:
          highlightedUnreadNotificationCount != null
              ? Value(highlightedUnreadNotificationCount)
              : Value.absent(),
      totalUnreadNotificationCount: totalUnreadNotificationCount != null
          ? Value(totalUnreadNotificationCount)
          : Value.absent(),
      directUserId: directUserId != null
          ? Value(directUserId.toString())
          : Value.absent(),
      nameChangeEventId: stateEvents?.nameChange?.storedId != null
          ? Value(stateEvents?.nameChange?.storedId)
          : Value.absent(),
      avatarChangeEventId: stateEvents?.avatarChange?.storedId != null
          ? Value(stateEvents?.avatarChange?.storedId)
          : Value.absent(),
      topicChangeEventId: stateEvents?.topicChange?.storedId != null
          ? Value(stateEvents?.topicChange?.storedId)
          : Value.absent(),
      powerLevelsChangeEventId: stateEvents?.powerLevelsChange?.storedId != null
          ? Value(stateEvents?.powerLevelsChange?.storedId)
          : Value.absent(),
      joinRulesChangeEventId: stateEvents?.joinRulesChange?.storedId != null
          ? Value(stateEvents?.joinRulesChange?.storedId)
          : Value.absent(),
      canonicalAliasChangeEventId:
          stateEvents?.canonicalAliasChange?.storedId != null
              ? Value(stateEvents?.canonicalAliasChange?.storedId)
              : Value.absent(),
      creationEventId: stateEvents?.creation?.storedId != null
          ? Value(stateEvents?.creation?.storedId)
          : Value.absent(),
      upgradeEventId: stateEvents?.upgrade?.storedId != null
          ? Value(stateEvents?.upgrade?.storedId)
          : Value.absent(),
    );
  }
}

extension on RoomEvent {
  RoomEventRecord toRecord({
    required bool inTimeline,
  }) {
    String? stateKey, previousContent;
    if (this is StateEvent) {
      final it = this as StateEvent;
      // Automatic cast doesn't seem to work on this
      stateKey = it.stateKey;

      previousContent = it.previousContent != null
          ? json.encode(it.previousContent!.toJson())
          : null;
    }

    String? redacts;
    if (this is RedactionEvent) {
      redacts = (this as RedactionEvent).redacts.toString();
    }

    return RoomEventRecord(
      id: storedId,
      networkId: networkId,
      type: type,
      roomId: roomId.toString(),
      senderId: senderId.toString(),
      time: time,
      content: content != null ? json.encode(content?.toJson()) : null,
      previousContent: previousContent,
      sentState: sentState?.toShortString(),
      transactionId: transactionId,
      stateKey: stateKey,
      redacts: redacts,
      inTimeline: inTimeline,
    );
  }

  RoomFakeEventRecord toFakeRecord({
    required bool inTimeline,
  }) {
    String? stateKey, previousContent;
    if (this is StateEvent) {
      final it = this as StateEvent;
      // Automatic cast doesn't seem to work on this
      stateKey = it.stateKey;

      previousContent = it.previousContent != null
          ? json.encode(it.previousContent!.toJson())
          : null;
    }

    String? redacts;
    if (this is RedactionEvent) {
      redacts = (this as RedactionEvent).redacts.toString();
    }

    return RoomFakeEventRecord(
      id: storedId,
      networkId: networkId,
      type: type,
      roomId: roomId.toString(),
      senderId: senderId.toString(),
      time: time,
      content: content != null ? json.encode(content?.toJson()) : null,
      previousContent: previousContent,
      sentState: sentState?.toShortString(),
      transactionId: transactionId,
      stateKey: stateKey,
      redacts: redacts,
      inTimeline: inTimeline,
    );
  }

  String get storedId {
    //    var id = this.id.toString();
    //
    //     if (this is StateEvent) {
    //       final it = this as StateEvent;
    //       id = '$roomId:$runtimeType:${it.stateKey}';
    //     }
    //
    //     return id;
    //TODO if stable remove and use everywhere id.value on next update
    return id.value;
  }
}

extension on RoomEventRecord {
  T toRoomEvent<T extends RoomEvent>() {
    final args = RoomEventArgs(
      id: EventId(id),
      networkId: networkId,
      senderId: UserId(senderId),
      time: time,
      roomId: RoomId(roomId),
      sentState: sentState?.toSentState(),
      transactionId: transactionId,
    );

    dynamic decodedContent, decodedPreviousContent;
    if (content != null) {
      decodedContent = json.decode(content!);
    }

    if (previousContent != null) {
      decodedPreviousContent = json.decode(previousContent!);
    }

    switch (type) {
      case MessageEvent.matrixType:
        return MessageEvent.instance(
          args,
          content: MessageEventContent.fromJson(decodedContent),
        ) as T;
      case MemberChangeEvent.matrixType:
        return MemberChangeEvent(
          args,
          content: MemberChange.fromJson(decodedContent),
          previousContent: MemberChange.fromJson(decodedPreviousContent),
          stateKey: stateKey ?? '',
        ) as T;
      case RedactionEvent.matrixType:
        return RedactionEvent(
          args,
          content: Redaction.fromJson(decodedContent),
          redacts: EventId(redacts ?? ''),
        ) as T;
      case RoomAvatarChangeEvent.matrixType:
        return RoomAvatarChangeEvent(
          args,
          content: RoomAvatarChange.fromJson(decodedContent),
          previousContent: RoomAvatarChange.fromJson(decodedPreviousContent),
        ) as T;
      case RoomNameChangeEvent.matrixType:
        return RoomNameChangeEvent(
          args,
          content: RoomNameChange.fromJson(decodedContent),
          previousContent: RoomNameChange.fromJson(decodedPreviousContent),
        ) as T;
      case RoomCreationEvent.matrixType:
        return RoomCreationEvent(
          args,
          content: RoomCreation.fromJson(decodedContent),
          previousContent: RoomCreation.fromJson(decodedPreviousContent),
        ) as T;
      case RoomUpgradeEvent.matrixType:
        return RoomUpgradeEvent(
          args,
          content: RoomUpgrade.fromJson(decodedContent),
          previousContent: RoomUpgrade.fromJson(decodedPreviousContent),
        ) as T;
      case TopicChangeEvent.matrixType:
        return TopicChangeEvent(
          args,
          content: TopicChange.fromJson(decodedContent),
          previousContent: TopicChange.fromJson(decodedPreviousContent),
        ) as T;
      case PowerLevelsChangeEvent.matrixType:
        return PowerLevelsChangeEvent.instance(
          args,
          content: PowerLevelsChange.fromJson(decodedContent),
          previousContent: PowerLevelsChange.fromJson(decodedPreviousContent),
        ) as T;
      case JoinRulesChangeEvent.matrixType:
        return JoinRulesChangeEvent(
          args,
          content: JoinRules.fromJson(decodedContent),
          previousContent: JoinRules.fromJson(decodedPreviousContent),
        ) as T;
      case CanonicalAliasChangeEvent.matrixType:
        return CanonicalAliasChangeEvent(
          args,
          content: CanonicalAliasChange.fromJson(decodedContent),
          previousContent: CanonicalAliasChange.fromJson(
            decodedPreviousContent,
          ),
        ) as T;
      default:
        return stateKey != null
            ? RawStateEvent(
                args,
                type: type,
                content: RawEventContent.fromJson(decodedContent),
                previousContent:
                    RawEventContent.fromJson(decodedPreviousContent),
                stateKey: stateKey,
              ) as T
            : RawRoomEvent(
                args,
                type: type,
                content: RawEventContent.fromJson(decodedContent),
              ) as T;
    }
  }
}

extension on RoomFakeEventRecord {
  T toRoomFakeEvent<T extends RoomEvent>() {
    final args = RoomEventArgs(
      id: EventId(id),
      networkId: networkId,
      senderId: UserId(senderId),
      time: time,
      roomId: RoomId(roomId),
      sentState: sentState?.toSentState(),
      transactionId: transactionId,
    );

    dynamic decodedContent, decodedPreviousContent;
    if (content != null) {
      decodedContent = json.decode(content!);
    }

    if (previousContent != null) {
      decodedPreviousContent = json.decode(previousContent!);
    }

    switch (type) {
      case MessageEvent.matrixType:
        return MessageEvent.instance(
          args,
          content: MessageEventContent.fromJson(decodedContent),
        ) as T;
      case MemberChangeEvent.matrixType:
        return MemberChangeEvent(
          args,
          content: MemberChange.fromJson(decodedContent),
          previousContent: MemberChange.fromJson(decodedPreviousContent),
          stateKey: stateKey ?? '',
        ) as T;
      case RedactionEvent.matrixType:
        return RedactionEvent(
          args,
          content: Redaction.fromJson(decodedContent),
          redacts: EventId(redacts ?? ''),
        ) as T;
      case RoomAvatarChangeEvent.matrixType:
        return RoomAvatarChangeEvent(
          args,
          content: RoomAvatarChange.fromJson(decodedContent),
          previousContent: RoomAvatarChange.fromJson(decodedPreviousContent),
        ) as T;
      case RoomNameChangeEvent.matrixType:
        return RoomNameChangeEvent(
          args,
          content: RoomNameChange.fromJson(decodedContent),
          previousContent: RoomNameChange.fromJson(decodedPreviousContent),
        ) as T;
      case RoomCreationEvent.matrixType:
        return RoomCreationEvent(
          args,
          content: RoomCreation.fromJson(decodedContent),
          previousContent: RoomCreation.fromJson(decodedPreviousContent),
        ) as T;
      case RoomUpgradeEvent.matrixType:
        return RoomUpgradeEvent(
          args,
          content: RoomUpgrade.fromJson(decodedContent),
          previousContent: RoomUpgrade.fromJson(decodedPreviousContent),
        ) as T;
      case TopicChangeEvent.matrixType:
        return TopicChangeEvent(
          args,
          content: TopicChange.fromJson(decodedContent),
          previousContent: TopicChange.fromJson(decodedPreviousContent),
        ) as T;
      case PowerLevelsChangeEvent.matrixType:
        return PowerLevelsChangeEvent.instance(
          args,
          content: PowerLevelsChange.fromJson(decodedContent),
          previousContent: PowerLevelsChange.fromJson(decodedPreviousContent),
        ) as T;
      case JoinRulesChangeEvent.matrixType:
        return JoinRulesChangeEvent(
          args,
          content: JoinRules.fromJson(decodedContent),
          previousContent: JoinRules.fromJson(decodedPreviousContent),
        ) as T;
      case CanonicalAliasChangeEvent.matrixType:
        return CanonicalAliasChangeEvent(
          args,
          content: CanonicalAliasChange.fromJson(decodedContent),
          previousContent: CanonicalAliasChange.fromJson(
            decodedPreviousContent,
          ),
        ) as T;
      default:
        return stateKey != null
            ? RawStateEvent(
                args,
                type: type,
                content: RawEventContent.fromJson(decodedContent),
                previousContent:
                    RawEventContent.fromJson(decodedPreviousContent),
                stateKey: stateKey,
              ) as T
            : RawRoomEvent(
                args,
                type: type,
                content: RawEventContent.fromJson(decodedContent),
              ) as T;
    }
  }
}

extension on EphemeralEventTransition {
  TypingEvent getTypingEvent() {
    final List<String> typingList = [];
    for (final e in typing) {
      final buf = json.decode(e.typing!);
      if (buf is List<String>) {
        typingList.addAll(buf);
      }
    }

    return TypingEvent(
      roomId: roomId,
      content: Typers(
        typerIds: typingList.map(UserId.new).toList(),
      ),
    );
  }

  ReceiptEvent getReceiveEvent() {
    final List<Receipt> readEventResult = [];
    for (final e in readEvents) {
      final buf = Receipt(
        type: ReceiptType.read,
        userId: UserId(e.userId),
        eventId: EventId(e.eventId),
        time: DateTime.fromMillisecondsSinceEpoch(e.timeStamp),
      );
      readEventResult.add(buf);
    }

    return ReceiptEvent(
      roomId: roomId,
      content: Receipts(readEventResult),
    );
  }
}

extension on EphemeralEventFull {
  EphemeralEventRecord toEventRecord() {
    return EphemeralEventRecord(
      typing:
          "[${typingEvents.content?.typerIds.whereNotNull().map((e) => e.value).join(", ")}]",
      roomId: roomId.toString(),
    );
  }

  List<EphemeralReceiptEventRecord> toReceiveRecord() {
    final receipts = receiptEvents.content?.receipts ?? [];

    return receipts
        .map(
          (r) => EphemeralReceiptEventRecord(
            roomId: roomId.value,
            eventId: r.eventId.value,
            userId: r.userId.value,
            timeStamp: r.time.millisecondsSinceEpoch,
          ),
        )
        .toList();
  }
}

extension on SentState {
  String toShortString() {
    switch (this) {
      case SentState.unsent:
        return "unsent";
      case SentState.sent:
        return "sent";
      case SentState.sentError:
        return "sentError";
    }
  }
}

extension on String {
  SentState? toSentState() {
    switch (this) {
      case 'unsent':
        return SentState.unsent;
      case 'sent':
        return SentState.sent;
      case 'sentError':
        return SentState.sentError;
      default:
        return null;
    }
  }
}
