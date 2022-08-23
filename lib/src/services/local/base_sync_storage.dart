import 'package:matrix_sdk/matrix_sdk.dart';

import '../../model/context.dart';

abstract class BaseSyncStorage {
  Stream<MyUser> myUserStorageSync();

  Stream<Room> roomStorageSync({
    required String selectedRoomId,
    required UserId userId,
    Context? context,
  });

  bool isReady();

  Future<void> setUserDelta(MyUser user);

  Future<void> setRoom(Room room);

  Future<List<String?>?> getRoomIds();

  Future<Iterable<Room>> getRoomsByIds(
    Iterable<RoomId>? roomIds, {
    Context? context,
    required int timelineLimit,
    Iterable<UserId>? memberIds,
  });

  Future<Iterable<Room>> getRooms({
    Context? context,
    required int limit,
    required int offset,
    required int timelineLimit,
    Iterable<UserId>? memberIds,
  });

  Future<Messages> getMessages(
    RoomId roomId, {
    int count = 20,
    DateTime? fromTime,
    Iterable<UserId>? memberIds,
  });

  Future<Iterable<Member>> getMembers(
    RoomId roomId, {
    int count = 20,
    DateTime? fromTime,
  });

  Future<Room?> getRoom(
    RoomId id, {
    int timelineLimit = 15,
    required Context context,
    required Iterable<UserId> memberIds,
  });

  Future<String?> getToken();

  Future<MyUser?> getMyUser({
    List<RoomId>? roomIds,
    int timelineLimit,
  });

  Future<bool> ensureOpen();

  Future<void> close();

  Future<void> wipeAllData();
}