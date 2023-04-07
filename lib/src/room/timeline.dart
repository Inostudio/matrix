// Copyright (C) 2019  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:collection/collection.dart';
import 'package:matrix_sdk/src/model/request_update.dart';

import '../event/event.dart';
import '../event/room/raw_room_event.dart';
import '../event/room/room_event.dart';
import '../model/context.dart';
import '../model/identifier.dart';
import '../model/my_user.dart';
import 'room.dart';

class Timeline extends DelegatingIterable<RoomEvent>
    implements Contextual<Timeline> {
  @override
  final RoomContext? context;

  final String? previousBatch;
  final String? startBatch;

  final bool? previousBatchSetBySync;

  @override
  String toString() {
    return 'Timeline{context: $context, previousBatch: $previousBatch, startBatch: $startBatch, previousBatchSetBySync: $previousBatchSetBySync}';
  }

  Timeline(
    Iterable<RoomEvent> iterable, {
    required this.context,
    this.previousBatch,
    this.startBatch,
    this.previousBatchSetBySync,
  }) : super(
          // TODO: Assume sorted
          iterable.toList(growable: false)
            ..sort(
              (a, b) => (a.time == null || b.time == null)
                  ? 0
                  : -a.time!.compareTo(b.time!),
            ),
        );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Timeline &&
          runtimeType == other.runtimeType &&
          context == other.context &&
          previousBatch == other.previousBatch &&
          startBatch == other.startBatch &&
          previousBatchSetBySync == other.previousBatchSetBySync;

  @override
  int get hashCode =>
      context.hashCode ^
      previousBatch.hashCode ^
      startBatch.hashCode ^
      previousBatchSetBySync.hashCode;

  Timeline.empty({
    required this.context,
  })  : previousBatch = null,
        startBatch = null,
        previousBatchSetBySync = null,
        super([]);

  /// Create a timeline from json received from a homeserver.
  ///
  /// If [context] is provided, [roomId] doesn't have to be.
  /// Otherwise [roomId] must be provided.
  factory Timeline.fromJson(
    List<Map<String, dynamic>> json, {
    RoomContext? context,
    String? previousBatch,
    String? startBatch,
    bool? previousBatchSetBySync,
  }) {
    final events = json
        .map((e) => RoomEvent.fromJson(e, roomId: context?.roomId))
        .whereNotNull()
        .toList(growable: false);

    return Timeline(
      List.of(
        events,
        growable: false,
      ),
      context: context,
      previousBatch: previousBatch,
      startBatch: startBatch,
      previousBatchSetBySync: previousBatchSetBySync,
    );
  }

  RoomEvent? operator [](EventId id) => firstWhereOrNull((s) => s.id == id);

  /// Load more events, returning the [Update] where [MyUser] has a room
  /// with a timeline containing more events.
  Future<RequestUpdate<Timeline>?> load({
    int count = 20,
    Room? room,
  }) {
    final result = context?.updater?.loadRoomEvents(
      roomId: context!.roomId,
      count: count,
      room: room,
    );
    return result ?? Future.value(null);
  }

  Iterable<RoomEvent> get reversed => List.of(this).reversed;

  Timeline copyWith({
    Iterable<RoomEvent>? events,
    RoomContext? context,
    String? previousBatch,
    String? startBatch,
    bool? previousBatchSetBySync,
  }) {
    return Timeline(
      events ?? this,
      context: context ?? this.context,
      previousBatch: previousBatch ?? this.previousBatch,
      startBatch: startBatch ?? this.startBatch,
      previousBatchSetBySync:
          previousBatchSetBySync ?? this.previousBatchSetBySync,
    );
  }

  Timeline? merge(Timeline? other) {
    if (other == null) {
      return this;
    }

    final currList = toList();

    final Set<String> otherIdsSet =
        other.map((e) => e.id.value).toSet();
    final Set<String> currIdsSet =
        currList.map((e) => e.id.value).toSet();
    final List<String> currWithoutOtherIds =
        currIdsSet.difference(otherIdsSet).toList();

    //Curr transactionId to index
    final Map<String, int> currIdToIndexMap = {};
    for (int i = 0; i < currList.length; i++) {
      final currId = currList[i].id.value;
      currIdToIndexMap[currId] = i;
    }

    //Make curr event list without other event
    final List<RoomEvent> currWithoutOther = [];
    for (final id in currWithoutOtherIds) {
      final index = currIdToIndexMap[id];
      if (index != null) {
        final value = currList[index];
        currWithoutOther.add(value);
      }
    }

    final result = List<RoomEvent>.from(
      currWithoutOther..addAll(other),
      growable: true,
    ).sorted((first, second) {
      if (first.time == null || second.time == null) {
        return 0;
      } else {
        return first.time!.isAfter(second.time!) ? 1 : -1;
      }
    });

    return copyWith(
      events: result,
      context: other.context,
      previousBatch: other.previousBatch,
      startBatch: other.startBatch,
      previousBatchSetBySync: other.previousBatchSetBySync,
    );
  }

  @override
  Timeline? delta({
    Iterable<RoomEvent>? events,
    String? previousBatch,
    String? startBatch,
    bool? previousBatchSetBySync,
  }) {
    if (events == null &&
        previousBatch == null &&
        startBatch == null &&
        previousBatchSetBySync == null) {
      return null;
    }

    return Timeline(
      events ?? [],
      context: context,
      previousBatch: previousBatch,
      startBatch: startBatch,
      previousBatchSetBySync: previousBatchSetBySync,
    );
  }

  @override
  Timeline? propertyOf(MyUser user) {
    if (context?.roomId != null) {
      return user.rooms?[context!.roomId]?.timeline;
    } else {
      return null;
    }
  }
}

extension TimelineExtension on Iterable<RoomEvent> {
  /// Returns [RawRoomEvent]s with the given Matrix type.
  ///
  /// **Should not be any type supported by the SDK.**
  Iterable<RawRoomEvent> withCustomType(String type) {
    assert(Event.typeOf(type) == null);

    return where((e) => e.type == type).cast();
  }

  /// Returns the first [RawRoomEvent] with the given Matrix type.
  ///
  /// **Should not be any type supported by the SDK.**
  RawRoomEvent? firstWithCustomType(
    String type, {
    RawRoomEvent Function()? orElse,
  }) {
    assert(Event.typeOf(type) == null);

    return firstWhere(
      (e) => e.type == type,
      orElse: orElse,
    ) as RawRoomEvent;
  }
}
