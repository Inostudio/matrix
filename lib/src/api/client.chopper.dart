// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// ignore_for_file: always_put_control_body_on_new_line, always_specify_types, prefer_const_declarations, unnecessary_brace_in_string_interps
class _$ClientService extends ClientService {
  _$ClientService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final definitionType = ClientService;

  @override
  Future<Response<dynamic>> login(String body) {
    final Uri $url = Uri.parse('/_matrix/client/r0/login');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> profile({
    required String authorization,
    required String userId,
  }) {
    final Uri $url = Uri.parse('/_matrix/client/r0/profile/${userId}');
    final Map<String, String> $headers = {
      'Authorization': authorization,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      headers: $headers,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> profileSetDisplayName({
    required String authorization,
    required String userId,
    required String body,
  }) {
    final Uri $url =
        Uri.parse('/_matrix/client/r0/profile/${userId}/displayname');
    final Map<String, String> $headers = {
      'Authorization': authorization,
    };
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      headers: $headers,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> setPusher({
    required String authorization,
    required String body,
  }) {
    final Uri $url = Uri.parse('/_matrix/client/r0/pushers/set');
    final Map<String, String> $headers = {
      'Authorization': authorization,
    };
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      headers: $headers,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> register({
    required String kind,
    required String body,
  }) {
    final Uri $url = Uri.parse('/_matrix/client/r0/register');
    final Map<String, dynamic> $params = <String, dynamic>{'kind': kind};
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> sync({
    required String authorization,
    required String since,
    bool fullState = false,
    required String filter,
    int timeout = 0,
  }) {
    final Uri $url = Uri.parse('/_matrix/client/r0/sync');
    final Map<String, dynamic> $params = <String, dynamic>{
      'since': since,
      'full_state': fullState,
      'filter': filter,
      'timeout': timeout,
    };
    final Map<String, String> $headers = {
      'Authorization': authorization,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      headers: $headers,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> roomMessages({
    required String authorization,
    required String roomId,
    required String from,
    required int limit,
    String dir = 'b',
    required String filter,
  }) {
    final Uri $url = Uri.parse('/_matrix/client/r0/rooms/${roomId}/messages');
    final Map<String, dynamic> $params = <String, dynamic>{
      'from': from,
      'limit': limit,
      'dir': dir,
      'filter': filter,
    };
    final Map<String, String> $headers = {
      'Authorization': authorization,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      headers: $headers,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> members({
    required String authorization,
    required String roomId,
    required String at,
    required String membership,
  }) {
    final Uri $url = Uri.parse('/_matrix/client/r0/rooms/${roomId}/members');
    final Map<String, dynamic> $params = <String, dynamic>{
      'at': at,
      'membership': membership,
    };
    final Map<String, String> $headers = {
      'Authorization': authorization,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      headers: $headers,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> send({
    required String authorization,
    required String roomId,
    required String eventType,
    required String txnId,
    required String content,
  }) {
    final Uri $url = Uri.parse(
        '/_matrix/client/r0/rooms/${roomId}/send/${eventType}/${txnId}');
    final Map<String, String> $headers = {
      'Authorization': authorization,
    };
    final $body = content;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      headers: $headers,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> edit({
    required String authorization,
    required String roomId,
    required String txnId,
    required String content,
  }) {
    final Uri $url = Uri.parse(
        '/_matrix/client/r0/rooms/${roomId}/send/m.room.message/${txnId}');
    final Map<String, String> $headers = {
      'Authorization': authorization,
    };
    final $body = content;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      headers: $headers,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> redact({
    required String authorization,
    required String roomId,
    required String eventId,
    required String txnId,
    required String content,
  }) {
    final Uri $url = Uri.parse(
        '/_matrix/client/r0/rooms/${roomId}/redact/${eventId}/${txnId}');
    final Map<String, String> $headers = {
      'Authorization': authorization,
    };
    final $body = content;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      headers: $headers,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> sendState({
    required String authorization,
    required String roomId,
    required String eventType,
    required String stateKey,
    required String content,
  }) {
    final Uri $url = Uri.parse(
        '/_matrix/client/r0/rooms/${roomId}/state/${eventType}/${stateKey}');
    final Map<String, String> $headers = {
      'Authorization': authorization,
    };
    final $body = content;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      headers: $headers,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> typing({
    required String authorization,
    required String roomId,
    required String userId,
    required String body,
  }) {
    final Uri $url =
        Uri.parse('/_matrix/client/r0/rooms/${roomId}/typing/${userId}');
    final Map<String, String> $headers = {
      'Authorization': authorization,
    };
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
      headers: $headers,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> readMarkers({
    required String authorization,
    required String roomId,
    required String body,
  }) {
    final Uri $url =
        Uri.parse('/_matrix/client/r0/rooms/${roomId}/read_markers');
    final Map<String, String> $headers = {
      'Authorization': authorization,
    };
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      headers: $headers,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> kick({
    required String authorization,
    required String roomId,
    required String body,
  }) {
    final Uri $url = Uri.parse('/_matrix/client/r0/rooms/${roomId}/kick');
    final Map<String, String> $headers = {
      'Authorization': authorization,
    };
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      headers: $headers,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> leave({
    required String authorization,
    required String roomId,
  }) {
    final Uri $url = Uri.parse('/_matrix/client/r0/rooms/${roomId}/leave');
    final Map<String, String> $headers = {
      'Authorization': authorization,
    };
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      headers: $headers,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> createRoom({
    required String authorization,
    required String body,
  }) {
    final Uri $url = Uri.parse('/_matrix/client/r0/createRoom');
    final Map<String, String> $headers = {
      'Authorization': authorization,
    };
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      headers: $headers,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> join({
    required String authorization,
    required String roomIdOrAlias,
    required String serverName,
  }) {
    final Uri $url = Uri.parse('/_matrix/client/r0/join/${roomIdOrAlias}');
    final Map<String, dynamic> $params = <String, dynamic>{
      'server_name': serverName
    };
    final Map<String, String> $headers = {
      'Authorization': authorization,
    };
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      parameters: $params,
      headers: $headers,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> logout({required String authorization}) {
    final Uri $url = Uri.parse('/_matrix/client/r0/logout');
    final Map<String, String> $headers = {
      'Authorization': authorization,
    };
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      headers: $headers,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> publicRooms({
    required String authorization,
    required String server,
    required String body,
  }) {
    final Uri $url = Uri.parse('/_matrix/client/r0/publicRooms');
    final Map<String, dynamic> $params = <String, dynamic>{'server': server};
    final Map<String, String> $headers = {
      'Authorization': authorization,
    };
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      headers: $headers,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> search({
    required String authorization,
    required String nextBatch,
    required String body,
  }) {
    final Uri $url = Uri.parse('/_matrix/client/r0/search');
    final Map<String, dynamic> $params = <String, dynamic>{
      'next_batch': nextBatch
    };
    final Map<String, String> $headers = {
      'Authorization': authorization,
    };
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      parameters: $params,
      headers: $headers,
    );
    return client.send<dynamic, dynamic>($request);
  }
}
