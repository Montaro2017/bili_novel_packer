import 'dart:io';

import 'package:dio/dio.dart';

typedef LogPrinter = void Function(Object? message);

enum LoggingInterceptorLevel {
  none,
  basic,
}

class LoggingInterceptor extends Interceptor {
  static const String _startTimeKey = "logging_interceptor_start_time";

  LoggingInterceptorLevel level;
  final LogPrinter printer;

  LoggingInterceptor({
    this.level = LoggingInterceptorLevel.basic,
    LogPrinter? printer,
  }) : printer = printer ?? print;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (level == LoggingInterceptorLevel.none) {
      handler.next(options);
      return;
    }
    options.extra[_startTimeKey] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (level == LoggingInterceptorLevel.none) {
      handler.next(response);
      return;
    }

    RequestOptions options = response.requestOptions;
    Duration duration = _duration(options);
    int? statusCode = response.statusCode;
    String statusMessage = response.statusMessage ?? "";

    String status = statusMessage.isEmpty
        ? statusCode.toString()
        : "$statusCode $statusMessage";

    if (statusCode == 301 || statusCode == 302) {
      var location = response.headers[HttpHeaders.locationHeader]?.firstOrNull;
      _log("${options.method} ${options.uri} $status -> $location (${duration.inMilliseconds}ms)");
    } else {
      _log("${options.method} ${options.uri} $status (${duration.inMilliseconds}ms)");
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (level == LoggingInterceptorLevel.none) {
      handler.next(err);
      return;
    }

    RequestOptions options = err.requestOptions;
    Duration duration = _duration(options);
    _log("${options.method} ${options.uri} HTTP FAILED: ${err.message} (${duration.inMilliseconds}ms)");
    handler.next(err);
  }

  Duration _duration(RequestOptions options) {
    Object? startTime = options.extra[_startTimeKey];
    if (startTime is DateTime) {
      return DateTime.now().difference(startTime);
    }
    return Duration.zero;
  }

  void _log(Object? message) {
    printer(message);
  }
}
