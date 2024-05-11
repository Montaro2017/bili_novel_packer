import 'package:bili_novel_packer/scheduler/scheduler.dart';

class Executor {
  Executor._();

  static Future<List<T>> parallel<T>(
    List<FutureFunction<T>> tasks, {
    int? batchSize,
    Duration? delay,
  }) async {
    batchSize ??= tasks.length;
    int index = 0;
    List<T> results = [];
    while (index < tasks.length) {
      List<FutureFunction<T>> functions =
          tasks.skip(index).take(batchSize).toList();
      List<Future<T>> futures = functions.map((e) => e()).toList();
      results.addAll(await Future.wait(futures));
      index += batchSize;
      if (delay != null) {
        await Future.delayed(delay);
      }
    }
    return Future.value(results);
  }

  static Future<List<T>> sequential<T>(
    List<FutureFunction> tasks, {
    Duration? delay,
  }) async {
    List<T> results = [];
    for (var task in tasks) {
      results.add(await task());
      if (delay != null) {
        await Future.delayed(delay);
      }
    }
    return Future.value(results);
  }
}
