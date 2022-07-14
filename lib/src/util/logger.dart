import 'package:logger/logger.dart';

class Log {
  Log._internal();

  static final Log _instance = Log._internal();

  factory Log() => _instance;

  ILogWriter writer = LogWriterNone();
}

abstract class ILogWriter {
  void log(dynamic sender, [String? message]);
}

class LogWriterNone extends ILogWriter {
  @override
  void log(dynamic sender, [String? message]) {}
}

class LogWriterDevelopment extends ILogWriter {
  final logger = Logger();

  @override
  void log(dynamic sender, [String? message]) => logger.d(sender, message);
}
