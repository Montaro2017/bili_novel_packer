import 'dart:async';

import 'package:console/console.dart';

typedef LoadingBarUpdateCallback = void Function();

class MyLoadingBar {
  Timer? _timer;
  String position = '<';
  late String lastPosition;
  late NextPositionLoadingBar nextPosition;
  LoadingBarUpdateCallback? callback;

  /// Creates a loading bar.
  MyLoadingBar({this.callback}) {
    nextPosition = _nextPosition;
  }

  /// Starts the Loading Bar
  void start() {
    Console.hideCursor();
    _timer = Timer.periodic(const Duration(milliseconds: 75), (timer) {
      nextPosition();
      update();
    });
  }

  /// Stops the Loading Bar with the specified (and optional) [message].
  void stop([String? message]) {
    if (_timer != null) {
      _timer!.cancel();
    }

    if (message != null) {
      position = message;
      update();
    }
    Console.showCursor();
    print('');
  }

  /// Updates the Loading Bar
  void update() {
    Console.overwriteLine(position);
    callback?.call();
  }

  void _nextPosition() {
    lastPosition = position;
    switch (position) {
      case '|':
        position = '/';
        break;
      case '/':
        position = '-';
        break;
      case '-':
        position = '\\';
        break;
      case '\\':
        position = '|';
        break;
      default:
        position = '|';
        break;
    }
  }
}
