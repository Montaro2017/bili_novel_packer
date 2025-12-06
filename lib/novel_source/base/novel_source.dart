import 'package:bili_novel_packer/novel_source/base/light_novel_model.dart';
import 'package:html/dom.dart';

abstract class NovelSource {
  String get name;

  Future<NovelSection> explore();

  Future<List<Novel>> search(String keyword, [int page = 1]);

  Future<Novel> loadNovel(String id);

  Future<Catalog> loadCatalog(Novel novel);

  Future<Document> loadChapter(Catalog catalog, Chapter chapter);

  Future<List<int>> loadImage(String src);
}
