import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:retry/retry.dart';

/// 默认超时时间 单位秒
const int defaultTimeout = 30;

/// 最大重试次数
const int defaultMaxAttempts = 5;

Future<T> _retry<T>(
  FutureOr<T> Function() fn, {
  int maxAttempts = defaultMaxAttempts,
}) {
  return retry(
    fn,
    retryIf: (e) =>
        e is SocketException ||
        e is TimeoutException ||
        e is HandshakeException,
    maxAttempts: maxAttempts,
  );
}

Future<Response> httpGetResponse(
  String url, {
  Map<String, String>? headers,
  Duration timeout = const Duration(seconds: defaultTimeout),
}) {
  return _retry(
    () => http.get(Uri.parse(url), headers: headers).timeout(timeout),
  );
}

Future<String> httpGetString(
  String url, {
  Map<String, String>? headers,
  Duration timeout = const Duration(seconds: defaultTimeout),
  Codec codec = const Utf8Codec(),
  int? maxAttempts,
}) {
  return _retry(
    () => http
        .get(
          Uri.parse(url),
          headers: headers,
        )
        .timeout(timeout),
    maxAttempts: maxAttempts ?? defaultMaxAttempts,
  ).then((response) {
    return codec.decode(response.bodyBytes);
  });
}

Future<Uint8List> httpGetBytes(
  String url, {
  Map<String, String>? headers,
  Duration timeout = const Duration(seconds: defaultTimeout),
  Codec codec = const Utf8Codec(),
  int? maxAttempts,
}) {
  return _retry(
    () => http
        .get(
          Uri.parse(url),
          headers: headers,
        )
        .timeout(timeout),
    maxAttempts: maxAttempts ?? defaultMaxAttempts,
  ).then((response) {
    return response.bodyBytes;
  });
}