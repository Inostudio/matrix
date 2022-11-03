// Copyright (C) 2020  Mathieu Velten
// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:developer';
import 'dart:isolate';

import 'package:drift/backends.dart';
import 'package:drift/drift.dart';
import 'package:matrix_sdk/matrix_sdk.dart';
import 'dart:async';
import '../../event/room/state/member_change_event.dart';
import '../../event/room/state/request_type.dart';
import '../../util/logger.dart';
import '../../util/queue/dart_queue_base.dart';

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
  TextColumn get type => text()();

  TextColumn get roomId =>
      text().customConstraint('REFERENCES room_events(id)')();

  TextColumn get content => text().nullable()();

  @override
  Set<Column> get primaryKey => {type, roomId};
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
  Database(DelegatedDatabase delegate) : super(delegate) {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  }

  final Queue _queue = Queue(delay: const Duration(milliseconds: 50));

  Future<T?> runOperation<T>({
    required Future<T?> onRun,
    Function(dynamic, dynamic)? onError,
    int attemptIndex = 1,
  }) {
    return _queue.add(() {
      try {
        return onRun;
      } catch (error, stack) {
        onError?.call(error, stack);
        if (attemptIndex <= 3) {
          Log.writer.log(
            """
    MATRIX DB REQUEST FAILED 
    RE_STARTING
    ATTEMPT $attemptIndex
      """,
          );
          attemptIndex++;
          return runOperation(onRun: onRun, attemptIndex: attemptIndex);
        } else {
          Log.writer.log(
            """
    MATRIX DB REQUEST FAILED 
    MORE THAN 3 ATTEMPTS
    GIVING UP :(
      """,
          );
          debugger(message: "DB LOCKED ERROR");
        }
        return Future.value(null);
      }
    });
  }

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration {
    return destructiveFallback;
  }

  Future<String?> getUserSyncToken() async {
    final query = select(myUsers);
    final user = await runOperation(
        onRun: query.getSingleOrNull(),
        onError: (error, stack) {
          print("ERROR RUN OPERATION --- getUserSyncToken");
        });
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

  Future<MyUserRecordWithDeviceRecord?> getMyUserRecord() =>
      _selectUserWithDevice().getSingleOrNull();

  Future<void> setMyUser(MyUsersCompanion companion) async {
    await runOperation(onRun: transaction(
      () async {
        await into(myUsers).insert(companion, mode: InsertMode.insertOrReplace);
      },
    ), onError: (error, stack) {
      print("ERROR RUN OPERATION --- setMyUser");
    });
  }

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
  ) =>
      selectRoomRecordsByIDs(roomIds).get();

  Future<List<String?>> getRoomIDs() async {
    final roomIDs = rooms.id;
    final query = selectOnly(rooms);
    query.addColumns([rooms.id]);
    final finQuery = query.map((row) => row.read(roomIDs));
    final result = await runOperation(
      onRun: finQuery.get(),
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
        onRun: finQuery.get(),
        onError: (error, stack) {
          print("ERROR RUN OPERATION --- getRoomRecords");
        });
    return result ?? [];
  }

  Future<void> setRooms(List<RoomsCompanion> companions) async {
    await runOperation(onRun: transaction(() async {
      for (RoomsCompanion c in companions) {
        await into(rooms).insert(c, onConflict: DoUpdate((_) => c));
      }
    }), onError: (error, stack) {
      print("ERROR RUN OPERATION --- setRooms");
    });
  }

  Future<void> setRoomsLatestMessages(Map<String, int> data) async {
    await runOperation(onRun: transaction(() async {
      for (String key in data.keys) {
        final value = data[key];
        if (value != null) {
          await (update(rooms)..where((t) => t.id.like(key)))
              .write(RoomsCompanion(
            lastMessageTimeInterval: Value(value),
          ));
        }
      }
    }), onError: (error, stack) {
      print("ERROR RUN OPERATION --- setRoomsLatestMessages");
    });
  }

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
        onRun: finQuery.get(),
        onError: (error, stack) {
          print("ERROR RUN OPERATION --- getRoomEventRecordsWithIDs");
        });
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
        onRun: query.get(),
        onError: (error, stack) {
          print(
              "ERROR RUN OPERATION --- getMemberEventRecordsOfSendersWithIds");
        });
    return result ?? [];
  }

  Future<Iterable<EphemeralEventRecord>> getEphemeralEventRecordsWithIds({
    required List<String> roomIds,
    int? count,
  }) async {
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

    final finQuery = query.map((row) {
      return EphemeralEventRecord.fromData(row.data);
    });

    final result = await runOperation(
        onRun: finQuery.get(),
        onError: (error, stack) {
          print("ERROR RUN OPERATION --- getEphemeralEventRecordsWithIds");
        });
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
        onRun: query.get(),
        onError: (error, stack) {
          print("ERROR RUN OPERATION --- getRoomEventRecords");
        });
    return result ?? [];
  }

  Future<void> setRoomEventRecords(List<RoomEventRecord> records) async {
    await runOperation(onRun: transaction(() async {
      for (RoomEventRecord r in records) {
        await into(roomEvents).insert(
          r,
          mode: InsertMode.insertOrReplace,
        );
      }

      //Delete fake local events
      await (delete(roomEvents)
        ..where((tbl) => tbl.id.isIn(records
            .map((r) => r.transactionId)
            .where((txnId) => txnId != null)))).go();
    }), onError: (error, stack) {
      print("ERROR RUN OPERATION --- setRoomEventRecords");
    });
  }

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
        onRun: query.get(),
        onError: (error, stack) {
          print("ERROR RUN OPERATION --- getMemberEventRecordsOfSenders");
        });
    return result ?? [];
  }

  Future<Iterable<EphemeralEventRecord>> getEphemeralEventRecords(
    String roomId,
  ) async {
    final query = select(ephemeralEvents)
      ..where(
        (tbl) => tbl.roomId.equals(roomId),
      );
    final result = await runOperation(
        onRun: query.get(),
        onError: (error, stack) {
          print("ERROR RUN OPERATION --- getEphemeralEventRecords");
        });
    return result ?? [];
  }

  Future<void> setEphemeralEventRecords(
    List<EphemeralEventRecord> records,
  ) async {
    await runOperation(onRun: transaction(() async {
      for (EphemeralEventRecord r in records) {
        await into(ephemeralEvents).insert(r, onConflict: DoUpdate((_) => r));
      }
    }), onError: (error, stack) {
      print("ERROR RUN OPERATION --- getEphemeralEventRecords");
    });
  }

  Future<void> setDeviceRecords(List<DevicesCompanion> companions) async {
    await runOperation(onRun: transaction(() async {
      for (DevicesCompanion d in companions) {
        await into(devices).insert(d, onConflict: DoUpdate((_) => d));
      }
    }), onError: (error, stack) {
      print("ERROR RUN OPERATION --- setDeviceRecords");
    });
  }

  Future<void> deleteInviteStates(List<String> roomIds) async {
    await runOperation(onRun: transaction(() async {
      for (final roomId in roomIds) {
        await (delete(roomEvents)..where((tbl) => tbl.id.isIn(['$roomId:%'])))
            .go();
      }
    }), onError: (error, stack) {
      print("ERROR RUN OPERATION --- deleteInviteStates");
    });
  }

  Future<void> wipeAllData() {
    return transaction(() async {
      for (final table in allTables) {
        await runOperation(
            onRun: delete(table).go(),
            onError: (error, stack) {
              print("ERROR RUN OPERATION --- wipeAllData");
            });
      }
    });
  }
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
