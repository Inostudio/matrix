//TODO add token refresh and syncer and remove accessToken everywhere

import '../../../matrix_sdk.dart';

abstract class BaseNetwork {

  Future<void> putProfileDisplayName({
    required String accessToken,
    required String userId,
    required String value,
  });

  Future<void> kickFromRoom({
    required String accessToken,
    required String roomId,
    required String userId,
  });

  Future<Uri?> uploadImage({
    required MyUser as,
    required Stream<List<int>> bytes,
    required int length,
    required String contentType,
    String fileName = '',
  });

  Future<Map<String, dynamic>> sendRoomsState({
    required String accessToken,
    required String roomId,
    required String eventType,
    required String stateKey,
    required Map<String, dynamic> content,
  });

  Future<Map<String, dynamic>> roomsSend({
    required String accessToken,
    required String roomId,
    required String eventType,
    required String transactionId,
    required Map<String, dynamic> content,
  });

  Future<Map<String, dynamic>> roomEdit({
    required String accessToken,
    required String roomId,
    required TextMessageEvent event,
    required String newContent,
    required String transactionId,
  });

  Future<Map<String, dynamic>> eventReact({
    required String accessToken,
    required String roomId,
    required EventId eventId,
    required String content,
    required String key,
    required String transactionId,
  });

  Future<Map<String, dynamic>> roomsRedact({
    required String accessToken,
    required String roomId,
    required String eventId,
    String transactionId = '',
    Map? reason,
  });

  Future<void> setRoomsReadMarkers({
    required String accessToken,
    required String roomId,
    String? fullyRead,
    String? read,
  });

  Future<void> logout({
    required String accessToken,
  });

  Future<Map<String, dynamic>> getRoomMessages({
    required String accessToken,
    required String roomId,
    required int limit,
    required String from,
    required Map<String, dynamic> filter,
  });

  Future<Map<String, dynamic>> getRoomMembers({
    required String accessToken,
    required String roomId,
    required String at,
  });

  Future<void> setRoomTyping({
    required String accessToken,
    required String roomId,
    required String userId,
    required bool typing,
    int timeout = 0,
  });

  Future<Map<String, dynamic>> joinToRoom({
    required String accessToken,
    required String roomIdOrAlias,
    required String serverName,
  });

  Future<void> leaveRoom({
    required String accessToken,
    required String roomId,
  });

  Future<bool> setPusher({
    required String accessToken,
    required Map<String, dynamic> body,
  });
}
