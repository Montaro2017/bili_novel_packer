import 'dart:async';
import 'dart:collection';

typedef SchedulerTask<R> = FutureOr<R?> Function(SchedulerController c);

class Scheduler {
  final Queue<SchedulerTask> _queue = Queue();
  final Map<int, _Result<dynamic>> _resultMap = {};
  final SchedulerController _controller = SchedulerController();

  late final Duration _gap;

  bool _looping = false;
  Completer _completer = Completer<void>()..complete();

  Scheduler(int n, Duration per) {
    if (n > 0) {
      Duration gap = Duration(milliseconds: (per.inMilliseconds / n).ceil());
      _gap = gap < Duration.zero ? Duration.zero : gap;
    } else {
      _gap = Duration.zero;
    }
  }

  Future<R> run<R>(SchedulerTask<R> task) async {
    _queue.add(task);
    _resultMap[task.hashCode] = _Result(_TaskStatus.pending);
    _loop();
    return _getResult(task.hashCode);
  }

  Future<R> _getResult<R>(int taskHashCode) async {
    _Result<dynamic>? result = _resultMap[taskHashCode];
    if (result == null) {
      return Future.error("Task already completed or not found");
    }
    while (true) {
      if (result.status == _TaskStatus.completed) {
        return result.value;
      }
      if (result.status == _TaskStatus.failed && result.error != null) {
        return Future.error(result.error!);
      }
      await Future.delayed(Duration(milliseconds: 1));
    }
  }

  void _loop() async {
    await _completer.future;
    _completer = Completer();
    if (_looping) {
      return;
    }
    _looping = true;
    while (_queue.isNotEmpty) {
      await Future.delayed(Duration(milliseconds: 1));
      if (_controller._pause) {
        continue;
      }
      SchedulerTask<dynamic> task = _queue.removeFirst();
      _Result<dynamic> result = _resultMap[task.hashCode]!;
      result.status = _TaskStatus.inProgress;
      FutureOr<dynamic> futureOr = task.call(_controller);
      if (futureOr is Future) {
        futureOr.then((onValue) {
          result.value = onValue;
          result.status = _TaskStatus.completed;
        }).catchError((e) {
          result.error = e;
          result.status = _TaskStatus.failed;
        });
      } else {
        result.value = await futureOr;
        result.status = _TaskStatus.completed;
      }
      await Future.delayed(_gap);
    }
    _completer.complete();
    _looping = false;
  }

  Future<void> wait() async {
    while (_queue.isNotEmpty) {
      await Future.delayed(Duration(milliseconds: 1));
    }
    List<Future<void>> futures = [];
    for (var r in _resultMap.values) {
      futures.add(Future(() async {
        while (r.status == _TaskStatus.pending ||
            r.status == _TaskStatus.inProgress) {
          await Future.delayed(Duration(milliseconds: 1));
        }
      }));
    }
    await Future.wait(futures);
  }
}

enum _TaskStatus { pending, inProgress, completed, failed }

class _Result<R> {
  _TaskStatus status;
  R? value;
  Object? error;

  _Result(this.status);
}

class SchedulerController {
  bool _pause = false;

  void pause() {
    _pause = true;
  }

  void resume() {
    _pause = false;
  }
}
