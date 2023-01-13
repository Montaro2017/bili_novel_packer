import 'dart:convert';
import 'package:archive/archive_io.dart';

import 'epub_constant.dart';
import 'epub_navigator.dart';
import 'epub_opf.dart';

class EpubPacker {
  final String epubFilePath;
  final ZipFileEncoder _zip = ZipFileEncoder();
  final Utf8Encoder _converter = Utf8Encoder();

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
    _zip.create(epubFilePath);
    _zip.addArchiveFile(mimetype);
    _zip.addArchiveFile(container);
  }

  void addArchiveFile(ArchiveFile archiveFile) {
    _zip.addArchiveFile(archiveFile);
  }

  void _beforePack() {
    var ncxUint8List = _converter.convert(
      _navigator.build().toXmlString(pretty: true),
    );
    addArchiveFile(
      ArchiveFile(
        "OEBPS/toc.ncx",
        ncxUint8List.length,
        ncxUint8List,
      ),
    );
    var opfUint8List = _converter.convert(
      _opf.build().toXmlString(pretty: true),
    );
    addArchiveFile(
      ArchiveFile(
        "OEBPS/content.opf",
        opfUint8List.length,
        opfUint8List,
      ),
    );
  }

  void pack() {
    _beforePack();
    _zip.close();
  }
}
