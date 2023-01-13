import 'package:archive/archive_io.dart';
import 'package:bili_novel_packer/epub_packer/epub_constant.dart';
import 'package:bili_novel_packer/epub_packer/epub_navigator.dart';

class EpubPacker {
  final String epubFilePath;
  final ZipFileEncoder _zip = ZipFileEncoder();
  // content.ncx
  final EpubNavigator _navigator = EpubNavigator();

  EpubPacker(this.epubFilePath) {
    _zip.create(epubFilePath);
    _zip.addArchiveFile(mimetype);
    _zip.addArchiveFile(container);
  }

  void addArchiveFile(ArchiveFile archiveFile) {
    _zip.addArchiveFile(archiveFile);
  }

  void pack() {
    _zip.close();
  }
}
