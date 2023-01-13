import 'package:archive/archive_io.dart';

import 'epub_constant.dart';
import 'epub_navigator.dart';
import 'epub_opf.dart';


class EpubPacker {
  final String epubFilePath;
  final ZipFileEncoder _zip = ZipFileEncoder();
  // toc.ncx
  final EpubNavigator _navigator = EpubNavigator();
  // content.opf
  final EpubOpenPackageFormat _opf = EpubOpenPackageFormat();

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
