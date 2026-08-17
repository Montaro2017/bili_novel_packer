import 'dart:io';

import 'package:logger/logger.dart';

const String logFilePath = "bili_novel.log";

final File loggerFile = File(logFilePath);

Logger logger = Logger(
  printer: CustomPrinter(),
  output: FileOutput(
    file: loggerFile,
    overrideExisting: true,
  ),
  filter: ProductionFilter(),
);

class CustomPrinter extends LogPrinter {
  final RegExp _stackTraceRegExp = RegExp(
    "#\\d\\s+(.+)\\s\\((.+):(\\d+):(\\d+)\\)",
  );

  @override
  List<String> log(LogEvent event) {
    String date = event.time.toString().substring(0, 19);
    String level = event.level.name.toUpperCase().padLeft(5);
    String message = event.message.toString();
    StackTrace stackTrace = event.stackTrace ?? StackTrace.current;
    String logger = (_getLogger(stackTrace) ?? "").padRight(30);
    return ["$date [$level] $logger $message"];
  }

  String? _getLogger(StackTrace stackTrace) {
    String loggerLine = stackTrace
        .toString()
        .split("\n")
        .where((line) => !_excludeStackTrace(line))
        .first;
    var match = _stackTraceRegExp.firstMatch(loggerLine);
    if (match == null) {
      return null;
    }
    var segment = match.group(2);
    if (segment == null) {
      return null;
    }
    var fileName = Uri.parse(segment).pathSegments.last;
    var lineNumber = match.group(3);

    return "$fileName:$lineNumber";
  }

  bool _excludeStackTrace(String stackTraceLine) {
    List<String> excludePrefixes = [
      "package:bili_novel_packer/logger.dart",
      "package:logger",
    ];
    var match = _stackTraceRegExp.firstMatch(stackTraceLine);
    if (match == null) {
      return false;
    }
    var segment = match.group(2);
    if (segment == null) {
      return false;
    }
    return excludePrefixes.any((prefix) => segment.startsWith(prefix));
  }
}
