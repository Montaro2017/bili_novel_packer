import 'package:bili_novel_packer/bili_novel/bili_novel_model.dart';
import 'package:bili_novel_packer/bili_novel/bili_novel_http.dart' as bili;
import 'package:bili_novel_packer/epub_packer/epub_packer.dart';
import 'package:html/dom.dart';

class BiliNovelPacker {
  final int id;
  late Novel novel;
  late Catalog catalog;

  BiliNovelPacker(this.id);

  Future<Novel> getNovel() async {
    novel = await bili.getNovel(id);
    return novel;
  }

  Future<Catalog> getCatalog() async {
    catalog = await bili.getCatalog(id);
    return catalog;
  }

  Future<Document?> getChapter(Chapter chapter) async {
    if (chapter.url == null || chapter.url!.isEmpty) {
      chapter.url = await bili.getChapterUrl(catalog, chapter);
    }
    if (chapter.url == null) {
      return null;
    }
    return await bili.getChapter(chapter.url!);
  }

  String pack(Volume volume, [String? dest]) {
    dest ??= "${novel.title}/${novel.title} ${volume.name}.epub";
    EpubPacker packer = EpubPacker(dest);

    return dest;
  }
}
