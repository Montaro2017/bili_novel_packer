import 'dart:async';
import 'dart:io';

import 'package:retry/retry.dart';
import 'package:http/http.dart' as http;

retryGet(
  String url, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  return retry(
    () => http.get(Uri.parse(url)).timeout(timeout),
    retryIf: (e) => e is SocketException || e is TimeoutException,
  );
}
