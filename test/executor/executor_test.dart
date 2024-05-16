import 'dart:math';

import 'package:bili_novel_packer/scheduler/executor_service.dart';
import 'package:bili_novel_packer/scheduler/scheduler.dart';
import 'package:test/test.dart';

void main() {
  test("ParallelExecutorService", () async {
    ExecutorService service = ParallelExecutorService(5);
    List<ExecutorTask<int>> tasks =
        List.generate(20, (index) => task1()).toList();
    service.invokeAll(tasks).then(
      (List<int> results) {
        print(results);
      },
    );
    await Future.delayed(Duration(seconds: 10));
  }, timeout: Timeout.none);

  test("SequentialExecutorService", () async {
    ExecutorService service = SequentialExecutorService();
    List<ExecutorTask<int>> tasks =
        List.generate(20, (index) => task2()).toList();
    List<int> results = await service.invokeAll(tasks);
    print(results);
  }, timeout: Timeout.none);

  test("Scheduler", () async {
    Scheduler scheduler = _MyScheduler();
    List<ExecutorTask<int>> tasks =
        List.generate(20, (index) => task2()).toList();
    scheduler.executeOne(task2()).then((values) {
      print(values);
    });
    await Future.delayed(Duration(seconds: 2));
  });
}

class _MyScheduler extends Scheduler {
  ExecutorService parallelService = ParallelExecutorService(5);

  @override
  Future<List<T>> execute<T>(List<ExecutorTask<T>> tasks, {Object? key}) {
    return parallelService.invokeAll(tasks);
  }
}

ExecutorTask<int> task1() {
  return (service) async {
    var random = Random();
    var ms = random.nextInt(1000);
    print(ms);
    await Future.delayed(Duration(milliseconds: ms));
    return Future.value(ms);
  };
}

ExecutorTask<int> task2() {
  return (service) async {
    var random = Random();
    var ms = random.nextInt(1000);
    await Future.delayed(Duration(milliseconds: ms));
    print(ms);
    return Future.value(ms);
  };
}
