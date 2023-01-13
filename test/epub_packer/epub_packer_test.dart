import 'package:archive/archive_io.dart';
import 'package:bili_novel_packer/epub_packer/epub_packer.dart';
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

    test("Epub Packer", () {
      EpubPacker packer = EpubPacker(r"D:\test.epub");
      packer.docTitle = "测试EPUB";
      packer.creator = "CXK";
      packer.bookUuid = "abc123-def456-ghd8909";
      packer.pack();
    });
  });
}
