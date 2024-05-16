import 'package:bili_novel_packer/scheduler/executor_service.dart';

typedef FutureFunction<T> = Future<T> Function();

abstract class Scheduler {
  Future<List<T>> execute<T>(List<ExecutorTask<T>> tasks, {Object? key});

  Future<T> executeOne<T>(ExecutorTask<T> one, {Object? key}) async {
    return await execute([one], key: key).then((value) => value.first);
  }
}