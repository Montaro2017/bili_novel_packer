import 'dart:async';

import 'package:bili_novel_packer/scheduler/scheduler.dart';
import 'package:test/test.dart';

void main() {
  test("SchedulerTest", () async {
    Scheduler scheduler = Scheduler(0, Duration.zero);
    scheduler.run((c) {
      print("AAA");
    });
    scheduler.run((c) async {
      print("BBB pause");
      c.pause();
      Future.delayed(Duration(seconds: 5)).then((_) {
        c.resume();
        print("BBB resume");
      });
    });

    scheduler.run((_) async {
      print("CCC");
      await Future.delayed(Duration(seconds: 3)).then((_) {
        print("CCC OK");
      });
    });
    await Future.delayed(Duration(seconds: 15));

    scheduler.run((_) {
      print("DDD");
    });
    await Future.delayed(Duration(seconds: 1));
  });

  test("RateScheduler", () async {
    Scheduler scheduler = Scheduler(0, Duration(seconds: 2));
    for (int i = 1; i <= 100; i++) {
      scheduler.run((_) async {
        await Future.delayed(Duration(milliseconds: 30));
        return i;
      }).then((v) {
        print("i = $v");
      });
    }
    await scheduler.wait();
  });
}
