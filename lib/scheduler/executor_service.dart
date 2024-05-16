typedef ExecutorTask<T> = Future<T> Function(ExecutorService service);

abstract class ExecutorService {
  bool _lock = false;

  Future<List<T>> invokeAll<T>(
    List<ExecutorTask<T>> tasks, {
    Duration? delay,
  });

  void lock() => _lock = true;

  void unlock() => _lock = false;

  bool isLock() => _lock;

  Future<void> _waitUnlock() async {
    while (_lock) {
      await Future.delayed(Duration(milliseconds: 10));
    }
  }
}

class ParallelExecutorService extends ExecutorService {
  int batchSize;

  ParallelExecutorService([this.batchSize = 10]);

  @override
  Future<List<T>> invokeAll<T>(
    List<ExecutorTask<T>> tasks, {
    Duration? delay,
  }) async {
    List<T> results = [];
    List<Future<T>> futures = [];
    for (int i = 0; i < tasks.length; i++) {
      await _waitUnlock();
      Future<T> future = tasks[i].call(this);
      futures.add(future);
      if (futures.length % batchSize == 0) {
        results.addAll(await Future.wait(futures));
        futures.clear();
        if (i != tasks.length - 1 && delay != null) {
          await Future.delayed(delay);
        }
      }
    }
    if (futures.isNotEmpty) {
      results.addAll(await Future.wait(futures));
    }
    return results;
  }
}

class SequentialExecutorService extends ParallelExecutorService {
  @override
  get batchSize => 1;
}
