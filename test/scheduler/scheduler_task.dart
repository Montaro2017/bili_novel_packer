import 'dart:math';

import 'package:bili_novel_packer/light_novel/base/light_novel_source.dart';
import 'package:bili_novel_packer/scheduler/scheduler.dart';
import 'package:test/scaffolding.dart';

void main() {
  test("Scheduler.parallel", () async {
    List<FutureFunction<int>> tasks = [];
    int size = 100;
    int batchSize = 10;
    for (int i = 0; i < size; i++) {
      tasks.add(task());
    }
    DateTime start = DateTime.now();
    List<int> results = await Scheduler.parallel(tasks, batchSize: batchSize);
    DateTime end = DateTime.now();
    int i = 0;
    int maxNum = 0;
    int total = 0;
    for (int result in results) {
      maxNum = max(result, maxNum);
      if (++i % batchSize == 0) {
        total = total + maxNum;
        maxNum = 0;
      }
    }
    print("total: $total");
    print("actual total: ${end.difference(start).inMilliseconds}");
    print(results);
  });

  test("Scheduler.sequential", () async {
    List<FutureFunction<int>> tasks = [];
    int size = 10;
    for (int i = 0; i < size; i++) {
      tasks.add(task());
    }
    await Future.delayed(Duration(milliseconds: 1000));
    DateTime start = DateTime.now();
    List<int> results = await Scheduler.sequential(tasks);
    DateTime end = DateTime.now();
    int total = results.reduce((value, element) => value + element);
    print("total: $total");
    print("actual total: ${end.difference(start).inMilliseconds}");
    print(results);
  });
}

FutureFunction<int> task() {
  return () async {
    var random = Random();
    var ms = random.nextInt(1000);
    await Future.delayed(Duration(milliseconds: ms));
    print(ms);
    return Future.value(ms);
  };
}
