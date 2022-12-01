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

class IsolateRespose<T> {
  final int? dataInstructionId;
  final T data;

  const IsolateRespose({
    required this.dataInstructionId,
    required this.data,
  });

  @override
  String toString() {
    return 'ResponseDataInstructionId{dataInstructionId: $dataInstructionId, data: $data}';
  }
}

abstract class StorageSyncInstruction<T> extends Instruction<T> {
  StorageSyncInstruction({required super.instructionId});
}

abstract class RequestInstruction<T extends Contextual<T>>
    extends Instruction<RequestUpdate<T>> {
  /// Some [RequestUpdate]s are wrapped [SyncUpdate]s, we should not send
  /// those through the `updates` `Stream`.
  final bool basedOnUpdate = false;

  RequestInstruction({required super.instructionId});
}

class GetRoomIDsInstruction
    extends Instruction<IsolateRespose<List<String?>>> {
  GetRoomIDsInstruction({required super.instructionId});
}

class GetRoomInstruction extends Instruction<IsolateRespose<Room>> {
  final String roomId;
  final Context? context;
  final List<UserId> memberIds;

  GetRoomInstruction({
    required this.roomId,
    required this.context,
    required this.memberIds,
    required super.instructionId,
  });
}

class SaveRoomToDBInstruction extends Instruction<IsolateRespose> {
  final Room room;

  SaveRoomToDBInstruction({
    required this.room,
    required super.instructionId,
  });
}

class OneRoomSyncInstruction extends Instruction<IsolateRespose<Room>> {
  final String roomId;
  final Context? context;
  final UserId? userId;

  OneRoomSyncInstruction({
    required this.roomId,
    this.context,
    this.userId,
    required super.instructionId,
  });
}

class StartSyncInstruction extends StorageSyncInstruction<IsolateRespose> {
  @override
  bool get expectsReturnValue => false;

  final Duration maxRetryAfter;
  final int timelineLimit;
  final String? syncToken;

  StartSyncInstruction({
    required this.maxRetryAfter,
    required this.timelineLimit,
    this.syncToken,
    required super.instructionId,
  });
}

class RunSyncOnceInstruction extends StorageSyncInstruction<IsolateRespose<SyncToken>> {
  final SyncFilter filter;

  RunSyncOnceInstruction({
    required this.filter,
    required super.instructionId,
  });
}

class StopSyncInstruction extends StorageSyncInstruction<IsolateRespose> {
  StopSyncInstruction({required super.instructionId});
}

class CloseRoomSync extends StorageSyncInstruction<IsolateRespose<bool>> {
  final String roomId;

  CloseRoomSync({
    required this.roomId,
    required super.instructionId,
  });
}

class CloseAllRoomsSync extends StorageSyncInstruction<IsolateRespose<bool>> {
  CloseAllRoomsSync({required super.instructionId});
}

class KickInstruction extends RequestInstruction<MemberTimeline> {
  final UserId id;
  final RoomId? from;

  KickInstruction({
    required this.id,
    this.from,
    required super.instructionId,
  });

  @override
  final bool basedOnUpdate = true;
}

class LoadRoomEventsInstruction extends RequestInstruction<Timeline> {
  final RoomId? roomId;
  final int count;
  final Room? room;

  @override
  final bool basedOnUpdate = true;

  LoadRoomEventsInstruction({
    this.roomId,
    required this.count,
    this.room,
    required super.instructionId,
  });
}

class LoadMembersInstruction extends RequestInstruction<MemberTimeline> {
  final RoomId? roomId;
  final int count;
  final Room? room;

  LoadMembersInstruction({
    this.roomId,
    required this.count,
    this.room,
    required super.instructionId,
  });
}

class LoadRoomsByIDsInstruction extends RequestInstruction<Rooms> {
  final List<RoomId> roomIds;
  final int timelineLimit;

  LoadRoomsByIDsInstruction({
    required this.roomIds,
    required this.timelineLimit,
    required super.instructionId,
  });
}

class LoadRoomsInstruction extends RequestInstruction<Rooms> {
  final int timelineLimit;
  final int limit;
  final int offset;

  LoadRoomsInstruction({
    required this.limit,
    required this.offset,
    required this.timelineLimit,
    required super.instructionId,
  });
}

class LogoutInstruction extends RequestInstruction<MyUser> {
  @override
  final bool basedOnUpdate = true;

  LogoutInstruction({required super.instructionId});
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
    required super.instructionId,
  });
}

class SendInstruction extends RequestInstruction<Timeline> {
  final RoomId roomId;
  final EventContent content;
  final String? transactionId;
  final String stateKey;
  final String type;
  final Room? room;

  SendInstruction({
    required this.roomId,
    required this.content,
    this.transactionId,
    required this.stateKey,
    required this.type,
    this.room,
    required super.instructionId,
  });
}

class EditTextEventInstruction extends RequestInstruction<Timeline> {
  final RoomId roomId;
  final TextMessageEvent event;
  final String? transactionId;
  final String newContent;
  final Room? room;

  EditTextEventInstruction({
    required this.roomId,
    required this.event,
    required this.newContent,
    this.transactionId,
    this.room,
    required super.instructionId,
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

  DeleteEventInstruction({
    required this.roomId,
    required this.eventId,
    this.transactionId,
    this.reason,
    this.room,
    required super.instructionId,
  });

  @override
  final bool basedOnUpdate = true;
}

class SetIsTypingInstruction extends RequestInstruction<EphemeralEventFull> {
  final RoomId? roomId;
  final bool isTyping;
  final Duration timeout;

  // ignore: avoid_positional_boolean_parameters
  SetIsTypingInstruction({
    this.roomId,
    required this.isTyping,
    required this.timeout,
    required super.instructionId,
  });

  @override
  final bool basedOnUpdate = true;
}

class JoinRoomInstruction extends RequestInstruction<Room> {
  final RoomId? id;
  final RoomAlias? alias;
  final Uri serverUrl;

  JoinRoomInstruction({
    this.id,
    this.alias,
    required this.serverUrl,
    required super.instructionId,
  });

  @override
  final bool basedOnUpdate = true;
}

class LeaveRoomInstruction extends RequestInstruction<Room> {
  final RoomId id;

  LeaveRoomInstruction({
    required this.id,
    required super.instructionId,
  });

  @override
  final bool basedOnUpdate = true;
}

class SetNameInstruction extends RequestInstruction<MyUser> {
  final String name;

  SetNameInstruction({
    required this.name,
    required super.instructionId,
  });
}

class SetPusherInstruction extends RequestInstruction<MyUser> {
  final Map<String, dynamic> pusher;

  SetPusherInstruction({
    required this.pusher,
    required super.instructionId,
  });

  @override
  final bool basedOnUpdate = true;
}
