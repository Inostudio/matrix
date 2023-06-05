// Copyright (C) 2019  Wilko Manger
// Copyright (C) 2019  Mathieu Velten
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:meta/meta.dart';

import 'state/state_event.dart';
import '../../model/identifier.dart';
import '../event.dart';
import 'room_event.dart';

class RedactionEvent extends RoomEvent {
  static const matrixType = 'm.room.redaction';

  @override
  final String type = matrixType;

  RedactionEvent(
    RoomEventArgs args, {
    required this.content,
    required this.redacts,
  }) : super(args);

  @override
  final Redaction? content;

  final EventId redacts;

  factory RedactionEvent.fromJson(
    RoomEventArgs args,
    Map<String, dynamic> json,
  ) {
    final redacts = EventId(json['redacts']);

    return RedactionEvent(
      args,
      content: Redaction.fromJson(json['content']),
      redacts: redacts,
    );
  }

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'redacts': redacts.toString(),
    });
}

@immutable
class Redaction extends EventContent {
  final RedactionReason reason;

  Redaction({
    required this.reason,
  });

  @override
  bool operator ==(dynamic other) =>
      other is Redaction && reason == other.reason;

  @override
  int get hashCode => reason.hashCode;

  static Redaction? fromJson(Map<String, dynamic>? content) {
    if(content?.containsKey("reason") ?? false){
      content = content!["reason"];
    }
    final reason = RedactionReason.fromJson(content ?? {"type": "DeletedByAuthor"});
    return Redaction(reason: reason);
  }

  @override
  Map<String, dynamic> toJson() => super.toJson()..addAll({'reason': reason.toJson()});
}


class RedactionReason{
  final String type;
  final Map<String, dynamic>? data;

  const RedactionReason({
    required this.type,
    required this.data,
  });

  factory RedactionReason.defaultReason(){
    return RedactionReason.fromJson({"type": "DeletedByAuthor"});
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
    };
  }

  factory RedactionReason.fromJson(Map<String, dynamic> map) {
    return RedactionReason(
      type: map['type'] ?? "DeletedByAuthor",
      data: map['data'] as Map<String, dynamic>?,
    );
  }
}

class RedactedEvent extends RoomEvent {
  factory RedactedEvent.fromRedaction({
    required RedactionEvent redaction,
    required RoomEvent original,
  }) {
    if (original is StateEvent) {
      return RedactedStateEvent(redaction, original);
    }

    return RedactedEvent(redaction, original);
  }

  @override
  final String type;

  @override
  final EventContent? content = null;

  final RedactionEvent redaction;

  final RoomEvent original;

  RedactedEvent(this.redaction, this.original)
      : type = original.type,
        super(RoomEventArgs.fromEvent(original));

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'unsigned': {
        'redacted_because': redaction.toJson(),
      }
    });
}

// ignore: avoid_implementing_value_types
class RedactedStateEvent extends StateEvent implements RedactedEvent {
  @override
  final EventContent? content = null;

  @override
  final EventContent? previousContent = null;

  @override
  final String type;

  @override
  final RedactionEvent redaction;

  @override
  final StateEvent original;

  RedactedStateEvent(this.redaction, this.original)
      : type = original.type,
        super(RoomEventArgs.fromEvent(original), stateKey: original.stateKey);

  @override
  Map<String, dynamic> toJson() =>
      super.toJson()..['unsigned']['redacted_because'] = redaction.toJson();
}
