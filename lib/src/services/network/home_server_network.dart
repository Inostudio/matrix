import 'package:matrix_sdk/src/services/network/base_network.dart';

import '../../../matrix_sdk.dart';

class HomeServerNetworking implements BaseNetwork {
  final Homeserver _homeServer;

  HomeServerNetworking({
    required Homeserver homeServer,
  }) : _homeServer = homeServer;

  @override
  Future<Map<String, dynamic>> getRoomMembers({
    required String accessToken,
    required String roomId,
    required String at,
  }) async =>
      _homeServer.api.rooms.members(
        accessToken: accessToken,
        roomId: roomId,
        at: at,
      );

  @override
  Future<Map<String, dynamic>> getRoomMessages({
    required String accessToken,
    required String roomId,
    required int limit,
    required String from,
    required Map<String, dynamic> filter,
  }) async =>
      _homeServer.api.rooms.messages(
        accessToken: accessToken,
        roomId: roomId,
        limit: limit,
        from: from,
        filter: filter,
      );

  @override
  Future<Map<String, dynamic>> joinToRoom({
    required String accessToken,
    required String roomIdOrAlias,
    required String serverName,
  }) async =>
      _homeServer.api.join(
        accessToken: accessToken,
        roomIdOrAlias: roomIdOrAlias,
        serverName: serverName,
      );

  @override
  Future<void> kickFromRoom({
    required String accessToken,
    required String roomId,
    required String userId,
  }) async =>
      _homeServer.api.rooms.kick(
        accessToken: accessToken,
        roomId: roomId,
        userId: userId,
      );

  @override
  Future<void> leaveRoom({
    required String accessToken,
    required String roomId,
  }) async =>
      _homeServer.api.rooms.leave(
        accessToken: accessToken,
        roomId: roomId,
      );

  @override
  Future<void> logout({
    required String accessToken,
  }) async =>
      _homeServer.api.logout(accessToken: accessToken);

  @override
  Future<void> putProfileDisplayName({
    required String accessToken,
    required String userId,
    required String value,
  }) async =>
      _homeServer.api.profile.putDisplayName(
        accessToken: accessToken,
        userId: userId,
        value: value,
      );

  @override
  Future<Map<String, dynamic>> roomEdit({
    required String accessToken,
    required String roomId,
    required TextMessageEvent event,
    required String newContent,
    required String transactionId,
  }) async =>
      _homeServer.api.rooms.edit(
        accessToken: accessToken,
        roomId: roomId,
        transactionId: transactionId,
        event: event,
        newContent: newContent,
      );

  @override
  Future<Map<String, dynamic>> eventReact({
    required String accessToken,
    required String roomId,
    required EventId eventId,
    required String content,
    required String key,
    required String transactionId,
  }) async =>
      _homeServer.api.rooms.react(
        accessToken: accessToken,
        roomId: roomId,
        eventId: eventId,
        content: content,
        key: key,
        transactionId: transactionId,
      );

  @override
  Future<Map<String, dynamic>> roomsRedact({
    required String accessToken,
    required String roomId,
    required String eventId,
    String transactionId = '',
    String? reason,
  }) async =>
      _homeServer.api.rooms.redact(
        accessToken: accessToken,
        roomId: roomId,
        eventId: eventId,
        transactionId: transactionId,
        reason: reason,
      );

  @override
  Future<Map<String, dynamic>> roomsSend({
    required String accessToken,
    required String roomId,
    required String eventType,
    required String transactionId,
    required Map<String, dynamic> content,
  }) async =>
      _homeServer.api.rooms.send(
        accessToken: accessToken,
        roomId: roomId,
        eventType: eventType,
        transactionId: transactionId,
        content: content,
      );

  @override
  Future<Map<String, dynamic>> sendRoomsState({
    required String accessToken,
    required String roomId,
    required String eventType,
    required String stateKey,
    required Map<String, dynamic> content,
  }) async =>
      _homeServer.api.rooms.sendState(
        accessToken: accessToken,
        roomId: roomId,
        eventType: eventType,
        stateKey: stateKey,
        content: content,
      );

  @override
  Future<bool> setPusher({
    required String accessToken,
    required Map<String, dynamic> body,
  }) async =>
      _homeServer.api.pushers.set(
        accessToken: accessToken,
        body: body,
      );

  @override
  Future<void> setRoomTyping({
    required String accessToken,
    required String roomId,
    required String userId,
    required bool typing,
    int timeout = 0,
  }) async =>
      _homeServer.api.rooms.typing(
        accessToken: accessToken,
        roomId: roomId,
        userId: userId,
        typing: typing,
        timeout: timeout,
      );

  @override
  Future<void> setRoomsReadMarkers({
    required String accessToken,
    required String roomId,
    String? fullyRead,
    String? read,
  }) async =>
      _homeServer.api.rooms.readMarkers(
        accessToken: accessToken,
        roomId: roomId,
        fullyRead: fullyRead,
        read: read,
      );

  @override
  Future<Uri?> uploadImage({
    required MyUser as,
    required Stream<List<int>> bytes,
    required int length,
    required String contentType,
    String fileName = '',
  }) async =>
      _homeServer.upload(
        as: as,
        bytes: bytes,
        length: length,
        contentType: contentType,
        fileName: fileName,
      );
}
