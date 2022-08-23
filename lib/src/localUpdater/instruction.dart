import 'package:meta/meta.dart';

@immutable
class IsolateStorageStartSyncInstruction {}

@immutable
class IsolateStorageStopSyncInstruction {}

@immutable
class IsolateStorageOneRoomStartSyncInstruction {
  final String roomId;

  const IsolateStorageOneRoomStartSyncInstruction({
    required this.roomId,
  });
}

@immutable
class IsolateStorageOneRoomStopSyncInstruction {}
