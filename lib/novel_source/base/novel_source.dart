import 'package:bili_novel_packer/novel_source/base/novel_model.dart';
import 'package:html/dom.dart';

abstract class NovelSource {
  String get name;

  Future<List<NovelSection>> explore();

  FutureIterator<List<Novel>> search(String keyword);

  Future<Novel> loadNovel(String id);

  Future<Catalog> loadCatalog(Novel novel);

  Future<Document> loadChapter(Catalog catalog, Chapter chapter);

  Future<List<int>> loadImage(String src);
}

abstract class FutureIterator<E> {
  Future<E> get current;

  Future<bool> moveNext();
}