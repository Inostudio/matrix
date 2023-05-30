// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DevicesTable extends Devices
    with TableInfo<$DevicesTable, DeviceRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastSeenMeta =
      const VerificationMeta('lastSeen');
  @override
  late final GeneratedColumn<DateTime> lastSeen = GeneratedColumn<DateTime>(
      'last_seen', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastIpAddressMeta =
      const VerificationMeta('lastIpAddress');
  @override
  late final GeneratedColumn<String> lastIpAddress = GeneratedColumn<String>(
      'last_ip_address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, name, lastSeen, lastIpAddress];
  @override
  String get aliasedName => _alias ?? 'devices';
  @override
  String get actualTableName => 'devices';
  @override
  VerificationContext validateIntegrity(Insertable<DeviceRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('last_seen')) {
      context.handle(_lastSeenMeta,
          lastSeen.isAcceptableOrUnknown(data['last_seen']!, _lastSeenMeta));
    }
    if (data.containsKey('last_ip_address')) {
      context.handle(
          _lastIpAddressMeta,
          lastIpAddress.isAcceptableOrUnknown(
              data['last_ip_address']!, _lastIpAddressMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeviceRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      lastSeen: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_seen']),
      lastIpAddress: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_ip_address']),
    );
  }

  @override
  $DevicesTable createAlias(String alias) {
    return $DevicesTable(attachedDatabase, alias);
  }
}

class DeviceRecord extends DataClass implements Insertable<DeviceRecord> {
  final String id;
  final String userId;
  final String? name;
  final DateTime? lastSeen;
  final String? lastIpAddress;
  const DeviceRecord(
      {required this.id,
      required this.userId,
      this.name,
      this.lastSeen,
      this.lastIpAddress});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || lastSeen != null) {
      map['last_seen'] = Variable<DateTime>(lastSeen);
    }
    if (!nullToAbsent || lastIpAddress != null) {
      map['last_ip_address'] = Variable<String>(lastIpAddress);
    }
    return map;
  }

  DevicesCompanion toCompanion(bool nullToAbsent) {
    return DevicesCompanion(
      id: Value(id),
      userId: Value(userId),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      lastSeen: lastSeen == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeen),
      lastIpAddress: lastIpAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(lastIpAddress),
    );
  }

  factory DeviceRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceRecord(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String?>(json['name']),
      lastSeen: serializer.fromJson<DateTime?>(json['lastSeen']),
      lastIpAddress: serializer.fromJson<String?>(json['lastIpAddress']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String?>(name),
      'lastSeen': serializer.toJson<DateTime?>(lastSeen),
      'lastIpAddress': serializer.toJson<String?>(lastIpAddress),
    };
  }

  DeviceRecord copyWith(
          {String? id,
          String? userId,
          Value<String?> name = const Value.absent(),
          Value<DateTime?> lastSeen = const Value.absent(),
          Value<String?> lastIpAddress = const Value.absent()}) =>
      DeviceRecord(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name.present ? name.value : this.name,
        lastSeen: lastSeen.present ? lastSeen.value : this.lastSeen,
        lastIpAddress:
            lastIpAddress.present ? lastIpAddress.value : this.lastIpAddress,
      );
  @override
  String toString() {
    return (StringBuffer('DeviceRecord(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('lastIpAddress: $lastIpAddress')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, name, lastSeen, lastIpAddress);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceRecord &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.lastSeen == this.lastSeen &&
          other.lastIpAddress == this.lastIpAddress);
}

class DevicesCompanion extends UpdateCompanion<DeviceRecord> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> name;
  final Value<DateTime?> lastSeen;
  final Value<String?> lastIpAddress;
  final Value<int> rowid;
  const DevicesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.lastSeen = const Value.absent(),
    this.lastIpAddress = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DevicesCompanion.insert({
    required String id,
    required String userId,
    this.name = const Value.absent(),
    this.lastSeen = const Value.absent(),
    this.lastIpAddress = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId);
  static Insertable<DeviceRecord> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<DateTime>? lastSeen,
    Expression<String>? lastIpAddress,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (lastSeen != null) 'last_seen': lastSeen,
      if (lastIpAddress != null) 'last_ip_address': lastIpAddress,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DevicesCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String?>? name,
      Value<DateTime?>? lastSeen,
      Value<String?>? lastIpAddress,
      Value<int>? rowid}) {
    return DevicesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      lastSeen: lastSeen ?? this.lastSeen,
      lastIpAddress: lastIpAddress ?? this.lastIpAddress,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (lastSeen.present) {
      map['last_seen'] = Variable<DateTime>(lastSeen.value);
    }
    if (lastIpAddress.present) {
      map['last_ip_address'] = Variable<String>(lastIpAddress.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DevicesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('lastIpAddress: $lastIpAddress, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MyUsersTable extends MyUsers
    with TableInfo<$MyUsersTable, MyUserRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MyUsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _homeserverMeta =
      const VerificationMeta('homeserver');
  @override
  late final GeneratedColumn<String> homeserver = GeneratedColumn<String>(
      'homeserver', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _avatarUrlMeta =
      const VerificationMeta('avatarUrl');
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
      'avatar_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _accessTokenMeta =
      const VerificationMeta('accessToken');
  @override
  late final GeneratedColumn<String> accessToken = GeneratedColumn<String>(
      'access_token', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncTokenMeta =
      const VerificationMeta('syncToken');
  @override
  late final GeneratedColumn<String> syncToken = GeneratedColumn<String>(
      'sync_token', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _currentDeviceIdMeta =
      const VerificationMeta('currentDeviceId');
  @override
  late final GeneratedColumn<String> currentDeviceId = GeneratedColumn<String>(
      'current_device_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'REFERENCES devices(id)');
  static const VerificationMeta _hasSyncedMeta =
      const VerificationMeta('hasSynced');
  @override
  late final GeneratedColumn<bool> hasSynced =
      GeneratedColumn<bool>('has_synced', aliasedName, true,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintsDependsOnDialect({
            SqlDialect.sqlite: 'CHECK ("has_synced" IN (0, 1))',
            SqlDialect.mysql: '',
            SqlDialect.postgres: '',
          }));
  static const VerificationMeta _isLoggedOutMeta =
      const VerificationMeta('isLoggedOut');
  @override
  late final GeneratedColumn<bool> isLoggedOut =
      GeneratedColumn<bool>('is_logged_out', aliasedName, true,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintsDependsOnDialect({
            SqlDialect.sqlite: 'CHECK ("is_logged_out" IN (0, 1))',
            SqlDialect.mysql: '',
            SqlDialect.postgres: '',
          }));
  @override
  List<GeneratedColumn> get $columns => [
        homeserver,
        id,
        name,
        avatarUrl,
        accessToken,
        syncToken,
        currentDeviceId,
        hasSynced,
        isLoggedOut
      ];
  @override
  String get aliasedName => _alias ?? 'my_users';
  @override
  String get actualTableName => 'my_users';
  @override
  VerificationContext validateIntegrity(Insertable<MyUserRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('homeserver')) {
      context.handle(
          _homeserverMeta,
          homeserver.isAcceptableOrUnknown(
              data['homeserver']!, _homeserverMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('avatar_url')) {
      context.handle(_avatarUrlMeta,
          avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta));
    }
    if (data.containsKey('access_token')) {
      context.handle(
          _accessTokenMeta,
          accessToken.isAcceptableOrUnknown(
              data['access_token']!, _accessTokenMeta));
    }
    if (data.containsKey('sync_token')) {
      context.handle(_syncTokenMeta,
          syncToken.isAcceptableOrUnknown(data['sync_token']!, _syncTokenMeta));
    }
    if (data.containsKey('current_device_id')) {
      context.handle(
          _currentDeviceIdMeta,
          currentDeviceId.isAcceptableOrUnknown(
              data['current_device_id']!, _currentDeviceIdMeta));
    }
    if (data.containsKey('has_synced')) {
      context.handle(_hasSyncedMeta,
          hasSynced.isAcceptableOrUnknown(data['has_synced']!, _hasSyncedMeta));
    }
    if (data.containsKey('is_logged_out')) {
      context.handle(
          _isLoggedOutMeta,
          isLoggedOut.isAcceptableOrUnknown(
              data['is_logged_out']!, _isLoggedOutMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MyUserRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MyUserRecord(
      homeserver: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}homeserver']),
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      avatarUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}avatar_url']),
      accessToken: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}access_token']),
      syncToken: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_token']),
      currentDeviceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}current_device_id']),
      hasSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}has_synced']),
      isLoggedOut: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_logged_out']),
    );
  }

  @override
  $MyUsersTable createAlias(String alias) {
    return $MyUsersTable(attachedDatabase, alias);
  }
}

class MyUserRecord extends DataClass implements Insertable<MyUserRecord> {
  final String? homeserver;
  final String? id;
  final String? name;
  final String? avatarUrl;
  final String? accessToken;
  final String? syncToken;
  final String? currentDeviceId;
  final bool? hasSynced;
  final bool? isLoggedOut;
  const MyUserRecord(
      {this.homeserver,
      this.id,
      this.name,
      this.avatarUrl,
      this.accessToken,
      this.syncToken,
      this.currentDeviceId,
      this.hasSynced,
      this.isLoggedOut});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || homeserver != null) {
      map['homeserver'] = Variable<String>(homeserver);
    }
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<String>(id);
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    if (!nullToAbsent || accessToken != null) {
      map['access_token'] = Variable<String>(accessToken);
    }
    if (!nullToAbsent || syncToken != null) {
      map['sync_token'] = Variable<String>(syncToken);
    }
    if (!nullToAbsent || currentDeviceId != null) {
      map['current_device_id'] = Variable<String>(currentDeviceId);
    }
    if (!nullToAbsent || hasSynced != null) {
      map['has_synced'] = Variable<bool>(hasSynced);
    }
    if (!nullToAbsent || isLoggedOut != null) {
      map['is_logged_out'] = Variable<bool>(isLoggedOut);
    }
    return map;
  }

  MyUsersCompanion toCompanion(bool nullToAbsent) {
    return MyUsersCompanion(
      homeserver: homeserver == null && nullToAbsent
          ? const Value.absent()
          : Value(homeserver),
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
      accessToken: accessToken == null && nullToAbsent
          ? const Value.absent()
          : Value(accessToken),
      syncToken: syncToken == null && nullToAbsent
          ? const Value.absent()
          : Value(syncToken),
      currentDeviceId: currentDeviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(currentDeviceId),
      hasSynced: hasSynced == null && nullToAbsent
          ? const Value.absent()
          : Value(hasSynced),
      isLoggedOut: isLoggedOut == null && nullToAbsent
          ? const Value.absent()
          : Value(isLoggedOut),
    );
  }

  factory MyUserRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MyUserRecord(
      homeserver: serializer.fromJson<String?>(json['homeserver']),
      id: serializer.fromJson<String?>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      accessToken: serializer.fromJson<String?>(json['accessToken']),
      syncToken: serializer.fromJson<String?>(json['syncToken']),
      currentDeviceId: serializer.fromJson<String?>(json['currentDeviceId']),
      hasSynced: serializer.fromJson<bool?>(json['hasSynced']),
      isLoggedOut: serializer.fromJson<bool?>(json['isLoggedOut']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'homeserver': serializer.toJson<String?>(homeserver),
      'id': serializer.toJson<String?>(id),
      'name': serializer.toJson<String?>(name),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'accessToken': serializer.toJson<String?>(accessToken),
      'syncToken': serializer.toJson<String?>(syncToken),
      'currentDeviceId': serializer.toJson<String?>(currentDeviceId),
      'hasSynced': serializer.toJson<bool?>(hasSynced),
      'isLoggedOut': serializer.toJson<bool?>(isLoggedOut),
    };
  }

  MyUserRecord copyWith(
          {Value<String?> homeserver = const Value.absent(),
          Value<String?> id = const Value.absent(),
          Value<String?> name = const Value.absent(),
          Value<String?> avatarUrl = const Value.absent(),
          Value<String?> accessToken = const Value.absent(),
          Value<String?> syncToken = const Value.absent(),
          Value<String?> currentDeviceId = const Value.absent(),
          Value<bool?> hasSynced = const Value.absent(),
          Value<bool?> isLoggedOut = const Value.absent()}) =>
      MyUserRecord(
        homeserver: homeserver.present ? homeserver.value : this.homeserver,
        id: id.present ? id.value : this.id,
        name: name.present ? name.value : this.name,
        avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
        accessToken: accessToken.present ? accessToken.value : this.accessToken,
        syncToken: syncToken.present ? syncToken.value : this.syncToken,
        currentDeviceId: currentDeviceId.present
            ? currentDeviceId.value
            : this.currentDeviceId,
        hasSynced: hasSynced.present ? hasSynced.value : this.hasSynced,
        isLoggedOut: isLoggedOut.present ? isLoggedOut.value : this.isLoggedOut,
      );
  @override
  String toString() {
    return (StringBuffer('MyUserRecord(')
          ..write('homeserver: $homeserver, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('accessToken: $accessToken, ')
          ..write('syncToken: $syncToken, ')
          ..write('currentDeviceId: $currentDeviceId, ')
          ..write('hasSynced: $hasSynced, ')
          ..write('isLoggedOut: $isLoggedOut')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(homeserver, id, name, avatarUrl, accessToken,
      syncToken, currentDeviceId, hasSynced, isLoggedOut);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MyUserRecord &&
          other.homeserver == this.homeserver &&
          other.id == this.id &&
          other.name == this.name &&
          other.avatarUrl == this.avatarUrl &&
          other.accessToken == this.accessToken &&
          other.syncToken == this.syncToken &&
          other.currentDeviceId == this.currentDeviceId &&
          other.hasSynced == this.hasSynced &&
          other.isLoggedOut == this.isLoggedOut);
}

class MyUsersCompanion extends UpdateCompanion<MyUserRecord> {
  final Value<String?> homeserver;
  final Value<String?> id;
  final Value<String?> name;
  final Value<String?> avatarUrl;
  final Value<String?> accessToken;
  final Value<String?> syncToken;
  final Value<String?> currentDeviceId;
  final Value<bool?> hasSynced;
  final Value<bool?> isLoggedOut;
  final Value<int> rowid;
  const MyUsersCompanion({
    this.homeserver = const Value.absent(),
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.accessToken = const Value.absent(),
    this.syncToken = const Value.absent(),
    this.currentDeviceId = const Value.absent(),
    this.hasSynced = const Value.absent(),
    this.isLoggedOut = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MyUsersCompanion.insert({
    this.homeserver = const Value.absent(),
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.accessToken = const Value.absent(),
    this.syncToken = const Value.absent(),
    this.currentDeviceId = const Value.absent(),
    this.hasSynced = const Value.absent(),
    this.isLoggedOut = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<MyUserRecord> custom({
    Expression<String>? homeserver,
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? avatarUrl,
    Expression<String>? accessToken,
    Expression<String>? syncToken,
    Expression<String>? currentDeviceId,
    Expression<bool>? hasSynced,
    Expression<bool>? isLoggedOut,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (homeserver != null) 'homeserver': homeserver,
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (accessToken != null) 'access_token': accessToken,
      if (syncToken != null) 'sync_token': syncToken,
      if (currentDeviceId != null) 'current_device_id': currentDeviceId,
      if (hasSynced != null) 'has_synced': hasSynced,
      if (isLoggedOut != null) 'is_logged_out': isLoggedOut,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MyUsersCompanion copyWith(
      {Value<String?>? homeserver,
      Value<String?>? id,
      Value<String?>? name,
      Value<String?>? avatarUrl,
      Value<String?>? accessToken,
      Value<String?>? syncToken,
      Value<String?>? currentDeviceId,
      Value<bool?>? hasSynced,
      Value<bool?>? isLoggedOut,
      Value<int>? rowid}) {
    return MyUsersCompanion(
      homeserver: homeserver ?? this.homeserver,
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      accessToken: accessToken ?? this.accessToken,
      syncToken: syncToken ?? this.syncToken,
      currentDeviceId: currentDeviceId ?? this.currentDeviceId,
      hasSynced: hasSynced ?? this.hasSynced,
      isLoggedOut: isLoggedOut ?? this.isLoggedOut,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (homeserver.present) {
      map['homeserver'] = Variable<String>(homeserver.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (accessToken.present) {
      map['access_token'] = Variable<String>(accessToken.value);
    }
    if (syncToken.present) {
      map['sync_token'] = Variable<String>(syncToken.value);
    }
    if (currentDeviceId.present) {
      map['current_device_id'] = Variable<String>(currentDeviceId.value);
    }
    if (hasSynced.present) {
      map['has_synced'] = Variable<bool>(hasSynced.value);
    }
    if (isLoggedOut.present) {
      map['is_logged_out'] = Variable<bool>(isLoggedOut.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MyUsersCompanion(')
          ..write('homeserver: $homeserver, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('accessToken: $accessToken, ')
          ..write('syncToken: $syncToken, ')
          ..write('currentDeviceId: $currentDeviceId, ')
          ..write('hasSynced: $hasSynced, ')
          ..write('isLoggedOut: $isLoggedOut, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoomEventsTable extends RoomEvents
    with TableInfo<$RoomEventsTable, RoomEventRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoomEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _networkIdMeta =
      const VerificationMeta('networkId');
  @override
  late final GeneratedColumn<String> networkId = GeneratedColumn<String>(
      'network_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<String> roomId = GeneratedColumn<String>(
      'room_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'REFERENCES room_events(id)');
  static const VerificationMeta _senderIdMeta =
      const VerificationMeta('senderId');
  @override
  late final GeneratedColumn<String> senderId = GeneratedColumn<String>(
      'sender_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<DateTime> time = GeneratedColumn<DateTime>(
      'time', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _previousContentMeta =
      const VerificationMeta('previousContent');
  @override
  late final GeneratedColumn<String> previousContent = GeneratedColumn<String>(
      'previous_content', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sentStateMeta =
      const VerificationMeta('sentState');
  @override
  late final GeneratedColumn<String> sentState = GeneratedColumn<String>(
      'sent_state', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _transactionIdMeta =
      const VerificationMeta('transactionId');
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
      'transaction_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _stateKeyMeta =
      const VerificationMeta('stateKey');
  @override
  late final GeneratedColumn<String> stateKey = GeneratedColumn<String>(
      'state_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _redactsMeta =
      const VerificationMeta('redacts');
  @override
  late final GeneratedColumn<String> redacts = GeneratedColumn<String>(
      'redacts', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _inTimelineMeta =
      const VerificationMeta('inTimeline');
  @override
  late final GeneratedColumn<bool> inTimeline =
      GeneratedColumn<bool>('in_timeline', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: true,
          defaultConstraints: GeneratedColumn.constraintsDependsOnDialect({
            SqlDialect.sqlite: 'CHECK ("in_timeline" IN (0, 1))',
            SqlDialect.mysql: '',
            SqlDialect.postgres: '',
          }));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        networkId,
        type,
        roomId,
        senderId,
        time,
        content,
        previousContent,
        sentState,
        transactionId,
        stateKey,
        redacts,
        inTimeline
      ];
  @override
  String get aliasedName => _alias ?? 'room_events';
  @override
  String get actualTableName => 'room_events';
  @override
  VerificationContext validateIntegrity(Insertable<RoomEventRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('network_id')) {
      context.handle(_networkIdMeta,
          networkId.isAcceptableOrUnknown(data['network_id']!, _networkIdMeta));
    } else if (isInserting) {
      context.missing(_networkIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('room_id')) {
      context.handle(_roomIdMeta,
          roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta));
    } else if (isInserting) {
      context.missing(_roomIdMeta);
    }
    if (data.containsKey('sender_id')) {
      context.handle(_senderIdMeta,
          senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta));
    } else if (isInserting) {
      context.missing(_senderIdMeta);
    }
    if (data.containsKey('time')) {
      context.handle(
          _timeMeta, time.isAcceptableOrUnknown(data['time']!, _timeMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    if (data.containsKey('previous_content')) {
      context.handle(
          _previousContentMeta,
          previousContent.isAcceptableOrUnknown(
              data['previous_content']!, _previousContentMeta));
    }
    if (data.containsKey('sent_state')) {
      context.handle(_sentStateMeta,
          sentState.isAcceptableOrUnknown(data['sent_state']!, _sentStateMeta));
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
          _transactionIdMeta,
          transactionId.isAcceptableOrUnknown(
              data['transaction_id']!, _transactionIdMeta));
    }
    if (data.containsKey('state_key')) {
      context.handle(_stateKeyMeta,
          stateKey.isAcceptableOrUnknown(data['state_key']!, _stateKeyMeta));
    }
    if (data.containsKey('redacts')) {
      context.handle(_redactsMeta,
          redacts.isAcceptableOrUnknown(data['redacts']!, _redactsMeta));
    }
    if (data.containsKey('in_timeline')) {
      context.handle(
          _inTimelineMeta,
          inTimeline.isAcceptableOrUnknown(
              data['in_timeline']!, _inTimelineMeta));
    } else if (isInserting) {
      context.missing(_inTimelineMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoomEventRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoomEventRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      networkId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}network_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      roomId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}room_id'])!,
      senderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender_id'])!,
      time: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}time']),
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content']),
      previousContent: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}previous_content']),
      sentState: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sent_state']),
      transactionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transaction_id']),
      stateKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}state_key']),
      redacts: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}redacts']),
      inTimeline: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}in_timeline'])!,
    );
  }

  @override
  $RoomEventsTable createAlias(String alias) {
    return $RoomEventsTable(attachedDatabase, alias);
  }
}

class RoomEventRecord extends DataClass implements Insertable<RoomEventRecord> {
  final String id;
  final String networkId;
  final String type;
  final String roomId;
  final String senderId;
  final DateTime? time;
  final String? content;
  final String? previousContent;
  final String? sentState;
  final String? transactionId;
  final String? stateKey;
  final String? redacts;
  final bool inTimeline;
  const RoomEventRecord(
      {required this.id,
      required this.networkId,
      required this.type,
      required this.roomId,
      required this.senderId,
      this.time,
      this.content,
      this.previousContent,
      this.sentState,
      this.transactionId,
      this.stateKey,
      this.redacts,
      required this.inTimeline});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['network_id'] = Variable<String>(networkId);
    map['type'] = Variable<String>(type);
    map['room_id'] = Variable<String>(roomId);
    map['sender_id'] = Variable<String>(senderId);
    if (!nullToAbsent || time != null) {
      map['time'] = Variable<DateTime>(time);
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    if (!nullToAbsent || previousContent != null) {
      map['previous_content'] = Variable<String>(previousContent);
    }
    if (!nullToAbsent || sentState != null) {
      map['sent_state'] = Variable<String>(sentState);
    }
    if (!nullToAbsent || transactionId != null) {
      map['transaction_id'] = Variable<String>(transactionId);
    }
    if (!nullToAbsent || stateKey != null) {
      map['state_key'] = Variable<String>(stateKey);
    }
    if (!nullToAbsent || redacts != null) {
      map['redacts'] = Variable<String>(redacts);
    }
    map['in_timeline'] = Variable<bool>(inTimeline);
    return map;
  }

  RoomEventsCompanion toCompanion(bool nullToAbsent) {
    return RoomEventsCompanion(
      id: Value(id),
      networkId: Value(networkId),
      type: Value(type),
      roomId: Value(roomId),
      senderId: Value(senderId),
      time: time == null && nullToAbsent ? const Value.absent() : Value(time),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      previousContent: previousContent == null && nullToAbsent
          ? const Value.absent()
          : Value(previousContent),
      sentState: sentState == null && nullToAbsent
          ? const Value.absent()
          : Value(sentState),
      transactionId: transactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionId),
      stateKey: stateKey == null && nullToAbsent
          ? const Value.absent()
          : Value(stateKey),
      redacts: redacts == null && nullToAbsent
          ? const Value.absent()
          : Value(redacts),
      inTimeline: Value(inTimeline),
    );
  }

  factory RoomEventRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoomEventRecord(
      id: serializer.fromJson<String>(json['id']),
      networkId: serializer.fromJson<String>(json['networkId']),
      type: serializer.fromJson<String>(json['type']),
      roomId: serializer.fromJson<String>(json['roomId']),
      senderId: serializer.fromJson<String>(json['senderId']),
      time: serializer.fromJson<DateTime?>(json['time']),
      content: serializer.fromJson<String?>(json['content']),
      previousContent: serializer.fromJson<String?>(json['previousContent']),
      sentState: serializer.fromJson<String?>(json['sentState']),
      transactionId: serializer.fromJson<String?>(json['transactionId']),
      stateKey: serializer.fromJson<String?>(json['stateKey']),
      redacts: serializer.fromJson<String?>(json['redacts']),
      inTimeline: serializer.fromJson<bool>(json['inTimeline']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'networkId': serializer.toJson<String>(networkId),
      'type': serializer.toJson<String>(type),
      'roomId': serializer.toJson<String>(roomId),
      'senderId': serializer.toJson<String>(senderId),
      'time': serializer.toJson<DateTime?>(time),
      'content': serializer.toJson<String?>(content),
      'previousContent': serializer.toJson<String?>(previousContent),
      'sentState': serializer.toJson<String?>(sentState),
      'transactionId': serializer.toJson<String?>(transactionId),
      'stateKey': serializer.toJson<String?>(stateKey),
      'redacts': serializer.toJson<String?>(redacts),
      'inTimeline': serializer.toJson<bool>(inTimeline),
    };
  }

  RoomEventRecord copyWith(
          {String? id,
          String? networkId,
          String? type,
          String? roomId,
          String? senderId,
          Value<DateTime?> time = const Value.absent(),
          Value<String?> content = const Value.absent(),
          Value<String?> previousContent = const Value.absent(),
          Value<String?> sentState = const Value.absent(),
          Value<String?> transactionId = const Value.absent(),
          Value<String?> stateKey = const Value.absent(),
          Value<String?> redacts = const Value.absent(),
          bool? inTimeline}) =>
      RoomEventRecord(
        id: id ?? this.id,
        networkId: networkId ?? this.networkId,
        type: type ?? this.type,
        roomId: roomId ?? this.roomId,
        senderId: senderId ?? this.senderId,
        time: time.present ? time.value : this.time,
        content: content.present ? content.value : this.content,
        previousContent: previousContent.present
            ? previousContent.value
            : this.previousContent,
        sentState: sentState.present ? sentState.value : this.sentState,
        transactionId:
            transactionId.present ? transactionId.value : this.transactionId,
        stateKey: stateKey.present ? stateKey.value : this.stateKey,
        redacts: redacts.present ? redacts.value : this.redacts,
        inTimeline: inTimeline ?? this.inTimeline,
      );
  @override
  String toString() {
    return (StringBuffer('RoomEventRecord(')
          ..write('id: $id, ')
          ..write('networkId: $networkId, ')
          ..write('type: $type, ')
          ..write('roomId: $roomId, ')
          ..write('senderId: $senderId, ')
          ..write('time: $time, ')
          ..write('content: $content, ')
          ..write('previousContent: $previousContent, ')
          ..write('sentState: $sentState, ')
          ..write('transactionId: $transactionId, ')
          ..write('stateKey: $stateKey, ')
          ..write('redacts: $redacts, ')
          ..write('inTimeline: $inTimeline')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      networkId,
      type,
      roomId,
      senderId,
      time,
      content,
      previousContent,
      sentState,
      transactionId,
      stateKey,
      redacts,
      inTimeline);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoomEventRecord &&
          other.id == this.id &&
          other.networkId == this.networkId &&
          other.type == this.type &&
          other.roomId == this.roomId &&
          other.senderId == this.senderId &&
          other.time == this.time &&
          other.content == this.content &&
          other.previousContent == this.previousContent &&
          other.sentState == this.sentState &&
          other.transactionId == this.transactionId &&
          other.stateKey == this.stateKey &&
          other.redacts == this.redacts &&
          other.inTimeline == this.inTimeline);
}

class RoomEventsCompanion extends UpdateCompanion<RoomEventRecord> {
  final Value<String> id;
  final Value<String> networkId;
  final Value<String> type;
  final Value<String> roomId;
  final Value<String> senderId;
  final Value<DateTime?> time;
  final Value<String?> content;
  final Value<String?> previousContent;
  final Value<String?> sentState;
  final Value<String?> transactionId;
  final Value<String?> stateKey;
  final Value<String?> redacts;
  final Value<bool> inTimeline;
  final Value<int> rowid;
  const RoomEventsCompanion({
    this.id = const Value.absent(),
    this.networkId = const Value.absent(),
    this.type = const Value.absent(),
    this.roomId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.time = const Value.absent(),
    this.content = const Value.absent(),
    this.previousContent = const Value.absent(),
    this.sentState = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.stateKey = const Value.absent(),
    this.redacts = const Value.absent(),
    this.inTimeline = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoomEventsCompanion.insert({
    required String id,
    required String networkId,
    required String type,
    required String roomId,
    required String senderId,
    this.time = const Value.absent(),
    this.content = const Value.absent(),
    this.previousContent = const Value.absent(),
    this.sentState = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.stateKey = const Value.absent(),
    this.redacts = const Value.absent(),
    required bool inTimeline,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        networkId = Value(networkId),
        type = Value(type),
        roomId = Value(roomId),
        senderId = Value(senderId),
        inTimeline = Value(inTimeline);
  static Insertable<RoomEventRecord> custom({
    Expression<String>? id,
    Expression<String>? networkId,
    Expression<String>? type,
    Expression<String>? roomId,
    Expression<String>? senderId,
    Expression<DateTime>? time,
    Expression<String>? content,
    Expression<String>? previousContent,
    Expression<String>? sentState,
    Expression<String>? transactionId,
    Expression<String>? stateKey,
    Expression<String>? redacts,
    Expression<bool>? inTimeline,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (networkId != null) 'network_id': networkId,
      if (type != null) 'type': type,
      if (roomId != null) 'room_id': roomId,
      if (senderId != null) 'sender_id': senderId,
      if (time != null) 'time': time,
      if (content != null) 'content': content,
      if (previousContent != null) 'previous_content': previousContent,
      if (sentState != null) 'sent_state': sentState,
      if (transactionId != null) 'transaction_id': transactionId,
      if (stateKey != null) 'state_key': stateKey,
      if (redacts != null) 'redacts': redacts,
      if (inTimeline != null) 'in_timeline': inTimeline,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoomEventsCompanion copyWith(
      {Value<String>? id,
      Value<String>? networkId,
      Value<String>? type,
      Value<String>? roomId,
      Value<String>? senderId,
      Value<DateTime?>? time,
      Value<String?>? content,
      Value<String?>? previousContent,
      Value<String?>? sentState,
      Value<String?>? transactionId,
      Value<String?>? stateKey,
      Value<String?>? redacts,
      Value<bool>? inTimeline,
      Value<int>? rowid}) {
    return RoomEventsCompanion(
      id: id ?? this.id,
      networkId: networkId ?? this.networkId,
      type: type ?? this.type,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      time: time ?? this.time,
      content: content ?? this.content,
      previousContent: previousContent ?? this.previousContent,
      sentState: sentState ?? this.sentState,
      transactionId: transactionId ?? this.transactionId,
      stateKey: stateKey ?? this.stateKey,
      redacts: redacts ?? this.redacts,
      inTimeline: inTimeline ?? this.inTimeline,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (networkId.present) {
      map['network_id'] = Variable<String>(networkId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (roomId.present) {
      map['room_id'] = Variable<String>(roomId.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<String>(senderId.value);
    }
    if (time.present) {
      map['time'] = Variable<DateTime>(time.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (previousContent.present) {
      map['previous_content'] = Variable<String>(previousContent.value);
    }
    if (sentState.present) {
      map['sent_state'] = Variable<String>(sentState.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (stateKey.present) {
      map['state_key'] = Variable<String>(stateKey.value);
    }
    if (redacts.present) {
      map['redacts'] = Variable<String>(redacts.value);
    }
    if (inTimeline.present) {
      map['in_timeline'] = Variable<bool>(inTimeline.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoomEventsCompanion(')
          ..write('id: $id, ')
          ..write('networkId: $networkId, ')
          ..write('type: $type, ')
          ..write('roomId: $roomId, ')
          ..write('senderId: $senderId, ')
          ..write('time: $time, ')
          ..write('content: $content, ')
          ..write('previousContent: $previousContent, ')
          ..write('sentState: $sentState, ')
          ..write('transactionId: $transactionId, ')
          ..write('stateKey: $stateKey, ')
          ..write('redacts: $redacts, ')
          ..write('inTimeline: $inTimeline, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoomsTable extends Rooms with TableInfo<$RoomsTable, RoomRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoomsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _myMembershipMeta =
      const VerificationMeta('myMembership');
  @override
  late final GeneratedColumn<String> myMembership = GeneratedColumn<String>(
      'my_membership', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timelinePreviousBatchMeta =
      const VerificationMeta('timelinePreviousBatch');
  @override
  late final GeneratedColumn<String> timelinePreviousBatch =
      GeneratedColumn<String>('timeline_previous_batch', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _timelinePreviousBatchSetBySyncMeta =
      const VerificationMeta('timelinePreviousBatchSetBySync');
  @override
  late final GeneratedColumn<bool> timelinePreviousBatchSetBySync =
      GeneratedColumn<bool>(
          'timeline_previous_batch_set_by_sync', aliasedName, true,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintsDependsOnDialect({
            SqlDialect.sqlite:
                'CHECK ("timeline_previous_batch_set_by_sync" IN (0, 1))',
            SqlDialect.mysql: '',
            SqlDialect.postgres: '',
          }));
  static const VerificationMeta _summaryJoinedMembersCountMeta =
      const VerificationMeta('summaryJoinedMembersCount');
  @override
  late final GeneratedColumn<int> summaryJoinedMembersCount =
      GeneratedColumn<int>('summary_joined_members_count', aliasedName, true,
          type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _summaryInvitedMembersCountMeta =
      const VerificationMeta('summaryInvitedMembersCount');
  @override
  late final GeneratedColumn<int> summaryInvitedMembersCount =
      GeneratedColumn<int>('summary_invited_members_count', aliasedName, true,
          type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameChangeEventIdMeta =
      const VerificationMeta('nameChangeEventId');
  @override
  late final GeneratedColumn<String> nameChangeEventId =
      GeneratedColumn<String>('name_change_event_id', aliasedName, true,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          $customConstraints: 'REFERENCES room_events(id)');
  static const VerificationMeta _avatarChangeEventIdMeta =
      const VerificationMeta('avatarChangeEventId');
  @override
  late final GeneratedColumn<String> avatarChangeEventId =
      GeneratedColumn<String>('avatar_change_event_id', aliasedName, true,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          $customConstraints: 'REFERENCES room_events(id)');
  static const VerificationMeta _topicChangeEventIdMeta =
      const VerificationMeta('topicChangeEventId');
  @override
  late final GeneratedColumn<String> topicChangeEventId =
      GeneratedColumn<String>('topic_change_event_id', aliasedName, true,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          $customConstraints: 'REFERENCES room_events(id)');
  static const VerificationMeta _powerLevelsChangeEventIdMeta =
      const VerificationMeta('powerLevelsChangeEventId');
  @override
  late final GeneratedColumn<String> powerLevelsChangeEventId =
      GeneratedColumn<String>('power_levels_change_event_id', aliasedName, true,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          $customConstraints: 'REFERENCES room_events(id)');
  static const VerificationMeta _joinRulesChangeEventIdMeta =
      const VerificationMeta('joinRulesChangeEventId');
  @override
  late final GeneratedColumn<String> joinRulesChangeEventId =
      GeneratedColumn<String>('join_rules_change_event_id', aliasedName, true,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          $customConstraints: 'REFERENCES room_events(id)');
  static const VerificationMeta _canonicalAliasChangeEventIdMeta =
      const VerificationMeta('canonicalAliasChangeEventId');
  @override
  late final GeneratedColumn<String> canonicalAliasChangeEventId =
      GeneratedColumn<String>(
          'canonical_alias_change_event_id', aliasedName, true,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          $customConstraints: 'REFERENCES room_events(id)');
  static const VerificationMeta _creationEventIdMeta =
      const VerificationMeta('creationEventId');
  @override
  late final GeneratedColumn<String> creationEventId = GeneratedColumn<String>(
      'creation_event_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'REFERENCES room_events(id)');
  static const VerificationMeta _upgradeEventIdMeta =
      const VerificationMeta('upgradeEventId');
  @override
  late final GeneratedColumn<String> upgradeEventId = GeneratedColumn<String>(
      'upgrade_event_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'REFERENCES room_events(id)');
  static const VerificationMeta _highlightedUnreadNotificationCountMeta =
      const VerificationMeta('highlightedUnreadNotificationCount');
  @override
  late final GeneratedColumn<int> highlightedUnreadNotificationCount =
      GeneratedColumn<int>(
          'highlighted_unread_notification_count', aliasedName, true,
          type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _totalUnreadNotificationCountMeta =
      const VerificationMeta('totalUnreadNotificationCount');
  @override
  late final GeneratedColumn<int> totalUnreadNotificationCount =
      GeneratedColumn<int>('total_unread_notification_count', aliasedName, true,
          type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lastMessageTimeIntervalMeta =
      const VerificationMeta('lastMessageTimeInterval');
  @override
  late final GeneratedColumn<int> lastMessageTimeInterval =
      GeneratedColumn<int>('last_message_time_interval', aliasedName, false,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultValue: const Constant(0));
  static const VerificationMeta _directUserIdMeta =
      const VerificationMeta('directUserId');
  @override
  late final GeneratedColumn<String> directUserId = GeneratedColumn<String>(
      'direct_user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        myMembership,
        id,
        timelinePreviousBatch,
        timelinePreviousBatchSetBySync,
        summaryJoinedMembersCount,
        summaryInvitedMembersCount,
        nameChangeEventId,
        avatarChangeEventId,
        topicChangeEventId,
        powerLevelsChangeEventId,
        joinRulesChangeEventId,
        canonicalAliasChangeEventId,
        creationEventId,
        upgradeEventId,
        highlightedUnreadNotificationCount,
        totalUnreadNotificationCount,
        lastMessageTimeInterval,
        directUserId
      ];
  @override
  String get aliasedName => _alias ?? 'rooms';
  @override
  String get actualTableName => 'rooms';
  @override
  VerificationContext validateIntegrity(Insertable<RoomRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('my_membership')) {
      context.handle(
          _myMembershipMeta,
          myMembership.isAcceptableOrUnknown(
              data['my_membership']!, _myMembershipMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('timeline_previous_batch')) {
      context.handle(
          _timelinePreviousBatchMeta,
          timelinePreviousBatch.isAcceptableOrUnknown(
              data['timeline_previous_batch']!, _timelinePreviousBatchMeta));
    }
    if (data.containsKey('timeline_previous_batch_set_by_sync')) {
      context.handle(
          _timelinePreviousBatchSetBySyncMeta,
          timelinePreviousBatchSetBySync.isAcceptableOrUnknown(
              data['timeline_previous_batch_set_by_sync']!,
              _timelinePreviousBatchSetBySyncMeta));
    }
    if (data.containsKey('summary_joined_members_count')) {
      context.handle(
          _summaryJoinedMembersCountMeta,
          summaryJoinedMembersCount.isAcceptableOrUnknown(
              data['summary_joined_members_count']!,
              _summaryJoinedMembersCountMeta));
    }
    if (data.containsKey('summary_invited_members_count')) {
      context.handle(
          _summaryInvitedMembersCountMeta,
          summaryInvitedMembersCount.isAcceptableOrUnknown(
              data['summary_invited_members_count']!,
              _summaryInvitedMembersCountMeta));
    }
    if (data.containsKey('name_change_event_id')) {
      context.handle(
          _nameChangeEventIdMeta,
          nameChangeEventId.isAcceptableOrUnknown(
              data['name_change_event_id']!, _nameChangeEventIdMeta));
    }
    if (data.containsKey('avatar_change_event_id')) {
      context.handle(
          _avatarChangeEventIdMeta,
          avatarChangeEventId.isAcceptableOrUnknown(
              data['avatar_change_event_id']!, _avatarChangeEventIdMeta));
    }
    if (data.containsKey('topic_change_event_id')) {
      context.handle(
          _topicChangeEventIdMeta,
          topicChangeEventId.isAcceptableOrUnknown(
              data['topic_change_event_id']!, _topicChangeEventIdMeta));
    }
    if (data.containsKey('power_levels_change_event_id')) {
      context.handle(
          _powerLevelsChangeEventIdMeta,
          powerLevelsChangeEventId.isAcceptableOrUnknown(
              data['power_levels_change_event_id']!,
              _powerLevelsChangeEventIdMeta));
    }
    if (data.containsKey('join_rules_change_event_id')) {
      context.handle(
          _joinRulesChangeEventIdMeta,
          joinRulesChangeEventId.isAcceptableOrUnknown(
              data['join_rules_change_event_id']!,
              _joinRulesChangeEventIdMeta));
    }
    if (data.containsKey('canonical_alias_change_event_id')) {
      context.handle(
          _canonicalAliasChangeEventIdMeta,
          canonicalAliasChangeEventId.isAcceptableOrUnknown(
              data['canonical_alias_change_event_id']!,
              _canonicalAliasChangeEventIdMeta));
    }
    if (data.containsKey('creation_event_id')) {
      context.handle(
          _creationEventIdMeta,
          creationEventId.isAcceptableOrUnknown(
              data['creation_event_id']!, _creationEventIdMeta));
    }
    if (data.containsKey('upgrade_event_id')) {
      context.handle(
          _upgradeEventIdMeta,
          upgradeEventId.isAcceptableOrUnknown(
              data['upgrade_event_id']!, _upgradeEventIdMeta));
    }
    if (data.containsKey('highlighted_unread_notification_count')) {
      context.handle(
          _highlightedUnreadNotificationCountMeta,
          highlightedUnreadNotificationCount.isAcceptableOrUnknown(
              data['highlighted_unread_notification_count']!,
              _highlightedUnreadNotificationCountMeta));
    }
    if (data.containsKey('total_unread_notification_count')) {
      context.handle(
          _totalUnreadNotificationCountMeta,
          totalUnreadNotificationCount.isAcceptableOrUnknown(
              data['total_unread_notification_count']!,
              _totalUnreadNotificationCountMeta));
    }
    if (data.containsKey('last_message_time_interval')) {
      context.handle(
          _lastMessageTimeIntervalMeta,
          lastMessageTimeInterval.isAcceptableOrUnknown(
              data['last_message_time_interval']!,
              _lastMessageTimeIntervalMeta));
    }
    if (data.containsKey('direct_user_id')) {
      context.handle(
          _directUserIdMeta,
          directUserId.isAcceptableOrUnknown(
              data['direct_user_id']!, _directUserIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoomRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoomRecord(
      myMembership: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}my_membership']),
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      timelinePreviousBatch: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}timeline_previous_batch']),
      timelinePreviousBatchSetBySync: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}timeline_previous_batch_set_by_sync']),
      summaryJoinedMembersCount: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}summary_joined_members_count']),
      summaryInvitedMembersCount: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}summary_invited_members_count']),
      nameChangeEventId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}name_change_event_id']),
      avatarChangeEventId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}avatar_change_event_id']),
      topicChangeEventId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}topic_change_event_id']),
      powerLevelsChangeEventId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}power_levels_change_event_id']),
      joinRulesChangeEventId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}join_rules_change_event_id']),
      canonicalAliasChangeEventId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}canonical_alias_change_event_id']),
      creationEventId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}creation_event_id']),
      upgradeEventId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}upgrade_event_id']),
      highlightedUnreadNotificationCount: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}highlighted_unread_notification_count']),
      totalUnreadNotificationCount: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}total_unread_notification_count']),
      lastMessageTimeInterval: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}last_message_time_interval'])!,
      directUserId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}direct_user_id']),
    );
  }

  @override
  $RoomsTable createAlias(String alias) {
    return $RoomsTable(attachedDatabase, alias);
  }
}

class RoomRecord extends DataClass implements Insertable<RoomRecord> {
  final String? myMembership;
  final String id;
  final String? timelinePreviousBatch;
  final bool? timelinePreviousBatchSetBySync;
  final int? summaryJoinedMembersCount;
  final int? summaryInvitedMembersCount;
  final String? nameChangeEventId;
  final String? avatarChangeEventId;
  final String? topicChangeEventId;
  final String? powerLevelsChangeEventId;
  final String? joinRulesChangeEventId;
  final String? canonicalAliasChangeEventId;
  final String? creationEventId;
  final String? upgradeEventId;
  final int? highlightedUnreadNotificationCount;
  final int? totalUnreadNotificationCount;
  final int lastMessageTimeInterval;
  final String? directUserId;
  const RoomRecord(
      {this.myMembership,
      required this.id,
      this.timelinePreviousBatch,
      this.timelinePreviousBatchSetBySync,
      this.summaryJoinedMembersCount,
      this.summaryInvitedMembersCount,
      this.nameChangeEventId,
      this.avatarChangeEventId,
      this.topicChangeEventId,
      this.powerLevelsChangeEventId,
      this.joinRulesChangeEventId,
      this.canonicalAliasChangeEventId,
      this.creationEventId,
      this.upgradeEventId,
      this.highlightedUnreadNotificationCount,
      this.totalUnreadNotificationCount,
      required this.lastMessageTimeInterval,
      this.directUserId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || myMembership != null) {
      map['my_membership'] = Variable<String>(myMembership);
    }
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || timelinePreviousBatch != null) {
      map['timeline_previous_batch'] = Variable<String>(timelinePreviousBatch);
    }
    if (!nullToAbsent || timelinePreviousBatchSetBySync != null) {
      map['timeline_previous_batch_set_by_sync'] =
          Variable<bool>(timelinePreviousBatchSetBySync);
    }
    if (!nullToAbsent || summaryJoinedMembersCount != null) {
      map['summary_joined_members_count'] =
          Variable<int>(summaryJoinedMembersCount);
    }
    if (!nullToAbsent || summaryInvitedMembersCount != null) {
      map['summary_invited_members_count'] =
          Variable<int>(summaryInvitedMembersCount);
    }
    if (!nullToAbsent || nameChangeEventId != null) {
      map['name_change_event_id'] = Variable<String>(nameChangeEventId);
    }
    if (!nullToAbsent || avatarChangeEventId != null) {
      map['avatar_change_event_id'] = Variable<String>(avatarChangeEventId);
    }
    if (!nullToAbsent || topicChangeEventId != null) {
      map['topic_change_event_id'] = Variable<String>(topicChangeEventId);
    }
    if (!nullToAbsent || powerLevelsChangeEventId != null) {
      map['power_levels_change_event_id'] =
          Variable<String>(powerLevelsChangeEventId);
    }
    if (!nullToAbsent || joinRulesChangeEventId != null) {
      map['join_rules_change_event_id'] =
          Variable<String>(joinRulesChangeEventId);
    }
    if (!nullToAbsent || canonicalAliasChangeEventId != null) {
      map['canonical_alias_change_event_id'] =
          Variable<String>(canonicalAliasChangeEventId);
    }
    if (!nullToAbsent || creationEventId != null) {
      map['creation_event_id'] = Variable<String>(creationEventId);
    }
    if (!nullToAbsent || upgradeEventId != null) {
      map['upgrade_event_id'] = Variable<String>(upgradeEventId);
    }
    if (!nullToAbsent || highlightedUnreadNotificationCount != null) {
      map['highlighted_unread_notification_count'] =
          Variable<int>(highlightedUnreadNotificationCount);
    }
    if (!nullToAbsent || totalUnreadNotificationCount != null) {
      map['total_unread_notification_count'] =
          Variable<int>(totalUnreadNotificationCount);
    }
    map['last_message_time_interval'] = Variable<int>(lastMessageTimeInterval);
    if (!nullToAbsent || directUserId != null) {
      map['direct_user_id'] = Variable<String>(directUserId);
    }
    return map;
  }

  RoomsCompanion toCompanion(bool nullToAbsent) {
    return RoomsCompanion(
      myMembership: myMembership == null && nullToAbsent
          ? const Value.absent()
          : Value(myMembership),
      id: Value(id),
      timelinePreviousBatch: timelinePreviousBatch == null && nullToAbsent
          ? const Value.absent()
          : Value(timelinePreviousBatch),
      timelinePreviousBatchSetBySync:
          timelinePreviousBatchSetBySync == null && nullToAbsent
              ? const Value.absent()
              : Value(timelinePreviousBatchSetBySync),
      summaryJoinedMembersCount:
          summaryJoinedMembersCount == null && nullToAbsent
              ? const Value.absent()
              : Value(summaryJoinedMembersCount),
      summaryInvitedMembersCount:
          summaryInvitedMembersCount == null && nullToAbsent
              ? const Value.absent()
              : Value(summaryInvitedMembersCount),
      nameChangeEventId: nameChangeEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(nameChangeEventId),
      avatarChangeEventId: avatarChangeEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarChangeEventId),
      topicChangeEventId: topicChangeEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(topicChangeEventId),
      powerLevelsChangeEventId: powerLevelsChangeEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(powerLevelsChangeEventId),
      joinRulesChangeEventId: joinRulesChangeEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(joinRulesChangeEventId),
      canonicalAliasChangeEventId:
          canonicalAliasChangeEventId == null && nullToAbsent
              ? const Value.absent()
              : Value(canonicalAliasChangeEventId),
      creationEventId: creationEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(creationEventId),
      upgradeEventId: upgradeEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(upgradeEventId),
      highlightedUnreadNotificationCount:
          highlightedUnreadNotificationCount == null && nullToAbsent
              ? const Value.absent()
              : Value(highlightedUnreadNotificationCount),
      totalUnreadNotificationCount:
          totalUnreadNotificationCount == null && nullToAbsent
              ? const Value.absent()
              : Value(totalUnreadNotificationCount),
      lastMessageTimeInterval: Value(lastMessageTimeInterval),
      directUserId: directUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(directUserId),
    );
  }

  factory RoomRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoomRecord(
      myMembership: serializer.fromJson<String?>(json['myMembership']),
      id: serializer.fromJson<String>(json['id']),
      timelinePreviousBatch:
          serializer.fromJson<String?>(json['timelinePreviousBatch']),
      timelinePreviousBatchSetBySync:
          serializer.fromJson<bool?>(json['timelinePreviousBatchSetBySync']),
      summaryJoinedMembersCount:
          serializer.fromJson<int?>(json['summaryJoinedMembersCount']),
      summaryInvitedMembersCount:
          serializer.fromJson<int?>(json['summaryInvitedMembersCount']),
      nameChangeEventId:
          serializer.fromJson<String?>(json['nameChangeEventId']),
      avatarChangeEventId:
          serializer.fromJson<String?>(json['avatarChangeEventId']),
      topicChangeEventId:
          serializer.fromJson<String?>(json['topicChangeEventId']),
      powerLevelsChangeEventId:
          serializer.fromJson<String?>(json['powerLevelsChangeEventId']),
      joinRulesChangeEventId:
          serializer.fromJson<String?>(json['joinRulesChangeEventId']),
      canonicalAliasChangeEventId:
          serializer.fromJson<String?>(json['canonicalAliasChangeEventId']),
      creationEventId: serializer.fromJson<String?>(json['creationEventId']),
      upgradeEventId: serializer.fromJson<String?>(json['upgradeEventId']),
      highlightedUnreadNotificationCount:
          serializer.fromJson<int?>(json['highlightedUnreadNotificationCount']),
      totalUnreadNotificationCount:
          serializer.fromJson<int?>(json['totalUnreadNotificationCount']),
      lastMessageTimeInterval:
          serializer.fromJson<int>(json['lastMessageTimeInterval']),
      directUserId: serializer.fromJson<String?>(json['directUserId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'myMembership': serializer.toJson<String?>(myMembership),
      'id': serializer.toJson<String>(id),
      'timelinePreviousBatch':
          serializer.toJson<String?>(timelinePreviousBatch),
      'timelinePreviousBatchSetBySync':
          serializer.toJson<bool?>(timelinePreviousBatchSetBySync),
      'summaryJoinedMembersCount':
          serializer.toJson<int?>(summaryJoinedMembersCount),
      'summaryInvitedMembersCount':
          serializer.toJson<int?>(summaryInvitedMembersCount),
      'nameChangeEventId': serializer.toJson<String?>(nameChangeEventId),
      'avatarChangeEventId': serializer.toJson<String?>(avatarChangeEventId),
      'topicChangeEventId': serializer.toJson<String?>(topicChangeEventId),
      'powerLevelsChangeEventId':
          serializer.toJson<String?>(powerLevelsChangeEventId),
      'joinRulesChangeEventId':
          serializer.toJson<String?>(joinRulesChangeEventId),
      'canonicalAliasChangeEventId':
          serializer.toJson<String?>(canonicalAliasChangeEventId),
      'creationEventId': serializer.toJson<String?>(creationEventId),
      'upgradeEventId': serializer.toJson<String?>(upgradeEventId),
      'highlightedUnreadNotificationCount':
          serializer.toJson<int?>(highlightedUnreadNotificationCount),
      'totalUnreadNotificationCount':
          serializer.toJson<int?>(totalUnreadNotificationCount),
      'lastMessageTimeInterval':
          serializer.toJson<int>(lastMessageTimeInterval),
      'directUserId': serializer.toJson<String?>(directUserId),
    };
  }

  RoomRecord copyWith(
          {Value<String?> myMembership = const Value.absent(),
          String? id,
          Value<String?> timelinePreviousBatch = const Value.absent(),
          Value<bool?> timelinePreviousBatchSetBySync = const Value.absent(),
          Value<int?> summaryJoinedMembersCount = const Value.absent(),
          Value<int?> summaryInvitedMembersCount = const Value.absent(),
          Value<String?> nameChangeEventId = const Value.absent(),
          Value<String?> avatarChangeEventId = const Value.absent(),
          Value<String?> topicChangeEventId = const Value.absent(),
          Value<String?> powerLevelsChangeEventId = const Value.absent(),
          Value<String?> joinRulesChangeEventId = const Value.absent(),
          Value<String?> canonicalAliasChangeEventId = const Value.absent(),
          Value<String?> creationEventId = const Value.absent(),
          Value<String?> upgradeEventId = const Value.absent(),
          Value<int?> highlightedUnreadNotificationCount = const Value.absent(),
          Value<int?> totalUnreadNotificationCount = const Value.absent(),
          int? lastMessageTimeInterval,
          Value<String?> directUserId = const Value.absent()}) =>
      RoomRecord(
        myMembership:
            myMembership.present ? myMembership.value : this.myMembership,
        id: id ?? this.id,
        timelinePreviousBatch: timelinePreviousBatch.present
            ? timelinePreviousBatch.value
            : this.timelinePreviousBatch,
        timelinePreviousBatchSetBySync: timelinePreviousBatchSetBySync.present
            ? timelinePreviousBatchSetBySync.value
            : this.timelinePreviousBatchSetBySync,
        summaryJoinedMembersCount: summaryJoinedMembersCount.present
            ? summaryJoinedMembersCount.value
            : this.summaryJoinedMembersCount,
        summaryInvitedMembersCount: summaryInvitedMembersCount.present
            ? summaryInvitedMembersCount.value
            : this.summaryInvitedMembersCount,
        nameChangeEventId: nameChangeEventId.present
            ? nameChangeEventId.value
            : this.nameChangeEventId,
        avatarChangeEventId: avatarChangeEventId.present
            ? avatarChangeEventId.value
            : this.avatarChangeEventId,
        topicChangeEventId: topicChangeEventId.present
            ? topicChangeEventId.value
            : this.topicChangeEventId,
        powerLevelsChangeEventId: powerLevelsChangeEventId.present
            ? powerLevelsChangeEventId.value
            : this.powerLevelsChangeEventId,
        joinRulesChangeEventId: joinRulesChangeEventId.present
            ? joinRulesChangeEventId.value
            : this.joinRulesChangeEventId,
        canonicalAliasChangeEventId: canonicalAliasChangeEventId.present
            ? canonicalAliasChangeEventId.value
            : this.canonicalAliasChangeEventId,
        creationEventId: creationEventId.present
            ? creationEventId.value
            : this.creationEventId,
        upgradeEventId:
            upgradeEventId.present ? upgradeEventId.value : this.upgradeEventId,
        highlightedUnreadNotificationCount:
            highlightedUnreadNotificationCount.present
                ? highlightedUnreadNotificationCount.value
                : this.highlightedUnreadNotificationCount,
        totalUnreadNotificationCount: totalUnreadNotificationCount.present
            ? totalUnreadNotificationCount.value
            : this.totalUnreadNotificationCount,
        lastMessageTimeInterval:
            lastMessageTimeInterval ?? this.lastMessageTimeInterval,
        directUserId:
            directUserId.present ? directUserId.value : this.directUserId,
      );
  @override
  String toString() {
    return (StringBuffer('RoomRecord(')
          ..write('myMembership: $myMembership, ')
          ..write('id: $id, ')
          ..write('timelinePreviousBatch: $timelinePreviousBatch, ')
          ..write(
              'timelinePreviousBatchSetBySync: $timelinePreviousBatchSetBySync, ')
          ..write('summaryJoinedMembersCount: $summaryJoinedMembersCount, ')
          ..write('summaryInvitedMembersCount: $summaryInvitedMembersCount, ')
          ..write('nameChangeEventId: $nameChangeEventId, ')
          ..write('avatarChangeEventId: $avatarChangeEventId, ')
          ..write('topicChangeEventId: $topicChangeEventId, ')
          ..write('powerLevelsChangeEventId: $powerLevelsChangeEventId, ')
          ..write('joinRulesChangeEventId: $joinRulesChangeEventId, ')
          ..write('canonicalAliasChangeEventId: $canonicalAliasChangeEventId, ')
          ..write('creationEventId: $creationEventId, ')
          ..write('upgradeEventId: $upgradeEventId, ')
          ..write(
              'highlightedUnreadNotificationCount: $highlightedUnreadNotificationCount, ')
          ..write(
              'totalUnreadNotificationCount: $totalUnreadNotificationCount, ')
          ..write('lastMessageTimeInterval: $lastMessageTimeInterval, ')
          ..write('directUserId: $directUserId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      myMembership,
      id,
      timelinePreviousBatch,
      timelinePreviousBatchSetBySync,
      summaryJoinedMembersCount,
      summaryInvitedMembersCount,
      nameChangeEventId,
      avatarChangeEventId,
      topicChangeEventId,
      powerLevelsChangeEventId,
      joinRulesChangeEventId,
      canonicalAliasChangeEventId,
      creationEventId,
      upgradeEventId,
      highlightedUnreadNotificationCount,
      totalUnreadNotificationCount,
      lastMessageTimeInterval,
      directUserId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoomRecord &&
          other.myMembership == this.myMembership &&
          other.id == this.id &&
          other.timelinePreviousBatch == this.timelinePreviousBatch &&
          other.timelinePreviousBatchSetBySync ==
              this.timelinePreviousBatchSetBySync &&
          other.summaryJoinedMembersCount == this.summaryJoinedMembersCount &&
          other.summaryInvitedMembersCount == this.summaryInvitedMembersCount &&
          other.nameChangeEventId == this.nameChangeEventId &&
          other.avatarChangeEventId == this.avatarChangeEventId &&
          other.topicChangeEventId == this.topicChangeEventId &&
          other.powerLevelsChangeEventId == this.powerLevelsChangeEventId &&
          other.joinRulesChangeEventId == this.joinRulesChangeEventId &&
          other.canonicalAliasChangeEventId ==
              this.canonicalAliasChangeEventId &&
          other.creationEventId == this.creationEventId &&
          other.upgradeEventId == this.upgradeEventId &&
          other.highlightedUnreadNotificationCount ==
              this.highlightedUnreadNotificationCount &&
          other.totalUnreadNotificationCount ==
              this.totalUnreadNotificationCount &&
          other.lastMessageTimeInterval == this.lastMessageTimeInterval &&
          other.directUserId == this.directUserId);
}

class RoomsCompanion extends UpdateCompanion<RoomRecord> {
  final Value<String?> myMembership;
  final Value<String> id;
  final Value<String?> timelinePreviousBatch;
  final Value<bool?> timelinePreviousBatchSetBySync;
  final Value<int?> summaryJoinedMembersCount;
  final Value<int?> summaryInvitedMembersCount;
  final Value<String?> nameChangeEventId;
  final Value<String?> avatarChangeEventId;
  final Value<String?> topicChangeEventId;
  final Value<String?> powerLevelsChangeEventId;
  final Value<String?> joinRulesChangeEventId;
  final Value<String?> canonicalAliasChangeEventId;
  final Value<String?> creationEventId;
  final Value<String?> upgradeEventId;
  final Value<int?> highlightedUnreadNotificationCount;
  final Value<int?> totalUnreadNotificationCount;
  final Value<int> lastMessageTimeInterval;
  final Value<String?> directUserId;
  final Value<int> rowid;
  const RoomsCompanion({
    this.myMembership = const Value.absent(),
    this.id = const Value.absent(),
    this.timelinePreviousBatch = const Value.absent(),
    this.timelinePreviousBatchSetBySync = const Value.absent(),
    this.summaryJoinedMembersCount = const Value.absent(),
    this.summaryInvitedMembersCount = const Value.absent(),
    this.nameChangeEventId = const Value.absent(),
    this.avatarChangeEventId = const Value.absent(),
    this.topicChangeEventId = const Value.absent(),
    this.powerLevelsChangeEventId = const Value.absent(),
    this.joinRulesChangeEventId = const Value.absent(),
    this.canonicalAliasChangeEventId = const Value.absent(),
    this.creationEventId = const Value.absent(),
    this.upgradeEventId = const Value.absent(),
    this.highlightedUnreadNotificationCount = const Value.absent(),
    this.totalUnreadNotificationCount = const Value.absent(),
    this.lastMessageTimeInterval = const Value.absent(),
    this.directUserId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoomsCompanion.insert({
    this.myMembership = const Value.absent(),
    required String id,
    this.timelinePreviousBatch = const Value.absent(),
    this.timelinePreviousBatchSetBySync = const Value.absent(),
    this.summaryJoinedMembersCount = const Value.absent(),
    this.summaryInvitedMembersCount = const Value.absent(),
    this.nameChangeEventId = const Value.absent(),
    this.avatarChangeEventId = const Value.absent(),
    this.topicChangeEventId = const Value.absent(),
    this.powerLevelsChangeEventId = const Value.absent(),
    this.joinRulesChangeEventId = const Value.absent(),
    this.canonicalAliasChangeEventId = const Value.absent(),
    this.creationEventId = const Value.absent(),
    this.upgradeEventId = const Value.absent(),
    this.highlightedUnreadNotificationCount = const Value.absent(),
    this.totalUnreadNotificationCount = const Value.absent(),
    this.lastMessageTimeInterval = const Value.absent(),
    this.directUserId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<RoomRecord> custom({
    Expression<String>? myMembership,
    Expression<String>? id,
    Expression<String>? timelinePreviousBatch,
    Expression<bool>? timelinePreviousBatchSetBySync,
    Expression<int>? summaryJoinedMembersCount,
    Expression<int>? summaryInvitedMembersCount,
    Expression<String>? nameChangeEventId,
    Expression<String>? avatarChangeEventId,
    Expression<String>? topicChangeEventId,
    Expression<String>? powerLevelsChangeEventId,
    Expression<String>? joinRulesChangeEventId,
    Expression<String>? canonicalAliasChangeEventId,
    Expression<String>? creationEventId,
    Expression<String>? upgradeEventId,
    Expression<int>? highlightedUnreadNotificationCount,
    Expression<int>? totalUnreadNotificationCount,
    Expression<int>? lastMessageTimeInterval,
    Expression<String>? directUserId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (myMembership != null) 'my_membership': myMembership,
      if (id != null) 'id': id,
      if (timelinePreviousBatch != null)
        'timeline_previous_batch': timelinePreviousBatch,
      if (timelinePreviousBatchSetBySync != null)
        'timeline_previous_batch_set_by_sync': timelinePreviousBatchSetBySync,
      if (summaryJoinedMembersCount != null)
        'summary_joined_members_count': summaryJoinedMembersCount,
      if (summaryInvitedMembersCount != null)
        'summary_invited_members_count': summaryInvitedMembersCount,
      if (nameChangeEventId != null) 'name_change_event_id': nameChangeEventId,
      if (avatarChangeEventId != null)
        'avatar_change_event_id': avatarChangeEventId,
      if (topicChangeEventId != null)
        'topic_change_event_id': topicChangeEventId,
      if (powerLevelsChangeEventId != null)
        'power_levels_change_event_id': powerLevelsChangeEventId,
      if (joinRulesChangeEventId != null)
        'join_rules_change_event_id': joinRulesChangeEventId,
      if (canonicalAliasChangeEventId != null)
        'canonical_alias_change_event_id': canonicalAliasChangeEventId,
      if (creationEventId != null) 'creation_event_id': creationEventId,
      if (upgradeEventId != null) 'upgrade_event_id': upgradeEventId,
      if (highlightedUnreadNotificationCount != null)
        'highlighted_unread_notification_count':
            highlightedUnreadNotificationCount,
      if (totalUnreadNotificationCount != null)
        'total_unread_notification_count': totalUnreadNotificationCount,
      if (lastMessageTimeInterval != null)
        'last_message_time_interval': lastMessageTimeInterval,
      if (directUserId != null) 'direct_user_id': directUserId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoomsCompanion copyWith(
      {Value<String?>? myMembership,
      Value<String>? id,
      Value<String?>? timelinePreviousBatch,
      Value<bool?>? timelinePreviousBatchSetBySync,
      Value<int?>? summaryJoinedMembersCount,
      Value<int?>? summaryInvitedMembersCount,
      Value<String?>? nameChangeEventId,
      Value<String?>? avatarChangeEventId,
      Value<String?>? topicChangeEventId,
      Value<String?>? powerLevelsChangeEventId,
      Value<String?>? joinRulesChangeEventId,
      Value<String?>? canonicalAliasChangeEventId,
      Value<String?>? creationEventId,
      Value<String?>? upgradeEventId,
      Value<int?>? highlightedUnreadNotificationCount,
      Value<int?>? totalUnreadNotificationCount,
      Value<int>? lastMessageTimeInterval,
      Value<String?>? directUserId,
      Value<int>? rowid}) {
    return RoomsCompanion(
      myMembership: myMembership ?? this.myMembership,
      id: id ?? this.id,
      timelinePreviousBatch:
          timelinePreviousBatch ?? this.timelinePreviousBatch,
      timelinePreviousBatchSetBySync:
          timelinePreviousBatchSetBySync ?? this.timelinePreviousBatchSetBySync,
      summaryJoinedMembersCount:
          summaryJoinedMembersCount ?? this.summaryJoinedMembersCount,
      summaryInvitedMembersCount:
          summaryInvitedMembersCount ?? this.summaryInvitedMembersCount,
      nameChangeEventId: nameChangeEventId ?? this.nameChangeEventId,
      avatarChangeEventId: avatarChangeEventId ?? this.avatarChangeEventId,
      topicChangeEventId: topicChangeEventId ?? this.topicChangeEventId,
      powerLevelsChangeEventId:
          powerLevelsChangeEventId ?? this.powerLevelsChangeEventId,
      joinRulesChangeEventId:
          joinRulesChangeEventId ?? this.joinRulesChangeEventId,
      canonicalAliasChangeEventId:
          canonicalAliasChangeEventId ?? this.canonicalAliasChangeEventId,
      creationEventId: creationEventId ?? this.creationEventId,
      upgradeEventId: upgradeEventId ?? this.upgradeEventId,
      highlightedUnreadNotificationCount: highlightedUnreadNotificationCount ??
          this.highlightedUnreadNotificationCount,
      totalUnreadNotificationCount:
          totalUnreadNotificationCount ?? this.totalUnreadNotificationCount,
      lastMessageTimeInterval:
          lastMessageTimeInterval ?? this.lastMessageTimeInterval,
      directUserId: directUserId ?? this.directUserId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (myMembership.present) {
      map['my_membership'] = Variable<String>(myMembership.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (timelinePreviousBatch.present) {
      map['timeline_previous_batch'] =
          Variable<String>(timelinePreviousBatch.value);
    }
    if (timelinePreviousBatchSetBySync.present) {
      map['timeline_previous_batch_set_by_sync'] =
          Variable<bool>(timelinePreviousBatchSetBySync.value);
    }
    if (summaryJoinedMembersCount.present) {
      map['summary_joined_members_count'] =
          Variable<int>(summaryJoinedMembersCount.value);
    }
    if (summaryInvitedMembersCount.present) {
      map['summary_invited_members_count'] =
          Variable<int>(summaryInvitedMembersCount.value);
    }
    if (nameChangeEventId.present) {
      map['name_change_event_id'] = Variable<String>(nameChangeEventId.value);
    }
    if (avatarChangeEventId.present) {
      map['avatar_change_event_id'] =
          Variable<String>(avatarChangeEventId.value);
    }
    if (topicChangeEventId.present) {
      map['topic_change_event_id'] = Variable<String>(topicChangeEventId.value);
    }
    if (powerLevelsChangeEventId.present) {
      map['power_levels_change_event_id'] =
          Variable<String>(powerLevelsChangeEventId.value);
    }
    if (joinRulesChangeEventId.present) {
      map['join_rules_change_event_id'] =
          Variable<String>(joinRulesChangeEventId.value);
    }
    if (canonicalAliasChangeEventId.present) {
      map['canonical_alias_change_event_id'] =
          Variable<String>(canonicalAliasChangeEventId.value);
    }
    if (creationEventId.present) {
      map['creation_event_id'] = Variable<String>(creationEventId.value);
    }
    if (upgradeEventId.present) {
      map['upgrade_event_id'] = Variable<String>(upgradeEventId.value);
    }
    if (highlightedUnreadNotificationCount.present) {
      map['highlighted_unread_notification_count'] =
          Variable<int>(highlightedUnreadNotificationCount.value);
    }
    if (totalUnreadNotificationCount.present) {
      map['total_unread_notification_count'] =
          Variable<int>(totalUnreadNotificationCount.value);
    }
    if (lastMessageTimeInterval.present) {
      map['last_message_time_interval'] =
          Variable<int>(lastMessageTimeInterval.value);
    }
    if (directUserId.present) {
      map['direct_user_id'] = Variable<String>(directUserId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoomsCompanion(')
          ..write('myMembership: $myMembership, ')
          ..write('id: $id, ')
          ..write('timelinePreviousBatch: $timelinePreviousBatch, ')
          ..write(
              'timelinePreviousBatchSetBySync: $timelinePreviousBatchSetBySync, ')
          ..write('summaryJoinedMembersCount: $summaryJoinedMembersCount, ')
          ..write('summaryInvitedMembersCount: $summaryInvitedMembersCount, ')
          ..write('nameChangeEventId: $nameChangeEventId, ')
          ..write('avatarChangeEventId: $avatarChangeEventId, ')
          ..write('topicChangeEventId: $topicChangeEventId, ')
          ..write('powerLevelsChangeEventId: $powerLevelsChangeEventId, ')
          ..write('joinRulesChangeEventId: $joinRulesChangeEventId, ')
          ..write('canonicalAliasChangeEventId: $canonicalAliasChangeEventId, ')
          ..write('creationEventId: $creationEventId, ')
          ..write('upgradeEventId: $upgradeEventId, ')
          ..write(
              'highlightedUnreadNotificationCount: $highlightedUnreadNotificationCount, ')
          ..write(
              'totalUnreadNotificationCount: $totalUnreadNotificationCount, ')
          ..write('lastMessageTimeInterval: $lastMessageTimeInterval, ')
          ..write('directUserId: $directUserId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EphemeralEventsTable extends EphemeralEvents
    with TableInfo<$EphemeralEventsTable, EphemeralEventRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EphemeralEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<String> roomId = GeneratedColumn<String>(
      'room_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'REFERENCES room_events(id)');
  static const VerificationMeta _typingMeta = const VerificationMeta('typing');
  @override
  late final GeneratedColumn<String> typing = GeneratedColumn<String>(
      'typing', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [roomId, typing];
  @override
  String get aliasedName => _alias ?? 'ephemeral_events';
  @override
  String get actualTableName => 'ephemeral_events';
  @override
  VerificationContext validateIntegrity(
      Insertable<EphemeralEventRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('room_id')) {
      context.handle(_roomIdMeta,
          roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta));
    } else if (isInserting) {
      context.missing(_roomIdMeta);
    }
    if (data.containsKey('typing')) {
      context.handle(_typingMeta,
          typing.isAcceptableOrUnknown(data['typing']!, _typingMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {roomId};
  @override
  EphemeralEventRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EphemeralEventRecord(
      roomId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}room_id'])!,
      typing: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}typing']),
    );
  }

  @override
  $EphemeralEventsTable createAlias(String alias) {
    return $EphemeralEventsTable(attachedDatabase, alias);
  }
}

class EphemeralEventRecord extends DataClass
    implements Insertable<EphemeralEventRecord> {
  final String roomId;
  final String? typing;
  const EphemeralEventRecord({required this.roomId, this.typing});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['room_id'] = Variable<String>(roomId);
    if (!nullToAbsent || typing != null) {
      map['typing'] = Variable<String>(typing);
    }
    return map;
  }

  EphemeralEventsCompanion toCompanion(bool nullToAbsent) {
    return EphemeralEventsCompanion(
      roomId: Value(roomId),
      typing:
          typing == null && nullToAbsent ? const Value.absent() : Value(typing),
    );
  }

  factory EphemeralEventRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EphemeralEventRecord(
      roomId: serializer.fromJson<String>(json['roomId']),
      typing: serializer.fromJson<String?>(json['typing']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'roomId': serializer.toJson<String>(roomId),
      'typing': serializer.toJson<String?>(typing),
    };
  }

  EphemeralEventRecord copyWith(
          {String? roomId, Value<String?> typing = const Value.absent()}) =>
      EphemeralEventRecord(
        roomId: roomId ?? this.roomId,
        typing: typing.present ? typing.value : this.typing,
      );
  @override
  String toString() {
    return (StringBuffer('EphemeralEventRecord(')
          ..write('roomId: $roomId, ')
          ..write('typing: $typing')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(roomId, typing);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EphemeralEventRecord &&
          other.roomId == this.roomId &&
          other.typing == this.typing);
}

class EphemeralEventsCompanion extends UpdateCompanion<EphemeralEventRecord> {
  final Value<String> roomId;
  final Value<String?> typing;
  final Value<int> rowid;
  const EphemeralEventsCompanion({
    this.roomId = const Value.absent(),
    this.typing = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EphemeralEventsCompanion.insert({
    required String roomId,
    this.typing = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : roomId = Value(roomId);
  static Insertable<EphemeralEventRecord> custom({
    Expression<String>? roomId,
    Expression<String>? typing,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (roomId != null) 'room_id': roomId,
      if (typing != null) 'typing': typing,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EphemeralEventsCompanion copyWith(
      {Value<String>? roomId, Value<String?>? typing, Value<int>? rowid}) {
    return EphemeralEventsCompanion(
      roomId: roomId ?? this.roomId,
      typing: typing ?? this.typing,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (roomId.present) {
      map['room_id'] = Variable<String>(roomId.value);
    }
    if (typing.present) {
      map['typing'] = Variable<String>(typing.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EphemeralEventsCompanion(')
          ..write('roomId: $roomId, ')
          ..write('typing: $typing, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoomFakeEventsTable extends RoomFakeEvents
    with TableInfo<$RoomFakeEventsTable, RoomFakeEventRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoomFakeEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _networkIdMeta =
      const VerificationMeta('networkId');
  @override
  late final GeneratedColumn<String> networkId = GeneratedColumn<String>(
      'network_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<String> roomId = GeneratedColumn<String>(
      'room_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'REFERENCES room_events(id)');
  static const VerificationMeta _senderIdMeta =
      const VerificationMeta('senderId');
  @override
  late final GeneratedColumn<String> senderId = GeneratedColumn<String>(
      'sender_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<DateTime> time = GeneratedColumn<DateTime>(
      'time', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _previousContentMeta =
      const VerificationMeta('previousContent');
  @override
  late final GeneratedColumn<String> previousContent = GeneratedColumn<String>(
      'previous_content', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sentStateMeta =
      const VerificationMeta('sentState');
  @override
  late final GeneratedColumn<String> sentState = GeneratedColumn<String>(
      'sent_state', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _transactionIdMeta =
      const VerificationMeta('transactionId');
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
      'transaction_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _stateKeyMeta =
      const VerificationMeta('stateKey');
  @override
  late final GeneratedColumn<String> stateKey = GeneratedColumn<String>(
      'state_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _redactsMeta =
      const VerificationMeta('redacts');
  @override
  late final GeneratedColumn<String> redacts = GeneratedColumn<String>(
      'redacts', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _inTimelineMeta =
      const VerificationMeta('inTimeline');
  @override
  late final GeneratedColumn<bool> inTimeline =
      GeneratedColumn<bool>('in_timeline', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: true,
          defaultConstraints: GeneratedColumn.constraintsDependsOnDialect({
            SqlDialect.sqlite: 'CHECK ("in_timeline" IN (0, 1))',
            SqlDialect.mysql: '',
            SqlDialect.postgres: '',
          }));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        networkId,
        type,
        roomId,
        senderId,
        time,
        content,
        previousContent,
        sentState,
        transactionId,
        stateKey,
        redacts,
        inTimeline
      ];
  @override
  String get aliasedName => _alias ?? 'room_fake_events';
  @override
  String get actualTableName => 'room_fake_events';
  @override
  VerificationContext validateIntegrity(
      Insertable<RoomFakeEventRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('network_id')) {
      context.handle(_networkIdMeta,
          networkId.isAcceptableOrUnknown(data['network_id']!, _networkIdMeta));
    } else if (isInserting) {
      context.missing(_networkIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('room_id')) {
      context.handle(_roomIdMeta,
          roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta));
    } else if (isInserting) {
      context.missing(_roomIdMeta);
    }
    if (data.containsKey('sender_id')) {
      context.handle(_senderIdMeta,
          senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta));
    } else if (isInserting) {
      context.missing(_senderIdMeta);
    }
    if (data.containsKey('time')) {
      context.handle(
          _timeMeta, time.isAcceptableOrUnknown(data['time']!, _timeMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    if (data.containsKey('previous_content')) {
      context.handle(
          _previousContentMeta,
          previousContent.isAcceptableOrUnknown(
              data['previous_content']!, _previousContentMeta));
    }
    if (data.containsKey('sent_state')) {
      context.handle(_sentStateMeta,
          sentState.isAcceptableOrUnknown(data['sent_state']!, _sentStateMeta));
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
          _transactionIdMeta,
          transactionId.isAcceptableOrUnknown(
              data['transaction_id']!, _transactionIdMeta));
    }
    if (data.containsKey('state_key')) {
      context.handle(_stateKeyMeta,
          stateKey.isAcceptableOrUnknown(data['state_key']!, _stateKeyMeta));
    }
    if (data.containsKey('redacts')) {
      context.handle(_redactsMeta,
          redacts.isAcceptableOrUnknown(data['redacts']!, _redactsMeta));
    }
    if (data.containsKey('in_timeline')) {
      context.handle(
          _inTimelineMeta,
          inTimeline.isAcceptableOrUnknown(
              data['in_timeline']!, _inTimelineMeta));
    } else if (isInserting) {
      context.missing(_inTimelineMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoomFakeEventRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoomFakeEventRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      networkId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}network_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      roomId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}room_id'])!,
      senderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender_id'])!,
      time: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}time']),
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content']),
      previousContent: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}previous_content']),
      sentState: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sent_state']),
      transactionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transaction_id']),
      stateKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}state_key']),
      redacts: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}redacts']),
      inTimeline: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}in_timeline'])!,
    );
  }

  @override
  $RoomFakeEventsTable createAlias(String alias) {
    return $RoomFakeEventsTable(attachedDatabase, alias);
  }
}

class RoomFakeEventRecord extends DataClass
    implements Insertable<RoomFakeEventRecord> {
  final String id;
  final String networkId;
  final String type;
  final String roomId;
  final String senderId;
  final DateTime? time;
  final String? content;
  final String? previousContent;
  final String? sentState;
  final String? transactionId;
  final String? stateKey;
  final String? redacts;
  final bool inTimeline;
  const RoomFakeEventRecord(
      {required this.id,
      required this.networkId,
      required this.type,
      required this.roomId,
      required this.senderId,
      this.time,
      this.content,
      this.previousContent,
      this.sentState,
      this.transactionId,
      this.stateKey,
      this.redacts,
      required this.inTimeline});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['network_id'] = Variable<String>(networkId);
    map['type'] = Variable<String>(type);
    map['room_id'] = Variable<String>(roomId);
    map['sender_id'] = Variable<String>(senderId);
    if (!nullToAbsent || time != null) {
      map['time'] = Variable<DateTime>(time);
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    if (!nullToAbsent || previousContent != null) {
      map['previous_content'] = Variable<String>(previousContent);
    }
    if (!nullToAbsent || sentState != null) {
      map['sent_state'] = Variable<String>(sentState);
    }
    if (!nullToAbsent || transactionId != null) {
      map['transaction_id'] = Variable<String>(transactionId);
    }
    if (!nullToAbsent || stateKey != null) {
      map['state_key'] = Variable<String>(stateKey);
    }
    if (!nullToAbsent || redacts != null) {
      map['redacts'] = Variable<String>(redacts);
    }
    map['in_timeline'] = Variable<bool>(inTimeline);
    return map;
  }

  RoomFakeEventsCompanion toCompanion(bool nullToAbsent) {
    return RoomFakeEventsCompanion(
      id: Value(id),
      networkId: Value(networkId),
      type: Value(type),
      roomId: Value(roomId),
      senderId: Value(senderId),
      time: time == null && nullToAbsent ? const Value.absent() : Value(time),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      previousContent: previousContent == null && nullToAbsent
          ? const Value.absent()
          : Value(previousContent),
      sentState: sentState == null && nullToAbsent
          ? const Value.absent()
          : Value(sentState),
      transactionId: transactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionId),
      stateKey: stateKey == null && nullToAbsent
          ? const Value.absent()
          : Value(stateKey),
      redacts: redacts == null && nullToAbsent
          ? const Value.absent()
          : Value(redacts),
      inTimeline: Value(inTimeline),
    );
  }

  factory RoomFakeEventRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoomFakeEventRecord(
      id: serializer.fromJson<String>(json['id']),
      networkId: serializer.fromJson<String>(json['networkId']),
      type: serializer.fromJson<String>(json['type']),
      roomId: serializer.fromJson<String>(json['roomId']),
      senderId: serializer.fromJson<String>(json['senderId']),
      time: serializer.fromJson<DateTime?>(json['time']),
      content: serializer.fromJson<String?>(json['content']),
      previousContent: serializer.fromJson<String?>(json['previousContent']),
      sentState: serializer.fromJson<String?>(json['sentState']),
      transactionId: serializer.fromJson<String?>(json['transactionId']),
      stateKey: serializer.fromJson<String?>(json['stateKey']),
      redacts: serializer.fromJson<String?>(json['redacts']),
      inTimeline: serializer.fromJson<bool>(json['inTimeline']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'networkId': serializer.toJson<String>(networkId),
      'type': serializer.toJson<String>(type),
      'roomId': serializer.toJson<String>(roomId),
      'senderId': serializer.toJson<String>(senderId),
      'time': serializer.toJson<DateTime?>(time),
      'content': serializer.toJson<String?>(content),
      'previousContent': serializer.toJson<String?>(previousContent),
      'sentState': serializer.toJson<String?>(sentState),
      'transactionId': serializer.toJson<String?>(transactionId),
      'stateKey': serializer.toJson<String?>(stateKey),
      'redacts': serializer.toJson<String?>(redacts),
      'inTimeline': serializer.toJson<bool>(inTimeline),
    };
  }

  RoomFakeEventRecord copyWith(
          {String? id,
          String? networkId,
          String? type,
          String? roomId,
          String? senderId,
          Value<DateTime?> time = const Value.absent(),
          Value<String?> content = const Value.absent(),
          Value<String?> previousContent = const Value.absent(),
          Value<String?> sentState = const Value.absent(),
          Value<String?> transactionId = const Value.absent(),
          Value<String?> stateKey = const Value.absent(),
          Value<String?> redacts = const Value.absent(),
          bool? inTimeline}) =>
      RoomFakeEventRecord(
        id: id ?? this.id,
        networkId: networkId ?? this.networkId,
        type: type ?? this.type,
        roomId: roomId ?? this.roomId,
        senderId: senderId ?? this.senderId,
        time: time.present ? time.value : this.time,
        content: content.present ? content.value : this.content,
        previousContent: previousContent.present
            ? previousContent.value
            : this.previousContent,
        sentState: sentState.present ? sentState.value : this.sentState,
        transactionId:
            transactionId.present ? transactionId.value : this.transactionId,
        stateKey: stateKey.present ? stateKey.value : this.stateKey,
        redacts: redacts.present ? redacts.value : this.redacts,
        inTimeline: inTimeline ?? this.inTimeline,
      );
  @override
  String toString() {
    return (StringBuffer('RoomFakeEventRecord(')
          ..write('id: $id, ')
          ..write('networkId: $networkId, ')
          ..write('type: $type, ')
          ..write('roomId: $roomId, ')
          ..write('senderId: $senderId, ')
          ..write('time: $time, ')
          ..write('content: $content, ')
          ..write('previousContent: $previousContent, ')
          ..write('sentState: $sentState, ')
          ..write('transactionId: $transactionId, ')
          ..write('stateKey: $stateKey, ')
          ..write('redacts: $redacts, ')
          ..write('inTimeline: $inTimeline')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      networkId,
      type,
      roomId,
      senderId,
      time,
      content,
      previousContent,
      sentState,
      transactionId,
      stateKey,
      redacts,
      inTimeline);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoomFakeEventRecord &&
          other.id == this.id &&
          other.networkId == this.networkId &&
          other.type == this.type &&
          other.roomId == this.roomId &&
          other.senderId == this.senderId &&
          other.time == this.time &&
          other.content == this.content &&
          other.previousContent == this.previousContent &&
          other.sentState == this.sentState &&
          other.transactionId == this.transactionId &&
          other.stateKey == this.stateKey &&
          other.redacts == this.redacts &&
          other.inTimeline == this.inTimeline);
}

class RoomFakeEventsCompanion extends UpdateCompanion<RoomFakeEventRecord> {
  final Value<String> id;
  final Value<String> networkId;
  final Value<String> type;
  final Value<String> roomId;
  final Value<String> senderId;
  final Value<DateTime?> time;
  final Value<String?> content;
  final Value<String?> previousContent;
  final Value<String?> sentState;
  final Value<String?> transactionId;
  final Value<String?> stateKey;
  final Value<String?> redacts;
  final Value<bool> inTimeline;
  final Value<int> rowid;
  const RoomFakeEventsCompanion({
    this.id = const Value.absent(),
    this.networkId = const Value.absent(),
    this.type = const Value.absent(),
    this.roomId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.time = const Value.absent(),
    this.content = const Value.absent(),
    this.previousContent = const Value.absent(),
    this.sentState = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.stateKey = const Value.absent(),
    this.redacts = const Value.absent(),
    this.inTimeline = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoomFakeEventsCompanion.insert({
    required String id,
    required String networkId,
    required String type,
    required String roomId,
    required String senderId,
    this.time = const Value.absent(),
    this.content = const Value.absent(),
    this.previousContent = const Value.absent(),
    this.sentState = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.stateKey = const Value.absent(),
    this.redacts = const Value.absent(),
    required bool inTimeline,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        networkId = Value(networkId),
        type = Value(type),
        roomId = Value(roomId),
        senderId = Value(senderId),
        inTimeline = Value(inTimeline);
  static Insertable<RoomFakeEventRecord> custom({
    Expression<String>? id,
    Expression<String>? networkId,
    Expression<String>? type,
    Expression<String>? roomId,
    Expression<String>? senderId,
    Expression<DateTime>? time,
    Expression<String>? content,
    Expression<String>? previousContent,
    Expression<String>? sentState,
    Expression<String>? transactionId,
    Expression<String>? stateKey,
    Expression<String>? redacts,
    Expression<bool>? inTimeline,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (networkId != null) 'network_id': networkId,
      if (type != null) 'type': type,
      if (roomId != null) 'room_id': roomId,
      if (senderId != null) 'sender_id': senderId,
      if (time != null) 'time': time,
      if (content != null) 'content': content,
      if (previousContent != null) 'previous_content': previousContent,
      if (sentState != null) 'sent_state': sentState,
      if (transactionId != null) 'transaction_id': transactionId,
      if (stateKey != null) 'state_key': stateKey,
      if (redacts != null) 'redacts': redacts,
      if (inTimeline != null) 'in_timeline': inTimeline,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoomFakeEventsCompanion copyWith(
      {Value<String>? id,
      Value<String>? networkId,
      Value<String>? type,
      Value<String>? roomId,
      Value<String>? senderId,
      Value<DateTime?>? time,
      Value<String?>? content,
      Value<String?>? previousContent,
      Value<String?>? sentState,
      Value<String?>? transactionId,
      Value<String?>? stateKey,
      Value<String?>? redacts,
      Value<bool>? inTimeline,
      Value<int>? rowid}) {
    return RoomFakeEventsCompanion(
      id: id ?? this.id,
      networkId: networkId ?? this.networkId,
      type: type ?? this.type,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      time: time ?? this.time,
      content: content ?? this.content,
      previousContent: previousContent ?? this.previousContent,
      sentState: sentState ?? this.sentState,
      transactionId: transactionId ?? this.transactionId,
      stateKey: stateKey ?? this.stateKey,
      redacts: redacts ?? this.redacts,
      inTimeline: inTimeline ?? this.inTimeline,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (networkId.present) {
      map['network_id'] = Variable<String>(networkId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (roomId.present) {
      map['room_id'] = Variable<String>(roomId.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<String>(senderId.value);
    }
    if (time.present) {
      map['time'] = Variable<DateTime>(time.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (previousContent.present) {
      map['previous_content'] = Variable<String>(previousContent.value);
    }
    if (sentState.present) {
      map['sent_state'] = Variable<String>(sentState.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (stateKey.present) {
      map['state_key'] = Variable<String>(stateKey.value);
    }
    if (redacts.present) {
      map['redacts'] = Variable<String>(redacts.value);
    }
    if (inTimeline.present) {
      map['in_timeline'] = Variable<bool>(inTimeline.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoomFakeEventsCompanion(')
          ..write('id: $id, ')
          ..write('networkId: $networkId, ')
          ..write('type: $type, ')
          ..write('roomId: $roomId, ')
          ..write('senderId: $senderId, ')
          ..write('time: $time, ')
          ..write('content: $content, ')
          ..write('previousContent: $previousContent, ')
          ..write('sentState: $sentState, ')
          ..write('transactionId: $transactionId, ')
          ..write('stateKey: $stateKey, ')
          ..write('redacts: $redacts, ')
          ..write('inTimeline: $inTimeline, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EphemeralReceiptEventTable extends EphemeralReceiptEvent
    with TableInfo<$EphemeralReceiptEventTable, EphemeralReceiptEventRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EphemeralReceiptEventTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<String> roomId = GeneratedColumn<String>(
      'room_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _eventIdMeta =
      const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
      'event_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timeStampMeta =
      const VerificationMeta('timeStamp');
  @override
  late final GeneratedColumn<int> timeStamp = GeneratedColumn<int>(
      'time_stamp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [roomId, userId, eventId, timeStamp];
  @override
  String get aliasedName => _alias ?? 'ephemeral_receipt_event';
  @override
  String get actualTableName => 'ephemeral_receipt_event';
  @override
  VerificationContext validateIntegrity(
      Insertable<EphemeralReceiptEventRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('room_id')) {
      context.handle(_roomIdMeta,
          roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta));
    } else if (isInserting) {
      context.missing(_roomIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta,
          eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('time_stamp')) {
      context.handle(_timeStampMeta,
          timeStamp.isAcceptableOrUnknown(data['time_stamp']!, _timeStampMeta));
    } else if (isInserting) {
      context.missing(_timeStampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {roomId, userId};
  @override
  EphemeralReceiptEventRecord map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EphemeralReceiptEventRecord(
      roomId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}room_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      eventId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event_id'])!,
      timeStamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}time_stamp'])!,
    );
  }

  @override
  $EphemeralReceiptEventTable createAlias(String alias) {
    return $EphemeralReceiptEventTable(attachedDatabase, alias);
  }
}

class EphemeralReceiptEventRecord extends DataClass
    implements Insertable<EphemeralReceiptEventRecord> {
  final String roomId;
  final String userId;
  final String eventId;
  final int timeStamp;
  const EphemeralReceiptEventRecord(
      {required this.roomId,
      required this.userId,
      required this.eventId,
      required this.timeStamp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['room_id'] = Variable<String>(roomId);
    map['user_id'] = Variable<String>(userId);
    map['event_id'] = Variable<String>(eventId);
    map['time_stamp'] = Variable<int>(timeStamp);
    return map;
  }

  EphemeralReceiptEventCompanion toCompanion(bool nullToAbsent) {
    return EphemeralReceiptEventCompanion(
      roomId: Value(roomId),
      userId: Value(userId),
      eventId: Value(eventId),
      timeStamp: Value(timeStamp),
    );
  }

  factory EphemeralReceiptEventRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EphemeralReceiptEventRecord(
      roomId: serializer.fromJson<String>(json['roomId']),
      userId: serializer.fromJson<String>(json['userId']),
      eventId: serializer.fromJson<String>(json['eventId']),
      timeStamp: serializer.fromJson<int>(json['timeStamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'roomId': serializer.toJson<String>(roomId),
      'userId': serializer.toJson<String>(userId),
      'eventId': serializer.toJson<String>(eventId),
      'timeStamp': serializer.toJson<int>(timeStamp),
    };
  }

  EphemeralReceiptEventRecord copyWith(
          {String? roomId, String? userId, String? eventId, int? timeStamp}) =>
      EphemeralReceiptEventRecord(
        roomId: roomId ?? this.roomId,
        userId: userId ?? this.userId,
        eventId: eventId ?? this.eventId,
        timeStamp: timeStamp ?? this.timeStamp,
      );
  @override
  String toString() {
    return (StringBuffer('EphemeralReceiptEventRecord(')
          ..write('roomId: $roomId, ')
          ..write('userId: $userId, ')
          ..write('eventId: $eventId, ')
          ..write('timeStamp: $timeStamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(roomId, userId, eventId, timeStamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EphemeralReceiptEventRecord &&
          other.roomId == this.roomId &&
          other.userId == this.userId &&
          other.eventId == this.eventId &&
          other.timeStamp == this.timeStamp);
}

class EphemeralReceiptEventCompanion
    extends UpdateCompanion<EphemeralReceiptEventRecord> {
  final Value<String> roomId;
  final Value<String> userId;
  final Value<String> eventId;
  final Value<int> timeStamp;
  final Value<int> rowid;
  const EphemeralReceiptEventCompanion({
    this.roomId = const Value.absent(),
    this.userId = const Value.absent(),
    this.eventId = const Value.absent(),
    this.timeStamp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EphemeralReceiptEventCompanion.insert({
    required String roomId,
    required String userId,
    required String eventId,
    required int timeStamp,
    this.rowid = const Value.absent(),
  })  : roomId = Value(roomId),
        userId = Value(userId),
        eventId = Value(eventId),
        timeStamp = Value(timeStamp);
  static Insertable<EphemeralReceiptEventRecord> custom({
    Expression<String>? roomId,
    Expression<String>? userId,
    Expression<String>? eventId,
    Expression<int>? timeStamp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (roomId != null) 'room_id': roomId,
      if (userId != null) 'user_id': userId,
      if (eventId != null) 'event_id': eventId,
      if (timeStamp != null) 'time_stamp': timeStamp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EphemeralReceiptEventCompanion copyWith(
      {Value<String>? roomId,
      Value<String>? userId,
      Value<String>? eventId,
      Value<int>? timeStamp,
      Value<int>? rowid}) {
    return EphemeralReceiptEventCompanion(
      roomId: roomId ?? this.roomId,
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      timeStamp: timeStamp ?? this.timeStamp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (roomId.present) {
      map['room_id'] = Variable<String>(roomId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (timeStamp.present) {
      map['time_stamp'] = Variable<int>(timeStamp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EphemeralReceiptEventCompanion(')
          ..write('roomId: $roomId, ')
          ..write('userId: $userId, ')
          ..write('eventId: $eventId, ')
          ..write('timeStamp: $timeStamp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$Database extends GeneratedDatabase {
  _$Database(QueryExecutor e) : super(e);
  late final $DevicesTable devices = $DevicesTable(this);
  late final Index ixDevicesUser = Index('ix_devices_user',
      'CREATE INDEX IF NOT EXISTS ix_devices_user ON devices (user_id)');
  late final $MyUsersTable myUsers = $MyUsersTable(this);
  late final Index ixMyuserDevice = Index('ix_myuser_device',
      'CREATE INDEX IF NOT EXISTS ix_myuser_device ON my_users (current_device_id)');
  late final $RoomEventsTable roomEvents = $RoomEventsTable(this);
  late final Index ixRoomevents = Index('ix_roomevents',
      'CREATE INDEX IF NOT EXISTS ix_roomevents ON room_events (room_id, sender_id, transaction_id)');
  late final $RoomsTable rooms = $RoomsTable(this);
  late final Index ixRooms = Index('ix_rooms',
      'CREATE INDEX IF NOT EXISTS ix_rooms ON rooms (name_change_event_id, avatar_change_event_id, topic_change_event_id, power_levels_change_event_id, join_rules_change_event_id, canonical_alias_change_event_id, creation_event_id, upgrade_event_id, direct_user_id)');
  late final $EphemeralEventsTable ephemeralEvents =
      $EphemeralEventsTable(this);
  late final $RoomFakeEventsTable roomFakeEvents = $RoomFakeEventsTable(this);
  late final $EphemeralReceiptEventTable ephemeralReceiptEvent =
      $EphemeralReceiptEventTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        devices,
        ixDevicesUser,
        myUsers,
        ixMyuserDevice,
        roomEvents,
        ixRoomevents,
        rooms,
        ixRooms,
        ephemeralEvents,
        roomFakeEvents,
        ephemeralReceiptEvent
      ];
}
