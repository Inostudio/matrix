import 'package:matrix_sdk/src/model/context.dart';
import 'package:matrix_sdk/src/services/local/base_sink_storage.dart';

import '../../../matrix_sdk.dart';

class SinkStorage implements BaseSinkStorage {
  late Store store;

  SinkStorage({
    required StoreLocation storeLocation,
  }) {
    store = storeLocation.create();
    store.open();
  }

  @override
  Stream<MyUser> myUserStorageSink(String userId) =>
      store.myUserStorageSink(userId);

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
    required Context context,
    required Iterable<UserId> memberIds,
  }) =>
      store.getRoom(
        id,
        context: context,
        memberIds: memberIds,
        timelineLimit: timelineLimit,
      );

  @override
  Future<List<String?>?> getRoomIds() => store.getRoomIDs();

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
  Future<String?> getToken(String id) async {
    final user = await store.getMyUser(id);
    return user?.syncToken;
  }

  @override
  bool isReady() => store.isOpen;

  @override
  Future<void> setRoom(Room room) => store.setRoom(room);

  @override
  Future<void> setUserDelta(MyUser user) => store.setMyUserDelta(user);
}
