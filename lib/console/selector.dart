import 'dart:math';

import 'package:bili_novel_packer/console/console.dart';

typedef SelectorAdapter<T, S> =
    List<T> Function(String input, Selector<T, S> selector);

class Selector<T, S> {
  final String message;
  final List<T> options;
  final S? suffix;
  final T? defaultValue;
  late final SelectorAdapter<T, S> adapter;

  static SelectorAdapter<T, S> _defaultAdapter<T, S>() {
    return (input, selector) {
      var options = selector.options;
      input = input.trim();
      if (input == "0") {
        return options;
      }
      input = input.replaceAll("，", ",");
      input = input.replaceAll(" ", ",");
      List<String> parts = input.split(",");
      List<T> selectedItems = [];
      for (var part in parts) {
        List<String> range = part.split("-");
        if (range.length == 1) {
          int index = int.parse(range[0]) - 1;
          selectedItems.add(options[index]);
        } else {
          int from = int.parse(range[0]);
          int to = int.parse(range[1]);
          if (from > to) {
            int tmp = from;
            from = to;
            to = tmp;
          }
          for (int i = from; i <= to; i++) {
            int index = i - 1;
            selectedItems.add(options[index]);
          }
        }
      }
      return selectedItems;
    };
  }

  Selector({
    required this.options,
    this.suffix,
    required this.message,
    this.defaultValue,
    SelectorAdapter<T, S>? adapter,
  }) {
    this.adapter = adapter ?? _defaultAdapter();
  }

  T selectOne() {
    do {
      _print();
      String? input = console.readLine();
      if (input == null || input.trim() == "") {
        continue;
      }
      List<T> results = adapter(input, this);
      if (results.isEmpty || results.length != 1) {
        if (defaultValue != null) {
          return defaultValue!;
        }
        continue;
      }
      return results.first;
    } while (true);
  }

  List<T> selectMany() {
    do {
      _print();
      String? input = console.readLine();
      if (input == null || input.trim() == "") {
        continue;
      }
      List<T> results = adapter(input, this);
      if (results.isEmpty) {
        continue;
      }
      return results;
    } while (true);
  }

  void _print() {
    int len = options.length.toString().length;
    int maxLine = 0;
    for (var i = 1; i <= options.length; i++) {
      String index = i.toString().padLeft(len);
      String line = "[$index] ${options[i - 1].toString()}";
      maxLine = max(maxLine, line.length);
      console.writeLine(line);
    }
    if (suffix != null) {
      console.writeLine("".padLeft(maxLine, "-"));
      String index = "0".padLeft(len);
      console.writeLine("[$index] ${suffix.toString()}");
    }
    console.write(message);
  }
}
