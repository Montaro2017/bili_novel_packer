import 'dart:async';

typedef Predicate<T> = bool Function(T data);

Future<T> retryByResult<T>(
  FutureOr<T> Function() fn, {
  int maxRetries = 10,
  Predicate<T>? predicate,
  Duration? delay,
  Function? onRetry,
  Function? onFinish,
}) async {
  bool shouldRetry = false;
  T result;
  int retryCount = 0;
  do {
    if (shouldRetry) {
      if (delay != null) {
        await Future.delayed(delay);
      }
      onRetry?.call();
      retryCount++;
    }
    result = await fn.call();
    shouldRetry = predicate != null && predicate.call(result);
    if(shouldRetry && retryCount >= maxRetries) {
      throw "Retry failed: $retryCount attempts made.";
    }
  } while (shouldRetry);
  onFinish?.call();
  return Future.value(result);
}
