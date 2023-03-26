import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:retry/retry.dart';

class HttpUtil {
  static get(
    String url, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    return retry(
      () => http.get(Uri.parse(url)).timeout(timeout),
      retryIf: (e) => e is SocketException || e is TimeoutException,
    );
  }
}
