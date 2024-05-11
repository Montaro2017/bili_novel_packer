typedef FutureFunction<T> = Future<T> Function();

abstract class Scheduler {
  Future<List<T>> execute<T>(List<FutureFunction<T>> tasks, {Object? key});
}
