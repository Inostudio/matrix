import 'package:logger/logger.dart';

class Log {
  static ILogWriter writer = LogWriterNone();
}

abstract class ILogWriter {
  void log(dynamic sender, [String? message]);
}

class LogWriterNone extends ILogWriter {
  @override
  void log(dynamic sender, [String? message]) {}
}

class LogWriterDevelopment extends ILogWriter {
  final logger = Logger(output: ConsoleOutput());

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
