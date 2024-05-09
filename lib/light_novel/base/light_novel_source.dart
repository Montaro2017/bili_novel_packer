import 'dart:typed_data';

import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart';
import 'package:html/dom.dart';

typedef FutureFunction<T> = Future<T> Function();

abstract class LightNovelSource {

  static const String html = "<html lang='zh-CN'><body></body></html>";

  String get name;

  String get sourceUrl;

  bool supportUrl(String url);

  FutureFunction<Novel> getNovel(String url);

  FutureFunction<Catalog> getNovelCatalog(Novel novel);

  FutureFunction<Document> getNovelChapter(Chapter chapter);

  FutureFunction<Uint8List> getImage(String src);
}
