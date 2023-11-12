import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:bili_novel_packer/epub_packer/epub_constant.dart';
import 'package:bili_novel_packer/epub_packer/epub_navigator.dart';
import 'package:bili_novel_packer/epub_packer/epub_opf.dart';
import 'package:bili_novel_packer/media_type.dart' as epub_media_type;
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class EpubPacker {
  final String epubFilePath;

  static const Utf8Encoder _utf8Encoder = Utf8Encoder();

  // toc.ncx
  final EpubNavigator _navigator = EpubNavigator();

  // content.opf
  final EpubOpenPackageFormat _opf = EpubOpenPackageFormat();

  final List<ArchiveFile> archiveFiles = [];

  String get absolutePath {
    return File(epubFilePath).absolute.path;
  }

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

  String? get source => _opf.metaData.source;

  set source(String? source) => _opf.metaData.source = source;

  String? get publisher => _opf.metaData.publisher;

  set publisher(String? publisher) => _opf.metaData.publisher = publisher;

  List<String> get subjects => _opf.metaData.subjects;

  set subjects(List<String> subjects) => _opf.metaData.subjects = subjects;

  String? get description => _opf.metaData.description;

  set description(String? description) => _opf.metaData.description = description;

  String? get cover => _opf.cover;

  set cover(String? id) => _opf.cover = id;

  EpubPacker(this.epubFilePath);

  /// 向EPUB中添加文件
  /// [archiveFile] 要添加的文件
  /// 注意：如果文件内容包含中文 需要使用Utf8Encoder()对内容进行编码
  /// 否则会出现乱码问题
  void addArchiveFile(ArchiveFile archiveFile) {
    if (!_existArchiveFile(archiveFile)) {
      archiveFiles.add(archiveFile);
    }
  }

  bool _existArchiveFile(ArchiveFile file) {
    for (var archiveFile in archiveFiles) {
      if (archiveFile.name == file.name) {
        return true;
      }
    }
    return false;
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
    bool addNavPoint = true,
    required String name,
    required String title,
    required String chapterContent,
  }) {
    // 相对于toc和opf文件的路径
    String href = path.relative(name, from: "OEBPS");
    id ??= href;
    Uint8List utf8Uint8List = _utf8Encoder.convert(chapterContent);
    addArchiveFile(
      ArchiveFile(name, utf8Uint8List.length, utf8Uint8List),
    );
    _opf.addChapter(
      ManifestItem(id, href, mediaType),
    );
    if (addNavPoint) {
      NavPoint navPoint = NavPoint(title, src: href);
      _navigator.addNavPoint(navPoint);
    }
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
    addArchiveFile(
      ArchiveFile(name, data.length, data),
    );
    _opf.addImage(ManifestItem(id, href, mediaType));
  }

  void addNavPoint(NavPoint navPoint) {
    _navigator.addNavPoint(navPoint);
  }

  /// 执行打包操作
  void pack() {
    bookUuid = Uuid().v1();
    Uint8List ncxUint8List = _utf8Encoder.convert(
      _navigator.build().toXmlString(pretty: true),
    );

    /// 在打包前需要添加content.opf和toc.ncx文件
    addArchiveFile(
      ArchiveFile(
        "OEBPS/toc.ncx",
        ncxUint8List.length,
        ncxUint8List,
      ),
    );
    Uint8List opfUint8List = _utf8Encoder.convert(
      _opf.build().toXmlString(pretty: true),
    );
    addArchiveFile(
      ArchiveFile(
        "OEBPS/content.opf",
        opfUint8List.length,
        opfUint8List,
      ),
    );
    addArchiveFile(container);
    addArchiveFile(mimetype);
    final ZipFileEncoder zip = ZipFileEncoder();
    zip.create(epubFilePath);
    for (var archiveFile in archiveFiles) {
      zip.addArchiveFile(archiveFile);
    }
    zip.close();
  }
}
