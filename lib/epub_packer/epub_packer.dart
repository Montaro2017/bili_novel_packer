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

  String get docTitle => _navigator.docTitle;

  set docTitle(docTitle) {
    _navigator.docTitle = docTitle;
    _opf.docTitle = docTitle;
  }

  String get bookUuid => _navigator.bookUuid;

  set bookUuid(String bookUuid) {
    _navigator.bookUuid = bookUuid;
    _opf.bookUuid = bookUuid;
  }

  String get creator => _opf.creator;

  set creator(creator) => _opf.creator = creator;

  EpubPacker(this.epubFilePath) {
    _zip.create(epubFilePath, level: Deflate.NO_COMPRESSION);
    _zip.addArchiveFile(mimetype);
    _zip.addArchiveFile(container);
  }

  void addArchiveFile(ArchiveFile archiveFile) {
    _zip.addArchiveFile(archiveFile);
  }

  void _beforePack() {
    String ncx = _navigator.build().toXmlString(pretty: true);
    var ncxFile = ArchiveFile.string(
      "OEBPS/toc.ncx",
      ncx,
    );
    addArchiveFile(ncxFile);
    String opf = _opf.build().toXmlString(pretty: true);
    addArchiveFile(
      ArchiveFile.string(
        "OEBPS/content.opf",
        opf,
      ),
    );
  }

  void pack() {
    _beforePack();
    _zip.close();
  }
}
