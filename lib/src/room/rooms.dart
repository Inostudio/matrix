// Copyright (C) 2019  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:collection/collection.dart';
import 'package:matrix_sdk/src/model/request_update.dart';

import '../homeserver.dart';
import '../model/context.dart';
import '../model/identifier.dart';
import '../model/my_user.dart';
import 'room.dart';

class Rooms extends DelegatingIterable<Room> implements Contextual<Rooms> {
  @override
  final Context? context;

  Rooms(
    Iterable<Room> iterable, {
    this.context,
  }) : super(iterable.toList());

  Rooms.empty({
    this.context,
  }) : super([]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Rooms &&
          runtimeType == other.runtimeType &&
          context == other.context;

  @override
  int get hashCode => context.hashCode;

  Room? operator [](RoomId id) => firstWhereOrNull((s) => s.id == id);

  bool containsWithId(RoomId id) => any((r) => r.id == id);

  @override
  String toString() {
    return 'Rooms{context: $context}';
  }

  Rooms copyWith({
    Iterable<Room>? rooms,
    Context? context,
  }) {
    rooms ??= this;

    // Make sure all contexts are changed
    if (context != null && context != this.context) {
      rooms = rooms.map((r) => r.copyWith(context: context));
    }

    return Rooms(
      rooms,
      context: context ?? this.context,
    );
  }

  Rooms merge(Rooms? other) {
    if (other == null) {
      return this;
    }

    final currList = toList();
    final otherList = other.toList();

    //Make curr and other map <RoomId, index in list>
    final Map<RoomId, int> currMap = {
      for (var e in currList.mapIndexed(
        (i, e) => MapEntry<RoomId, int>(e.id, i),
      ))
        e.key: e.value
    };
    final Map<RoomId, int> otherMap = {
      for (var e in otherList.mapIndexed(
        (i, e) => MapEntry<RoomId, int>(e.id, i),
      ))
        e.key: e.value
    };

    final currSet = currList.toSet();
    final otherSet = otherList.toSet();

    //Calculate both difference and intersection, both differences go to result list
    final differenceLeft = otherSet.difference(currSet);
    final differenceRight = toSet().difference(otherSet);
    final intersection = otherSet.intersection(currSet);

    final result = List<Room>.from(
      differenceLeft..addAll(differenceRight),
      growable: true,
    );

    //for every intersected by id room item merge them, then add into result list
    for (final Room i in intersection) {
      final id = i.id;
      final otherIndex = otherMap[id];
      final currIndex = currMap[id];

      if (currIndex != null && otherIndex != null) {
        final otherToMerge = otherList[otherIndex];
        final currToMerge = currList[currIndex];
        final merged = currToMerge.merge(otherToMerge);
        result.add(merged);
      }
    }

    return  copyWith(
      rooms: result,
      context: other.context,
    );
  }

  @override
  Rooms? delta({Iterable<Room>? rooms}) {
    if (rooms == null) {
      return null;
    }

    return Rooms(
      rooms,
      context: context,
    );
  }

  @override
  Rooms? propertyOf(MyUser user) => user.rooms;

  /// Join a room with the given [id] or [alias].
  ///
  /// Either [id] or [alias] must not be null, and they can't be both
  /// non-null.
  ///
  /// Returns a RequestUpdate with the [Room] that has been joined.
  ///
  /// Note that this method is called `enter` because otherwise it would
  /// conflict with [Iterable.join].
  ///
  /// [through] is the server which will be used to join through. Can be
  /// left `null`.
  Future<RequestUpdate<Room>?> enter({
    RoomId? id,
    RoomAlias? alias,
    Homeserver? through,
  }) {
    assert((id != null && alias == null) || (id == null && alias != null));
    final result = context?.updater?.joinRoom(
      id: id,
      alias: alias,
      serverUrl: through?.wellKnownUrl ?? through?.url ?? Uri(),
    );
    return result ?? Future.value(null);
  }
}
