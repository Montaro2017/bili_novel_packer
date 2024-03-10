import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:fast_gbk/fast_gbk.dart';
import 'package:http/http.dart' as http;
import 'package:retry/retry.dart';

class HttpUtil {
  // 默认超时时间 单位秒
  static const int defaultTimeout = 30;
  // 最大重试次数
  static const int maxAttempts = 5;

  HttpUtil._();

  static Future<T> _retry<T>(
    FutureOr<T> Function() fn,
  ) {
    return retry(
      fn,
      retryIf: (e) =>
          e is SocketException ||
          e is TimeoutException ||
          e is HandshakeException,
      maxAttempts: maxAttempts,
    );
  }

  static Future<Uint8List> getBytes(
    String url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: defaultTimeout),
  }) async {
    return _retry(
      () => http.get(Uri.parse(url), headers: headers).timeout(timeout),
    ).then((response) => response.bodyBytes);
  }

  static Future<String> getString(
    String url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: defaultTimeout),
  }) async {
    return _retry(
      () => http.get(Uri.parse(url), headers: headers).timeout(timeout),
    ).then((response) {
      return response.body;
    });
  }

  static Future<String> getStringFromGbk(
    String url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: defaultTimeout),
  }) async {
    return _retry(
      () => http.get(Uri.parse(url), headers: headers).timeout(timeout),
    ).then((response) => gbk.decode(response.bodyBytes));
  }
}
