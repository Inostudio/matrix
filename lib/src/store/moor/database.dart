// Copyright (C) 2020  Mathieu Velten
// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:drift/backends.dart';
import 'package:drift/drift.dart';
import 'package:matrix_sdk/matrix_sdk.dart';
import 'package:matrix_sdk/src/util/logger.dart';
import 'package:synchronized/synchronized.dart';

import '../../event/room/state/request_type.dart';

part 'database.g.dart';

@DataClassName('MyUserRecord')
class MyUsers extends Table {
  TextColumn get homeserver => text().nullable()();

  TextColumn get id => text().nullable()();

  TextColumn get name => text().nullable()();

  TextColumn get avatarUrl => text().nullable()();

  TextColumn get accessToken => text().nullable()();

  TextColumn get syncToken => text().nullable()();

  TextColumn get currentDeviceId =>
      text().nullable().customConstraint('REFERENCES devices(id)')();

  BoolColumn get hasSynced => boolean().nullable()();

  BoolColumn get isLoggedOut => boolean().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RoomRecord')
class Rooms extends Table {
  TextColumn get myMembership => text().nullable()();

  TextColumn get id => text()();

  TextColumn get timelinePreviousBatch => text().nullable()();

  BoolColumn get timelinePreviousBatchSetBySync => boolean().nullable()();

  IntColumn get summaryJoinedMembersCount => integer().nullable()();

  IntColumn get summaryInvitedMembersCount => integer().nullable()();

  TextColumn get nameChangeEventId =>
      text().customConstraint('REFERENCES room_events(id)').nullable()();

  TextColumn get avatarChangeEventId =>
      text().customConstraint('REFERENCES room_events(id)').nullable()();

  TextColumn get topicChangeEventId =>
      text().customConstraint('REFERENCES room_events(id)').nullable()();

  TextColumn get powerLevelsChangeEventId =>
      text().customConstraint('REFERENCES room_events(id)').nullable()();

  TextColumn get joinRulesChangeEventId =>
      text().customConstraint('REFERENCES room_events(id)').nullable()();

  TextColumn get canonicalAliasChangeEventId =>
      text().customConstraint('REFERENCES room_events(id)').nullable()();

  TextColumn get creationEventId =>
      text().customConstraint('REFERENCES room_events(id)').nullable()();

  TextColumn get upgradeEventId =>
      text().customConstraint('REFERENCES room_events(id)').nullable()();

  IntColumn get highlightedUnreadNotificationCount => integer().nullable()();

  IntColumn get totalUnreadNotificationCount => integer().nullable()();

  IntColumn get lastMessageTimeInterval =>
      integer().withDefault(const Constant(0))();

  TextColumn get directUserId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RoomEventRecord')
class RoomEvents extends Table {
  TextColumn get id => text()();

  //TODO now id and networkId is duplicated. If work stable - remove networkId
  TextColumn get networkId => text()();

  TextColumn get type => text()();

  TextColumn get roomId =>
      text().customConstraint('REFERENCES room_events(id)')();

  TextColumn get senderId => text()();

  DateTimeColumn get time => dateTime().nullable()();

  TextColumn get content => text().nullable()();

  TextColumn get previousContent => text().nullable()();

  TextColumn get sentState => text().nullable()();

  TextColumn get transactionId => text().nullable()();

  TextColumn get stateKey => text().nullable()();

  TextColumn get redacts => text().nullable()();

  BoolColumn get inTimeline => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('EphemeralEventRecord')
class EphemeralEvents extends Table {
  TextColumn get roomId =>
      text().customConstraint('REFERENCES room_events(id)')();

  TextColumn get typing => text().nullable()();

  @override
  Set<Column> get primaryKey => {roomId};
}

@DataClassName('EphemeralReceiptEventRecord')
class EphemeralReceiptEvent extends Table {
  TextColumn get roomId => text()();

  TextColumn get userId => text()();

  TextColumn get eventId => text()();

  IntColumn get timeStamp => integer()();

  @override
  Set<Column> get primaryKey => {roomId, userId};
}

@DataClassName('DeviceRecord')
class Devices extends Table {
  TextColumn get id => text()();

  TextColumn get userId => text()();

  TextColumn get name => text().nullable()();

  DateTimeColumn get lastSeen => dateTime().nullable()();

  TextColumn get lastIpAddress => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(include: {
  'indices.drift'
}, tables: [
  MyUsers,
  Rooms,
  RoomEvents,
  EphemeralEvents,
  Devices,
])
class Database extends _$Database {
  int maxAttempts = 5;
  final Lock lock = Lock();

  Database(DelegatedDatabase delegate) : super(delegate) {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  }

  Future<T> runOperation<T>({
    required Function onRun,
    Function(String)? onError,
    required String operationName,
  }) async {
    Object? lastError;
    int index = 0;
    final result = await lock.synchronized(() async {
      while (index <= maxAttempts) {
        index += 1;
        try {
          return await onRun();
        } catch (e) {
          lastError = e;
          Log.writer.log("$operationName Retrying count: $index");
          onError?.call(e.toString());
          await Future.delayed(Duration(milliseconds: 100));
        }
      }
      throw Exception(
          "Cant do $operationName in $maxAttempts attempts\nError: $lastError");
    });
    if (index != 1) {
      Log.writer.log(
          "$operationName Result success!!! Attempt: $index\nRESULT IS $result");
    }
    return result;
  }

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration {
    runOperation(
      onRun: () async {
        final user = await select(myUsers).getSingleOrNull();

        if (user != null) {
          final emptyUser = user.copyWith(syncToken: null);
          await batch(
            (batch) => batch.insert(
              myUsers,
              emptyUser.toCompanion(true),
              mode: InsertMode.insertOrReplace,
            ),
          );
        }
      },
      operationName: "WipeUserTokenMigration",
    );
    return destructiveFallback;
  }

  Future<String?> getUserSyncToken() async {
    final query = select(myUsers);
    final user = await runOperation(
      onRun: query.getSingleOrNull,
      onError: (error) => showError("getUserSyncToken", error),
      operationName: "getUserSyncToken",
    );
    return user?.syncToken;
  }

  Selectable<MyUserRecordWithDeviceRecord?> _selectUserWithDevice() {
    final query = select(myUsers)..getSingleOrNull();

    return query.join([
      leftOuterJoin(
        devices,
        devices.id.equalsExp(myUsers.currentDeviceId),
      )
    ]).map(
      (r) => MyUserRecordWithDeviceRecord(
        myUserRecord: r.readTable(myUsers),
        deviceRecord: r.readTableOrNull(devices),
      ),
    );
  }

  Stream<MyUserRecordWithDeviceRecord?> getUserSync() =>
      _selectUserWithDevice().watchSingleOrNull();

  Future<MyUserRecordWithDeviceRecord> getMyUserRecord() => runOperation(
        operationName: "getMyUserRecord",
        onRun: _selectUserWithDevice().getSingleOrNull,
        onError: (error) => showError("getMyUserRecord", error),
      );

  Future<void> setMyUser(MyUsersCompanion companion) async => runOperation(
        onRun: () => batch(
          (batch) => batch.insert(myUsers, companion,
              mode: InsertMode.insertOrReplace),
        ),
        onError: (error) => showError("setMyUser", error),
        operationName: "setMyUser",
      );

  Selectable<RoomRecordWithStateRecords> selectRoomRecordsByIDs(
    Iterable<String>? roomIds,
  ) {
    final nameChangeAlias = alias(roomEvents, 'name_change');
    final avatarChangeAlias = alias(roomEvents, 'avatar_change');
    final topicChangeAlias = alias(roomEvents, 'topic_change');
    final powerLevelsChangeAlias = alias(roomEvents, 'power_levels_change');
    final joinRulesChangeAlias = alias(roomEvents, 'join_rules_change');
    final canonicalAliasChangeAlias = alias(
      roomEvents,
      'canonical_alias_change',
    );
    final creationAlias = alias(roomEvents, 'creation');
    final upgradeAlias = alias(roomEvents, 'upgrade');
    final query = select(rooms).join([
      leftOuterJoin(
        nameChangeAlias,
        nameChangeAlias.id.equalsExp(rooms.nameChangeEventId),
      ),
      leftOuterJoin(
        avatarChangeAlias,
        avatarChangeAlias.id.equalsExp(rooms.avatarChangeEventId),
      ),
      leftOuterJoin(
        topicChangeAlias,
        topicChangeAlias.id.equalsExp(rooms.topicChangeEventId),
      ),
      leftOuterJoin(
        powerLevelsChangeAlias,
        powerLevelsChangeAlias.id.equalsExp(rooms.powerLevelsChangeEventId),
      ),
      leftOuterJoin(
        joinRulesChangeAlias,
        joinRulesChangeAlias.id.equalsExp(rooms.joinRulesChangeEventId),
      ),
      leftOuterJoin(
        canonicalAliasChangeAlias,
        canonicalAliasChangeAlias.id.equalsExp(
          rooms.canonicalAliasChangeEventId,
        ),
      ),
      leftOuterJoin(
        creationAlias,
        creationAlias.id.equalsExp(rooms.creationEventId),
      ),
      leftOuterJoin(
        upgradeAlias,
        upgradeAlias.id.equalsExp(rooms.upgradeEventId),
      ),
    ]);

    if (roomIds != null) {
      query.where(rooms.id.isIn(roomIds));
    }

    return query.map(
      (r) => RoomRecordWithStateRecords(
        roomRecord: r.readTable(rooms),
        nameChangeRecord: r.readTableOrNull(nameChangeAlias),
        avatarChangeRecord: r.readTableOrNull(avatarChangeAlias),
        topicChangeRecord: r.readTableOrNull(topicChangeAlias),
        powerLevelsChangeRecord: r.readTableOrNull(powerLevelsChangeAlias),
        joinRulesChangeRecord: r.readTableOrNull(joinRulesChangeAlias),
        canonicalAliasChangeRecord:
            r.readTableOrNull(canonicalAliasChangeAlias),
        creationRecord: r.readTableOrNull(creationAlias),
        upgradeRecord: r.readTableOrNull(upgradeAlias),
      ),
    );
  }

  Future<List<RoomRecordWithStateRecords>> getRoomRecordsByIDs(
    Iterable<String>? roomIds,
  ) async => runOperation(
        onRun: () => selectRoomRecordsByIDs(roomIds).get(),
        onError: (error) => showError("getRoomRecordsByIDs", error),
        operationName: "getRoomRecordsByIDs",
      );

  Future<List<String?>> getRoomIDs() async {
    final roomIDs = rooms.id;
    final query = selectOnly(rooms);
    query.addColumns([rooms.id]);
    final finQuery = query.map((row) => row.read(roomIDs));
    final result = await runOperation(
      operationName: "getRoomIDs",
      onRun: finQuery.get,
      onError: (error) => showError("getRoomIDs", error),
    );
    return result ?? [];
  }

  Future<List<RoomRecordWithStateRecords>> getRoomRecords(
      int limit, int offset) async {
    final nameChangeAlias = alias(roomEvents, 'name_change');
    final avatarChangeAlias = alias(roomEvents, 'avatar_change');
    final topicChangeAlias = alias(roomEvents, 'topic_change');
    final powerLevelsChangeAlias = alias(roomEvents, 'power_levels_change');
    final joinRulesChangeAlias = alias(roomEvents, 'join_rules_change');
    final canonicalAliasChangeAlias = alias(
      roomEvents,
      'canonical_alias_change',
    );
    final creationAlias = alias(roomEvents, 'creation');
    final upgradeAlias = alias(roomEvents, 'upgrade');

    final query = select(rooms).join([
      leftOuterJoin(
        nameChangeAlias,
        nameChangeAlias.id.equalsExp(rooms.nameChangeEventId),
      ),
      leftOuterJoin(
        avatarChangeAlias,
        avatarChangeAlias.id.equalsExp(rooms.avatarChangeEventId),
      ),
      leftOuterJoin(
        topicChangeAlias,
        topicChangeAlias.id.equalsExp(rooms.topicChangeEventId),
      ),
      leftOuterJoin(
        powerLevelsChangeAlias,
        powerLevelsChangeAlias.id.equalsExp(rooms.powerLevelsChangeEventId),
      ),
      leftOuterJoin(
        joinRulesChangeAlias,
        joinRulesChangeAlias.id.equalsExp(rooms.joinRulesChangeEventId),
      ),
      leftOuterJoin(
        canonicalAliasChangeAlias,
        canonicalAliasChangeAlias.id.equalsExp(
          rooms.canonicalAliasChangeEventId,
        ),
      ),
      leftOuterJoin(
        creationAlias,
        creationAlias.id.equalsExp(rooms.creationEventId),
      ),
      leftOuterJoin(
        upgradeAlias,
        upgradeAlias.id.equalsExp(rooms.upgradeEventId),
      ),
    ]);
    query.orderBy([
      OrderingTerm(
          expression: rooms.lastMessageTimeInterval, mode: OrderingMode.desc)
    ]);
    query.limit(limit, offset: offset);

    final finQuery = query.map(
      (r) => RoomRecordWithStateRecords(
        roomRecord: r.readTable(rooms),
        nameChangeRecord: r.readTableOrNull(nameChangeAlias),
        avatarChangeRecord: r.readTableOrNull(avatarChangeAlias),
        topicChangeRecord: r.readTableOrNull(topicChangeAlias),
        powerLevelsChangeRecord: r.readTableOrNull(powerLevelsChangeAlias),
        joinRulesChangeRecord: r.readTableOrNull(joinRulesChangeAlias),
        canonicalAliasChangeRecord:
            r.readTableOrNull(canonicalAliasChangeAlias),
        creationRecord: r.readTableOrNull(creationAlias),
        upgradeRecord: r.readTableOrNull(upgradeAlias),
      ),
    );

    final result = await runOperation(
      operationName: "getRoomRecords",
      onRun: finQuery.get,
      onError: (error) => showError("getRoomRecords", error),
    );
    return result ?? [];
  }

  Future<void> setRooms(List<RoomsCompanion> companions) async {
    return runOperation(
      operationName: "setRooms",
      onRun: () => batch(
        (batch) => batch.insertAllOnConflictUpdate(rooms, companions),
      ),
      onError: (error) => showError("setRooms", error),
    );
  }

  Future<void> setRoomsLatestMessages(Map<String, int> data) async =>
      runOperation(
        operationName: "setRoomsLatestMessages",
        onRun: () => batch(
          (batch) async => data.forEach(
            (key, value) => batch.update<$RoomsTable, RoomRecord>(
              rooms,
              RoomsCompanion(lastMessageTimeInterval: Value(value)),
              where: (t) => t.id.like(key),
            ),
          ),
        ),
        onError: (error) => showError("setRoomsLatestMessages", error),
      );

  Future<Iterable<RoomEventRecord>> getRoomEventRecordsWithIDs(
    List<String> roomIds, {
    DateTime? fromTime,
    int? count,
    required RoomEventRequestType requestType,
    bool? inTimeline,
  }) async {
    final roomsList = roomIds.map((e) => "\'$e\'").join(", ");
    final requestsList = requestType.getEventLists();
    final requestTypesStrings = requestsList.isNotEmpty
        ? requestsList.map((e) => "\'$e\'").join(", ")
        : "";

    String whereClause = "room_id = rv1.room_id";
    if (roomIds.isNotEmpty) {
      whereClause += " AND room_id IN ($roomsList)";
    }

    if (requestTypesStrings.isNotEmpty) {
      whereClause += " AND type IN ($requestTypesStrings)";
    }
    if (inTimeline != null) {
      whereClause += " AND in_timeline = ${inTimeline.toString()}";
    }
    if (fromTime != null) {
      whereClause +=
          " AND time < ${fromTime.millisecondsSinceEpoch.toString()}";
    }

    final query = customSelect(
      """select  *
        from room_events rv1
        where id in
        (
        select id
        from room_events rv2
        where $whereClause
        order by
            time desc
        ${count == null ? '' : 'limit $count'}
        )""",
      readsFrom: {roomEvents},
    );

    final finQuery = query.map((row) {
      return RoomEventRecord.fromData(row.data);
    });

    final result = await runOperation(
        operationName: "getRoomEventRecordsWithIDs",
        onRun: finQuery.get,
        onError: (error) => showError("getRoomEventRecordsWithIDs", error));
    return result ?? [];
  }

  Future<Iterable<RoomEventRecord>> getMemberEventRecordsOfSendersWithIds({
    required List<String> roomIds,
    required Iterable<String> userIds,
    int? count,
  }) async {
    final query = select(roomEvents)
      ..where(
        (tbl) =>
            tbl.roomId.isIn(roomIds) &
            tbl.type.equals(MemberChangeEvent.matrixType) &
            (tbl.senderId.isIn(userIds) | tbl.stateKey.isIn(userIds)),
      );
    final result = await runOperation(
        operationName: "getMemberEventRecordsOfSendersWithIds",
        onRun: query.get,
        onError: (error) =>
            showError("getMemberEventRecordsOfSendersWithIds", error));
    return result ?? [];
  }

  Future<Iterable<EphemeralEventTransition>> getEphemeralEventRecordsWithIds({
    required List<String> roomIds,
    int? count,
  }) async {
    final result = await runOperation(
      operationName: "getEphemeralEventRecordsWithIds",
      onRun: () async {
        final List<EphemeralEventTransition> result = [];
        final roomsList = roomIds.map((e) => "\'$e\'").join(", ");

        String whereClause = "room_id = rv1.room_id";
        if (roomIds.isNotEmpty) {
          whereClause += " AND room_id IN ($roomsList)";
        }

        final query = customSelect(
          """select  *
        from ephemeral_events rv1
        where room_id in
        (
        select room_id
        from ephemeral_events rv2
        where $whereClause
        ${count == null ? '' : 'limit $count'}
        )""",
          readsFrom: {ephemeralEvents},
        );

        final typingQuery = query.map((row) {
          return EphemeralEventRecord.fromData(row.data);
        });

        final typing = await typingQuery.get();

        final recordQuery = select(ephemeralReceiptEvent)
          ..where(
            (tbl) => tbl.roomId.isIn(roomIds),
          );

        final readEvents = await recordQuery.get();

        for (final id in roomIds) {
          final buf = EphemeralEventTransition(
            roomId: RoomId(id),
            readEvents: readEvents.where((e) => e.roomId == id).toList(),
            typing: typing.where((e) => e.roomId == id).toList(),
          );
          result.add(buf);
        }

        return result;
      },
      onError: (error) => showError("getEphemeralEventRecordsWithIds", error),
    );
    return result ?? [];
  }

  Future<Iterable<RoomEventRecord>> getRoomEventRecords(
    String roomId, {
    int? count,
    DateTime? fromTime,
    bool onlyMemberChanges = false,
    bool? inTimeline,
  }) async {
    final query = select(roomEvents);

    if (onlyMemberChanges) {
      query.where(
        (tbl) => tbl.type.equals(MemberChangeEvent.matrixType),
      );
    }

    if (inTimeline != null) {
      query.where((tbl) => tbl.inTimeline.equals(inTimeline));
    }

    if (fromTime != null) {
      query.where((tbl) => tbl.time.isSmallerThanValue(fromTime));
    }

    query.where((tbl) => tbl.roomId.equals(roomId));

    query.orderBy([
      (e) => OrderingTerm(expression: e.time, mode: OrderingMode.desc),
    ]);

    if (count != null) {
      query.limit(count);
    }

    final result = await runOperation(
      operationName: "getRoomEventRecords",
      onRun: query.get,
      onError: (error) => showError("getRoomEventRecords", error),
    );
    return result ?? [];
  }

  Future<void> setRoomEventRecords(List<RoomEventRecord> records) async =>
      runOperation(
        operationName: "setRoomEventRecords",
        onRun: () => batch((batch) async {
          batch.insertAll(
            roomEvents,
            records,
            mode: InsertMode.insertOrReplace,
          );
          batch.deleteWhere<$RoomEventsTable, RoomEventRecord>(
            roomEvents,
            (tbl) => tbl.id.isIn(
              records
                  .map((r) => r.transactionId)
                  .where((txnId) => txnId != null),
            ),
          );
        }),
        onError: (error) => showError("setRoomEventRecords", error),
      );

  /// Get the MemberChangeEvents for each user.
  Future<Iterable<RoomEventRecord>> getMemberEventRecordsOfSenders(
    String roomId,
    Iterable<String> userIds,
  ) async {
    final query = select(roomEvents)
      ..where(
        (tbl) =>
            tbl.roomId.equals(roomId) &
            tbl.type.equals(MemberChangeEvent.matrixType) &
            (tbl.senderId.isIn(userIds) | tbl.stateKey.isIn(userIds)),
      );
    final result = await runOperation(
      operationName: "getMemberEventRecordsOfSenders",
      onRun: query.get,
      onError: (error) => showError("getMemberEventRecordsOfSenders", error),
    );
    return result ?? [];
  }

  Future<EphemeralEventTransition> getEphemeralEventRecords(
    String roomId,
  ) async {
    final result = await runOperation(
      operationName: "getEphemeralEventRecords",
      onRun: () async {
        final typingQuery = select(ephemeralEvents)
          ..where(
            (tbl) => tbl.roomId.equals(roomId),
          );

        final typing = await typingQuery.get();
        final recordQuery = select(ephemeralReceiptEvent)
          ..where(
            (tbl) => tbl.roomId.equals(roomId),
          );
        final record = await recordQuery.get();

        return EphemeralEventTransition(
          roomId: RoomId(roomId),
          typing: typing,
          readEvents: record,
        );
      },
      onError: (error) => showError("getEphemeralEventRecords", error),
    );
    return result ?? [];
  }

  Future<void> setEphemeralEventRecords(
    List<EphemeralEventRecord> records,
  ) async =>
      runOperation(
        operationName: "setEphemeralEventRecords",
        onRun: () => batch((batch) async {
          batch.insertAllOnConflictUpdate(
            ephemeralEvents,
            records,
          );
        }),
        onError: (error) => showError("setEphemeralEventRecords", error),
      );

  Future<void> setEphemeralReceiveEventRecords(
    List<EphemeralReceiptEventRecord> records,
  ) async {
    return runOperation(
      operationName: "setEphemeralReceiveEventRecords",
      onRun: () => batch((batch) async {
        batch.insertAllOnConflictUpdate(
          ephemeralReceiptEvent,
          records,
        );
      }),
      onError: (error) => showError("setEphemeralReceiveEventRecords", error),
    );
  }

  Future<void> setDeviceRecords(List<DevicesCompanion> companions) async =>
      runOperation(
        onRun: () => batch((batch) async {
          batch.insertAllOnConflictUpdate(
            devices,
            companions,
          );
        }),
        onError: (error) => showError("setDeviceRecords", error),
        operationName: "setDeviceRecords",
      );

  Future<void> deleteInviteStates(List<String> roomIds) async => runOperation(
        onRun: () => batch((batch) async {
          for (final roomId in roomIds) {
            batch.deleteWhere<$RoomEventsTable, RoomEventRecord>(
              roomEvents,
              (tbl) => tbl.id.isIn(['$roomId:%']),
            );
          }
        }),
        onError: (error) => showError("deleteInviteStates", error),
        operationName: "deleteInviteStates",
      );

  Future<void> wipeAllData() {
    return transaction(
      () async {
        for (final table in allTables) {
          await runOperation(
            operationName: "wipeAllData",
            onRun: () => delete(table).go(),
            onError: (error) => showError("wipeAllData", error),
          );
        }
      },
    );
  }

  void showError(String message, String error) => Log.writer.log(
        "ERROR RUN OPERATION --- $message\nerror: $error\nstack: ${StackTrace.current}",
      );
}

class MyUserRecordWithDeviceRecord {
  final MyUserRecord myUserRecord;
  final DeviceRecord? deviceRecord;

  MyUserRecordWithDeviceRecord({
    required this.myUserRecord,
    this.deviceRecord,
  });
}

class RoomRecordWithStateRecords {
  final RoomRecord roomRecord;

  final RoomEventRecord? nameChangeRecord;
  final RoomEventRecord? avatarChangeRecord;
  final RoomEventRecord? topicChangeRecord;
  final RoomEventRecord? powerLevelsChangeRecord;
  final RoomEventRecord? joinRulesChangeRecord;
  final RoomEventRecord? canonicalAliasChangeRecord;
  final RoomEventRecord? creationRecord;
  final RoomEventRecord? upgradeRecord;

  RoomRecordWithStateRecords({
    required this.roomRecord,
    required this.nameChangeRecord,
    required this.avatarChangeRecord,
    required this.topicChangeRecord,
    required this.powerLevelsChangeRecord,
    required this.joinRulesChangeRecord,
    required this.canonicalAliasChangeRecord,
    required this.creationRecord,
    required this.upgradeRecord,
  });
}

class EphemeralEventTransition {
  final RoomId roomId;
  final List<EphemeralReceiptEventRecord> readEvents;
  final List<EphemeralEventRecord> typing;

  const EphemeralEventTransition({
    required this.roomId,
    required this.readEvents,
    required this.typing,
  });
}
