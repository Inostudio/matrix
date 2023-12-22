import 'package:matrix_sdk/matrix_sdk.dart';

import '../../model/context.dart';

abstract class BaseSyncStorage {
  Stream<MyUser> myUserStorageSync({required int timelineLimit});

  Stream<Room> roomStorageSync({
    required String selectedRoomId,
    required UserId userId,
    Context? context,
  });

  Future<Iterable<Room>> getRoomsByIds(
    Iterable<RoomId>? roomIds, {
    required int timelineLimit,
    Iterable<UserId>? memberIds,
    Context? context,
  });

  Future<Room?> getRoom(
    RoomId id, {
    int timelineLimit = 15,
    required Iterable<UserId> memberIds,
    Context? context,
  });

  bool isReady();

  Future<void> setUserDelta(MyUser user);

  Future<void> setRoom(Room room);

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

  Future<String?> getToken();

  Future<MyUser?> getLightWeightUser();

  Future<MyUser?> getMyUser({
    List<RoomId>? roomIds,
    int timelineLimit,
  });

  Future<bool> addFakeEvent(RoomEvent fakeRoomEvent);

  Future<bool> deleteFakeEvent(String transactionId);

  Future<List<RoomEvent>> getAllFakeEvents();

  Future<bool> ensureOpen();

  Future<void> close();

  Future<void> wipeAllData();
}
