import 'package:archive/archive.dart';
import 'package:flutter/services.dart';

Future<ArchiveFile> get container async {
  return ArchiveFile.string(
    'assets/epub/META-INF/container.xml',
    await rootBundle.loadString('META-INF/container.xml'),
  );
}

Future<ArchiveFile> get mimetype async {
  return ArchiveFile.string(
    'assets/epub/mimetype',
    await rootBundle.loadString('mimetype'),
  )..compress = false;
}
