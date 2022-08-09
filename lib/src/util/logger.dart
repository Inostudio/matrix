import 'package:logger/logger.dart';

enum LoggerVariant { none, dev }

class Log {
  static void setLogger(LoggerVariant variant) {
    _variant = variant;
    switch (variant) {
      case LoggerVariant.none:
        _writer = LogWriterNone();
        break;
      case LoggerVariant.dev:
        _writer = LogWriterDevelopment();
        break;
    }
  }

  static LoggerVariant _variant = LoggerVariant.none;

  static ILogWriter _writer = LogWriterNone();

  static LoggerVariant get variant => _variant;

  static ILogWriter get writer => _writer;
}

abstract class ILogWriter {
  void log(dynamic sender, [String? message]);
}

class LogWriterNone extends ILogWriter {
  @override
  void log(dynamic sender, [String? message]) {}
}

class LogWriterDevelopment extends ILogWriter {
  final logger = Logger(
    output: ConsoleOutput(),
    printer: PrettyPrinter(printEmojis: false),
  );

  @override
  void log(dynamic sender, [String? message]) => logger.d(sender, message);
}

class ConsoleOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    event.lines.forEach(printWrapped);
  }

  void printWrapped(String text) {
    final pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
    pattern.allMatches(text).forEach((match) => print(match.group(0)));
  }
}
