import 'package:dio/dio.dart';

const _retryInfoKey = "retry_info";

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration delay;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.delay = Duration.zero,
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (!_shouldRetry(err)) {
      super.onError(err, handler);
      return;
    }
    await _delay(err);
    await _retry(err, handler);
  }

  bool _shouldRetry(DioException err) {
    if (err.isCanceled()) {
      return false;
    }
    if (err.retried >= maxRetries) {
      return false;
    }
    return true;
  }

  Future<void> _delay(DioException err) async {
    if (delay.compareTo(Duration.zero) <= 0) {
      return;
    }
    await Future.delayed(delay);
  }

  Future<void> _retry(DioException err, ErrorInterceptorHandler handler) async {
    err.retried++;
    var resp = await dio.fetch(err.requestOptions);
    handler.resolve(resp);
  }
}

class _RetryInfo {
  int retried = 0;
}

extension _RetryInfoExt on DioException {
  bool isCanceled() {
    var opts = requestOptions;
    return opts.cancelToken?.isCancelled ?? false;
  }

  int get retried => retryInfo().retried;

  set retried(int retried) => retryInfo().retried = retried;

  _RetryInfo retryInfo() {
    var opts = requestOptions;
    opts.extra[_retryInfoKey] ??= _RetryInfo();
    return opts.extra[_retryInfoKey];
  }
}
