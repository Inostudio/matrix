// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:collection/collection.dart';

import '../../../matrix_sdk.dart';
import '../../model/context.dart';
import 'typing_event.dart';

abstract class EphemeralEvent extends Event {
  final RoomId? roomId;

  EphemeralEvent({
    this.roomId,
  });
}

class EphemeralEventFull implements Contextual<EphemeralEventFull> {
  final RoomId roomId;
  final TypingEvent typingEvents;
  final ReceiptEvent receiptEvents;

  final Map<Type, EphemeralEvent> _map;
  @override
  final RoomContext? context;

  EphemeralEventFull({
    this.context,
    required this.roomId,
    required this.typingEvents,
    required this.receiptEvents,
  }) : _map = {
          for (final event in [
            typingEvents,
            receiptEvents,
          ].whereNotNull())
            event.runtimeType: event
        };

  EphemeralEventFull? merge(EphemeralEventFull? other) {
    if (other == null) {
      return this;
    }
    final fullEvents = mergeMaps<Type, EphemeralEvent>(
      _map,
      other._map,
      value: (thisEvent, otherEvent) =>
          thisEvent is ReceiptEvent && otherEvent is ReceiptEvent
              ? thisEvent.merge(otherEvent)
              : otherEvent,
    ).values.toList();

    TypingEvent typing = TypingEvent(
      roomId: roomId,
      content: Typers(typerIds: const []),
    );
    ReceiptEvent receiptEvents = ReceiptEvent();
    final typingList =
        fullEvents.whereType<TypingEvent>().map((e) => e).toList();
    final receiptList =
        fullEvents.whereType<ReceiptEvent>().map((e) => e).toList();

    for (final e in typingList) {
      typing = typing.merge(e);
    }
    for (final e in receiptList) {
      receiptEvents = receiptEvents.merge(e);
    }
    return copyWith(
      typingEvents: typing,
      receiptEvents: receiptEvents,
      context: other.context,
    );
  }

  @override
  EphemeralEventFull? delta({
    Iterable<EphemeralEvent>? events,
  }) {
    if (events == null) {
      return null;
    }

    final TypingEvent typing = TypingEvent();
    final ReceiptEvent receipt = ReceiptEvent();
    for (final e in events) {
      switch (e.type) {
        case TypingEvent.matrixType:
          if (e is TypingEvent) {
            typing.merge(e);
          }
          break;
        case ReceiptEvent.matrixType:
          if (e is ReceiptEvent) {
            receipt.merge(e);
          }
          break;
      }
    }
    return EphemeralEventFull(
      receiptEvents: receipt,
      typingEvents: typing,
      roomId: roomId,
      context: context,
    );
  }

  @override
  EphemeralEventFull? propertyOf(MyUser user) {
    if (context?.roomId != null) {
      return user.rooms?[context!.roomId]?.ephemeral;
    } else {
      return null;
    }
  }

  EphemeralEventFull copyWith({
    RoomId? roomId,
    TypingEvent? typingEvents,
    ReceiptEvent? receiptEvents,
    RoomContext? context,
  }) {
    return EphemeralEventFull(
      roomId: roomId ?? this.roomId,
      typingEvents: typingEvents ?? this.typingEvents,
      receiptEvents: receiptEvents ?? this.receiptEvents,
      context: context ?? this.context,
    );
  }

  factory EphemeralEventFull.fromMap({
    required Map<String, dynamic> map,
    required RoomId roomId,
    RoomContext? context,
  }) {
    final List<dynamic> events = map["events"];

    TypingEvent typing = TypingEvent(content: Typers(typerIds: const []));
    ReceiptEvent receipt = ReceiptEvent(content: Receipts(const []));
    for (final e in events) {
      final eventData = e as Map<String, dynamic>;
      final type = eventData["type"];
      if (type == ReceiptEvent.matrixType) {
        final a = ReceiptEvent(
          roomId: roomId,
          content: Receipts.fromJson(eventData['content']),
        );

        receipt = receipt.merge(a);
      } else if (type == TypingEvent.matrixType) {
        typing = typing.merge(
          TypingEvent(
            roomId: roomId,
            content: Typers.fromJson(eventData['content']),
          ),
        );
      }
    }

    return EphemeralEventFull(
      context: context,
      roomId: roomId,
      typingEvents: typing,
      receiptEvents: receipt,
    );
  }
}
