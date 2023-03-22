import 'package:meta/meta.dart';

@immutable
class ApiCallStatistics {
  final String method;
  final String requestMethod;
  final String requestUrl;
  final int responseTimeMillis;
  final int responseStatusCode;
  final int bytesSend;
  final int bytesReceived;
  final String responseText;

  const ApiCallStatistics({
    required this.method,
    required this.requestMethod,
    required this.requestUrl,
    required this.responseTimeMillis,
    required this.responseStatusCode,
    required this.bytesSend,
    required this.bytesReceived,
    required this.responseText,
  });

  Map<String, dynamic> toJson() {
    return {
      "method": method,
      "request_method": requestMethod,
      "request_url": requestUrl,
      "response_time": responseTimeMillis,
      "response_code": responseStatusCode,
      "bytes_send": bytesSend,
      "bytes_received": bytesReceived,
      "response_text": responseText,
    };
  }

  @override
  String toString() {
    return 'ApiCallStatistics{method: $method, requestMethod: $requestMethod, requestUrl: $requestUrl, responseTimeMillis: $responseTimeMillis, responseStatusCode: $responseStatusCode, bytesSend: $bytesSend, bytesReceived: $bytesReceived, responseText: $responseText}';
  }
}
