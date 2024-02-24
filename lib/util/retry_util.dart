import 'dart:async';

typedef Predicate<T> = bool Function(T data);

Future<T> retryByResult<T>(
  FutureOr<T> Function() fn, {
  Predicate<T>? predicate,
  Duration? delay,
  Function? onRetry,
  Function? onFinish,
}) async {
  bool shouldRetry = false;
  T result;
  do {
    if (shouldRetry && onRetry != null) {
      onRetry.call();
    }
    result = await fn.call();
    shouldRetry = predicate != null && predicate.call(result);
    if (shouldRetry && delay != null) {
      await Future.delayed(delay);
    }
  } while (shouldRetry);
  onFinish?.call();
  return Future.value(result);
}
