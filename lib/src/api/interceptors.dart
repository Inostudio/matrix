import 'dart:async';

import 'package:chopper/chopper.dart';

import '../util/logger.dart';

String get _separator => "${"=" * 20}";

const int _maxBodyLen = 2000;

class LogRequestInterceptor implements RequestInterceptor {
  @override
  FutureOr<Request> onRequest(Request request) {
    final url = request.url;
    final baseUrl = request.baseUri;
    final method = request.method;
    final body = request.body;
    final params = request.parameters;
    final header = request.headers;
    Log.writer.log(
      """
    MATRIX REQUEST $method $baseUrl$url
    $_separator
    HEADER $header
    Params $params
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
    final error = response.error;
    Log.writer.log(
      """
    MATRIX RESPONSE $method $url
    $_separator
    HEADER $header
    $_separator
    BODY ${body.toString().length > _maxBodyLen ? "LEN ${body.toString().length}" : body}
    ${error == null ? "" : "$_separator\nERROR $error"} 
    """,
    );
    return response;
  }
}
