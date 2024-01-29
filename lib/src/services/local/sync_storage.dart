import 'package:matrix_sdk/src/model/context.dart';
import 'package:matrix_sdk/src/services/local/base_sync_storage.dart';

import '../../../matrix_sdk.dart';

class SyncStorage implements BaseSyncStorage {
  late Store store;

  SyncStorage({
    required StoreLocation storeLocation,
  }) {
    store = storeLocation.create();
    store.open();
  }

  @override
  Stream<MyUser> myUserStorageSync({required int timelineLimit}) =>
      store.myUserStorageSync(timelineLimit: timelineLimit);

  @override
  Stream<Room> roomStorageSync({
    required String selectedRoomId,
    required UserId userId,
    Context? context,
  }) =>
      store.roomStorageSync(
        selectedRoomId: selectedRoomId,
        userId: userId,
        context: context,
      );

  @override
  Future<bool> ensureOpen() => store.ensureOpen();

  @override
  Future<void> close() => store.close();

  @override
  Future<Iterable<Member>> getMembers(
    RoomId roomId, {
    int count = 20,
    DateTime? fromTime,
  }) =>
      store.getMembers(roomId, count: count, fromTime: fromTime);

  @override
  Future<Messages> getMessages(
    RoomId roomId, {
    int count = 20,
    DateTime? fromTime,
    Iterable<UserId>? memberIds,
  }) =>
      store.getMessages(
        roomId,
        count: count,
        fromTime: fromTime,
        memberIds: memberIds,
      );

  @override
  Future<Room?> getRoom(
    RoomId id, {
    int timelineLimit = 15,
    Context? context,
    required Iterable<UserId> memberIds,
  }) =>
      store.getRoom(
        id,
        context: context,
        memberIds: memberIds,
        timelineLimit: timelineLimit,
      );

  @override
  Future<Iterable<Room>> getRooms({
    Context? context,
    required int limit,
    required int offset,
    required int timelineLimit,
    Iterable<UserId>? memberIds,
  }) =>
      store.getRooms(
        context: context,
        limit: limit,
        offset: offset,
        timelineLimit: timelineLimit,
        memberIds: memberIds,
      );

  @override
  Future<Iterable<Room>> getRoomsByIds(
    Iterable<RoomId>? roomIds, {
    Context? context,
    required int timelineLimit,
    Iterable<UserId>? memberIds,
  }) =>
      store.getRoomsByIDs(
        roomIds,
        context: context,
        timelineLimit: timelineLimit,
        memberIds: memberIds,
      );

  @override
  Future<String?> getToken() async => store.getSyncToken();

  @override
  Future<MyUser?> getLightWeightUser() async => store.getLightWeightUser();

  @override
  Future<MyUser?> getMyUser({
    List<RoomId>? roomIds,
    int timelineLimit = 100,
  }) async =>
      store.getMyUser(
        roomIds: roomIds,
        timelineLimit: timelineLimit,
      );

  @override
  Future<void> deleteUser(String userID) async => store.deleteUser(userID);

  @override
  bool isReady() => store.isOpen;

  @override
  Future<void> setRoom(Room room) => store.setRoom(room);

  @override
  Future<void> setUserDelta(MyUser user) => store.setMyUserDelta(user);

  @override
  Future<void> wipeAllData() => store.wipeAllData();

  @override
  Future<List<RoomEvent>> getAllFakeEvents() => store.getAllFakeEvents();

  @override
  Future<bool> addFakeEvent(RoomEvent fakeRoomEvent) => store.addFakeEvent(fakeRoomEvent);

  @override
  Future<bool> deleteFakeEvent(String transactionId) {
    return store.deleteFakeMessage(transactionId);
  }
}
