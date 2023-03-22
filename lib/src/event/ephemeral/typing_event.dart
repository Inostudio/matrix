// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:meta/meta.dart';

import '../../model/identifier.dart';
import '../event.dart';
import 'ephemeral_event.dart';

class TypingEvent extends EphemeralEvent {
  static const matrixType = 'm.typing';

  @override
  final String type = matrixType;

  TypingEvent({
    RoomId? roomId,
    this.content,
  }) : super(roomId: roomId);

  @override
  final Typers? content;

  TypingEvent merge(TypingEvent? other) {
    if (other == null) {
      return this;
    }


    return TypingEvent(
      roomId: roomId,
      content: content?.merge(other.content) ?? other.content,
    );
  }
}

@immutable
class Typers extends EventContent {
  Typers({
    required this.typerIds,
  });

  @override
  bool operator ==(dynamic other) =>
      other is Typers && typerIds == other.typerIds;

  @override
  int get hashCode => typerIds.hashCode;

  final List<UserId> typerIds;

  static Typers? fromJson(Map<String, dynamic>? content) {
    if (content == null) {
      return null;
    }

    final rawIds = content['user_ids'] as List<String>;
    final typerIds = rawIds.map<UserId>(UserId.new).toList(growable: false);

    return Typers(typerIds: typerIds);
  }

  static Typers? fromList(List<String> data) {
    if (data.isEmpty) {
      return null;
    }
    return Typers(typerIds: data.map(UserId.new).toList());
  }

  @override
  Map<String, dynamic> toJson() => {
        'user_ids': [...typerIds.map((id) => id.toString())],
      };

  Typers? merge(Typers? other) {
    if (other == null) {
      return this;
    }

    final union = typerIds.toSet().union(other.typerIds.toSet());
    return Typers(typerIds: union.toList());
  }
}
