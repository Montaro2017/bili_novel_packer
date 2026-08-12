import 'dart:io';

class Console {
  const Console();

  void write(String msg) {
    stdout.write(msg);
  }

  void writeLine([Object? msg = ""]) {
    stdout.writeln(msg);
  }

  String? readLine() {
    return stdin.readLineSync();
  }
}

const console = Console();
