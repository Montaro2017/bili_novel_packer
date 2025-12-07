import 'dart:typed_data';

import 'package:bili_novel_packer/novel_source/base/novel_model.dart';
import 'package:bili_novel_packer/novel_source/bili_novel/bili_novel_source.dart';
import 'package:bili_novel_packer/novel_source/wenku_novel/wenku_novel_source.dart';
import 'package:html/dom.dart';

abstract class LightNovelSource {
  static const String html = "<html xmlns='http://www.w3.org/1999/xhtml' lang='zh-CN'><body></body></html>";

  static final sources = [
    BiliNovelSource(),
    WenkuNovelSource(),
  ];

  String get name;

  String get sourceUrl;

  bool supportUrl(String url);

  Future<Novel> getNovel(String id);

  Future<Novel> getNovelByUrl(String url);

  Future<Catalog> getNovelCatalog(Novel novel);

  Future<Document> getNovelChapter(Chapter chapter);

  Future<Uint8List> getImage(String src);
}
