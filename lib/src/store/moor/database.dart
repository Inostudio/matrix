// Copyright (C) 2020  Mathieu Velten
// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:moor/backends.dart';
import 'package:moor/moor.dart';
import '../../event/room/state/member_change_event.dart';

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

@UseMoor(include: {
  "indices.moor",
}, tables: [
  MyUsers,
  Rooms,
  RoomEvents,
  EphemeralEvents,
  Devices,
])
class Database extends _$Database {
  Database(DelegatedDatabase delegate) : super(delegate) {
    moorRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  }

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return destructiveFallback;
  }

  Future<MyUserRecordWithDeviceRecord?> getMyUserRecord(
    String userID,
  ) {
    final query = select(myUsers);
    query.where((u) => u.id.like('$userID'));
    query.limit(1);

    return query
        .join([
          leftOuterJoin(
            devices,
            devices.id.equalsExp(myUsers.currentDeviceId),
          )
        ])
        .map(
          (r) => MyUserRecordWithDeviceRecord(
            myUserRecord: r.readTable(myUsers),
            deviceRecord: r.readTableOrNull(devices),
          ),
        )
        .getSingleOrNull();
  }

  Future<void> setMyUser(MyUsersCompanion companion) async {
    await batch((batch) {
      batch.insert(myUsers, companion, mode: InsertMode.insertOrReplace);
    });
  }

  Future<List<RoomRecordWithStateRecords>> getRoomRecordsByIDs(
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

    return query
        .map(
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
        )
        .get();
  }

  Future<List<String?>> getRoomIDs() {
    final roomIDs = rooms.id;
    final query = selectOnly(rooms)..addColumns([rooms.id]);
    return query.map((row) => row.read(roomIDs)).get();
  }

  Future<List<RoomRecordWithStateRecords>> getRoomRecords(
      int limit, int offset) {
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

    return query
        .map(
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
        )
        .get();
  }

  Future<void> setRooms(List<RoomsCompanion> companions) async {
    await batch((batch) async {
      batch.insertAllOnConflictUpdate(rooms, companions);
    });
  }

  Future<void> setRoomsLatestMessages(Map<String, int> data) async {
    await batch((batch) async {
      data.forEach((key, value) {
        batch.update<$RoomsTable, RoomRecord>(
            rooms,
            RoomsCompanion(
              lastMessageTimeInterval: Value(value),
            ),
            where: (t) => t.id.like(key));
      });
    });
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

    return query.get();
  }

  Future<void> setRoomEventRecords(List<RoomEventRecord> records) async {
    await batch((batch) async {
      batch.insertAll(
        roomEvents,
        records,
        mode: InsertMode.insertOrReplace,
      );
      batch.deleteWhere<$RoomEventsTable, RoomEventRecord>(
        roomEvents,
        (tbl) => tbl.id.isIn(
          records.map((r) => r.transactionId).where((txnId) => txnId != null),
        ),
      );
    });
  }

  /// Get the MemberChangeEvents for each user.
  Future<Iterable<RoomEventRecord>> getMemberEventRecordsOfSenders(
    String roomId,
    Iterable<String> userIds,
  ) async {
    return (select(roomEvents)
          ..where(
            (tbl) =>
                tbl.roomId.equals(roomId) &
                tbl.type.equals(MemberChangeEvent.matrixType) &
                (tbl.senderId.isIn(userIds) | tbl.stateKey.isIn(userIds)),
          ))
        .get();
  }

  Future<Iterable<EphemeralEventRecord>> getEphemeralEventRecords(
    String roomId,
  ) async {
    final query = select(ephemeralEvents)
      ..where(
        (tbl) => tbl.roomId.equals(roomId),
      );

    return query.get();
  }

  Future<void> setEphemeralEventRecords(
    List<EphemeralEventRecord> records,
  ) async {
    await batch((batch) async {
      batch.insertAllOnConflictUpdate(
        ephemeralEvents,
        records,
      );
    });
  }

  Future<void> setDeviceRecords(List<DevicesCompanion> companions) async {
    await batch((batch) async {
      batch.insertAllOnConflictUpdate(
        devices,
        companions,
      );
    });
  }

  Future<void> deleteInviteStates(List<String> roomIds) async {
    await batch((batch) async {
      for (final roomId in roomIds) {
        batch.deleteWhere<$RoomEventsTable, RoomEventRecord>(
          roomEvents,
          (tbl) => tbl.id.isIn(['$roomId:%']),
        );
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
