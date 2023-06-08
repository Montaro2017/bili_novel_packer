import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:fast_gbk/fast_gbk.dart';
import 'package:http/http.dart' as http;
import 'package:retry/retry.dart';

class HttpUtil {

  // 默认超时时间 单位秒
  static const int defaultTimeout = 10;

  HttpUtil._();

  static Future<Uint8List> getBytes(
    String url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: defaultTimeout),
  }) async {
    return retry(
      () => http.get(Uri.parse(url), headers: headers).timeout(timeout),
      retryIf: (e) => e is SocketException || e is TimeoutException,
    ).then((response) => response.bodyBytes);
  }

  static Future<String> getString(
    String url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: defaultTimeout),
  }) async {
    return retry(
      () => http.get(Uri.parse(url), headers: headers).timeout(timeout),
      retryIf: (e) => e is SocketException || e is TimeoutException,
    ).then((response) => response.body);
  }

  static Future<String> getStringFromGbk(
    String url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: defaultTimeout),
  }) async {
    return retry(
      () => http.get(Uri.parse(url), headers: headers).timeout(timeout),
      retryIf: (e) => e is SocketException || e is TimeoutException,
    ).then((response) => gbk.decode(response.bodyBytes));
  }
}
