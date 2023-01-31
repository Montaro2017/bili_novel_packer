import 'dart:convert';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;

import 'package:bili_novel_packer/epub_packer/epub_opf.dart';
import 'package:bili_novel_packer/epub_packer/epub_constant.dart';
import 'package:bili_novel_packer/epub_packer/epub_navigator.dart';

import 'package:bili_novel_packer/media_type.dart' as epub_media_type;

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

  String? get cover => _opf.cover;

  set cover(String? id) => _opf.cover = id;

  /// [epubFilePath] EPUB文件路径，实例化后文件就会被创建
  /// [bookUuid] 将被初始化
  EpubPacker(this.epubFilePath) {
    _zip.create(epubFilePath);
    _zip.addArchiveFile(mimetype);
    _zip.addArchiveFile(container);
    bookUuid = Uuid().v1();
  }

  /// 向EPUB中添加文件
  /// [archiveFile] 要添加的文件
  /// 注意：如果文件内容包含中文 需要使用Utf8Encoder()对内容进行编码
  /// 否则会出现乱码问题
  void addArchiveFile(ArchiveFile archiveFile) {
    _zip.addArchiveFile(archiveFile);
  }

  /// 添加章节文件
  /// [id] 可选
  /// [mediaType] 可选，默认使用[EpubMediaType.xhtml]
  /// [name] 章节文件在EPUB中的全路径 例如: "OEBPS/chapter001.xhtml"
  /// [title] 章节标题
  /// [chapterContent] 章节的文件内容
  void addChapter({
    String? id,
    String mediaType = epub_media_type.xhtml,
    required String name,
    required String title,
    required String chapterContent,
  }) {
    // 相对于toc和opf文件的路径
    String href = path.relative(name, from: "OEBPS");
    id ??= href;
    Uint8List utf8Uint8List = _converter.convert(chapterContent);
    _zip.addArchiveFile(
      ArchiveFile(name, utf8Uint8List.length, utf8Uint8List),
    );
    _opf.addChapter(
      ManifestItem(id, href, mediaType),
    );
    _navigator.addNavMapItem(title, href);
  }

  /// 添加图片资源
  /// [id] 可选
  /// [mediaType] 可选 默认 image/jpeg
  /// [name] 图片文件在EPUB中的全路径 例如: OEBPS/images/0001.jpg
  /// [data] 图片数据
  void addImage({
    String? id,
    String mediaType = epub_media_type.jpeg,
    required String name,
    required Uint8List data,
  }) {
    String href = path.relative(name, from: "OEBPS");
    id ??= href;
    _zip.addArchiveFile(
      ArchiveFile(name, data.length, data),
    );
    _opf.addImage(ManifestItem(id, href, mediaType));
  }

  /// 在打包前需要添加content.opf和toc.ncx文件
  void _beforePack() {
    Uint8List ncxUint8List = _converter.convert(
      _navigator.build().toXmlString(pretty: true),
    );
    addArchiveFile(
      ArchiveFile(
        "OEBPS/toc.ncx",
        ncxUint8List.length,
        ncxUint8List,
      ),
    );
    Uint8List opfUint8List = _converter.convert(
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

  /// 执行打包操作
  void pack() {
    _beforePack();
    _zip.close();
  }
}
