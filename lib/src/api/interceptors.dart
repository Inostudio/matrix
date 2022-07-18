import 'dart:async';

import 'package:chopper/chopper.dart';

import '../util/logger.dart';

String get _separator => "${"=" * 20}";

class LogRequestInterceptor implements RequestInterceptor {
  @override
  FutureOr<Request> onRequest(Request request) {
    final url = request.url;
    final baseUrl = request.baseUrl;
    final method = request.method;
    final body = request.body;
    final header = request.headers;
    Log.writer.log(
      """
    MATRIX REQUEST $method $baseUrl$url
    $_separator
    HEADER $header
    $_separator
    BODY $body
      """,
    );

    return request;
  }
}

class LogResponseInterceptor implements ResponseInterceptor {
  @override
  FutureOr<Response> onResponse(Response<dynamic> response) {
    final url = response.base.request?.url.path;
    final method = response.base.request?.method;
    final body = response.body;
    final header = response.headers;
    Log.writer.log(
      """
    MATRIX RESPONSE $method $url
    $_separator
    HEADER $header
    $_separator
    BODY $body
        """,
    );
    return response;
  }
}
