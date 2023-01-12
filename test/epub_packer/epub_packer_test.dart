import 'package:archive/archive_io.dart';
import 'package:test/scaffolding.dart';

void main() {
  group("EpubPacker Test", () {
    test("test zip", () {
      var zip = ZipFileEncoder();
      zip.create(r"D:\test.epub");
      zip.addArchiveFile(ArchiveFile.string(
        "container",
        "application/epub+zip",
      ));
      zip.close();
    });
  });
}
