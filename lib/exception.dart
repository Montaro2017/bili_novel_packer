class NotRetryableException implements Exception {
  final dynamic message;

  NotRetryableException(this.message);
}
