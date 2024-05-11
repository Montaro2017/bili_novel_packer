import 'dart:typed_data';

import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart';
import 'package:bili_novel_packer/scheduler/scheduler.dart';
import 'package:html/dom.dart';

abstract class LightNovelSource {

  static const String html = "<html lang='zh-CN'><body></body></html>";

  String get name;

  String get sourceUrl;

  Scheduler getScheduler();

  bool supportUrl(String url);

  Future<Novel> getNovel(String url);

  Future<Catalog> getNovelCatalog(Novel novel);

  FutureFunction<Document> getNovelChapter(Chapter chapter);

  FutureFunction<Uint8List> getImage(String src);
}

enum SchedulerKey {
  document,
  image,
}
