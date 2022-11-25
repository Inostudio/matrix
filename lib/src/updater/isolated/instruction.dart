// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:matrix_sdk/src/event/ephemeral/ephemeral_event.dart';
import 'package:matrix_sdk/src/event/room/message_event.dart';

import '../../event/event.dart';
import '../../model/models.dart';
import '../../model/sync_token.dart';
import '../../room/member/member_timeline.dart';
import '../../room/room.dart';
import '../../room/rooms.dart';
import '../../room/timeline.dart';

abstract class StorageSyncInstruction<T> extends Instruction<T> {}

abstract class OneRoomInstruction<T> extends Instruction<T> {}

class StartSyncInstruction extends StorageSyncInstruction<void> {
  @override
  bool get expectsReturnValue => false;

  final Duration maxRetryAfter;
  final int timelineLimit;
  final String? syncToken;

  StartSyncInstruction(this.maxRetryAfter, this.timelineLimit, this.syncToken);
}

class RunSyncOnceInstruction extends StorageSyncInstruction<SyncToken> {
  final SyncFilter filter;

  RunSyncOnceInstruction(this.filter);
}

class StopSyncInstruction extends StorageSyncInstruction<void> {}

class CloseRoomSync extends StorageSyncInstruction<bool> {
  final String roomId;

  CloseRoomSync({
    required this.roomId,
  });
}

class CloseAllRoomsSync extends StorageSyncInstruction<bool> {}

class GetRoomIDsInstruction extends Instruction<List<String?>> {}

class GetRoomInstruction extends Instruction<Room> {
  final String roomId;
  final Context? context;
  final List<UserId> memberIds;

  GetRoomInstruction({
    required this.roomId,
    required this.context,
    required this.memberIds,
  });
}

class SaveRoomToDBInstruction extends Instruction<void> {
  final Room room;

  SaveRoomToDBInstruction(this.room);
}

abstract class RequestInstruction<T extends Contextual<T>>
    extends Instruction<RequestUpdate<T>> {
  /// Some [RequestUpdate]s are wrapped [SyncUpdate]s, we should not send
  /// those through the `updates` `Stream`.
  final bool basedOnUpdate = false;
}

class KickInstruction extends RequestInstruction<MemberTimeline> {
  final UserId id;
  final RoomId? from;

  KickInstruction(this.id, this.from);

  @override
  final bool basedOnUpdate = true;
}

class LoadRoomEventsInstruction extends RequestInstruction<Timeline> {
  final RoomId? roomId;
  final int count;
  final Room? room;

  @override
  final bool basedOnUpdate = true;

  LoadRoomEventsInstruction(this.roomId, this.count, this.room);
}

class LoadMembersInstruction extends RequestInstruction<MemberTimeline> {
  final RoomId? roomId;
  final int count;
  final Room? room;

  LoadMembersInstruction(this.roomId, this.count, this.room);
}

class LoadRoomsByIDsInstruction extends RequestInstruction<Rooms> {
  final List<RoomId> roomIds;
  final int timelineLimit;

  LoadRoomsByIDsInstruction(this.roomIds, this.timelineLimit);
}

class LoadRoomsInstruction extends RequestInstruction<Rooms> {
  final int timelineLimit;
  final int limit;
  final int offset;

  LoadRoomsInstruction(this.limit, this.offset, this.timelineLimit);
}

class LogoutInstruction extends RequestInstruction<MyUser> {
  @override
  final bool basedOnUpdate = true;
}

class MarkReadInstruction extends RequestInstruction<ReadReceipts> {
  final RoomId roomId;
  final EventId until;
  final bool receipt;
  final bool fullyRead;
  final Room? room;

  @override
  final bool basedOnUpdate = true;

  MarkReadInstruction({
    required this.roomId,
    required this.until,
    required this.receipt,
    required this.fullyRead,
    this.room,
  });
}

class SendInstruction extends RequestInstruction<Timeline> {
  final RoomId roomId;
  final EventContent content;
  final String? transactionId;
  final String stateKey;
  final String type;
  final Room? room;

  SendInstruction(
    this.roomId,
    this.content,
    this.transactionId,
    this.stateKey,
    this.type,
    this.room,
  );
}

class OneRoomSyncInstruction extends OneRoomInstruction<Room> {
  final String roomId;
  final Context? context;
  final UserId? userId;

  OneRoomSyncInstruction({
    required this.roomId,
    this.context,
    this.userId,
  });
}

class EditTextEventInstruction extends RequestInstruction<Timeline> {
  final RoomId roomId;
  final TextMessageEvent event;
  final String? transactionId;
  final String newContent;
  final Room? room;

  EditTextEventInstruction(
    this.roomId,
    this.event,
    this.newContent,
    this.transactionId, {
    this.room,
  });

  @override
  final bool basedOnUpdate = true;
}

class DeleteEventInstruction extends RequestInstruction<Timeline> {
  final RoomId roomId;
  final EventId eventId;
  final String? transactionId;
  final String? reason;
  final Room? room;

  DeleteEventInstruction(
      this.roomId, this.eventId, this.transactionId, this.reason, this.room);

  @override
  final bool basedOnUpdate = true;
}

class SetIsTypingInstruction extends RequestInstruction<EphemeralEventFull> {
  final RoomId? roomId;
  final bool isTyping;
  final Duration timeout;

  // ignore: avoid_positional_boolean_parameters
  SetIsTypingInstruction(this.roomId, this.isTyping, this.timeout);

  @override
  final bool basedOnUpdate = true;
}

class JoinRoomInstruction extends RequestInstruction<Room> {
  final RoomId? id;
  final RoomAlias? alias;
  final Uri serverUrl;

  JoinRoomInstruction(this.id, this.alias, this.serverUrl);

  @override
  final bool basedOnUpdate = true;
}

class LeaveRoomInstruction extends RequestInstruction<Room> {
  final RoomId id;

  LeaveRoomInstruction(this.id);

  @override
  final bool basedOnUpdate = true;
}

class SetNameInstruction extends RequestInstruction<MyUser> {
  final String name;

  SetNameInstruction(this.name);
}

class SetPusherInstruction extends RequestInstruction<MyUser> {
  final Map<String, dynamic> pusher;

  SetPusherInstruction(this.pusher);

  @override
  final bool basedOnUpdate = true;
}
