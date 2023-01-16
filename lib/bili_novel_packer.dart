import 'dart:io';

import 'package:archive/archive.dart';
import 'package:bili_novel_packer/bili_novel/bili_novel_model.dart';
import 'package:bili_novel_packer/bili_novel/bili_novel_http.dart' as bili;
import 'package:bili_novel_packer/epub_packer/epub_packer.dart';
import 'package:bili_novel_packer/extension/node_format_extension.dart';
import 'package:html/dom.dart';
import 'package:http/http.dart';

import 'bili_novel/bili_novel_util.dart';

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

  Future<String> pack(
    Volume volume,
    String dest, {
    Function(Chapter chapter, bool result)? callback,
  }) async {
    EpubPacker packer = EpubPacker(dest);
    _Index imageIndex = _Index();
    packer.docTitle = "${novel.title} ${volume.name}";
    packer.creator = novel.author;
    int chapterId = 0;
    for (var chapter in volume.chapters) {
      chapterId++;
      Document? chapterDoc = await getChapter(chapter);
      if (chapterDoc != null) {
        await _resolveImage(chapterDoc, packer, imageIndex);
        String chapterName =
            "OEBPS/${chapterId.toString().padLeft(4, "0")}.xhtml";
        packer.addChapter(
          name: chapterName,
          title: chapter.name,
          chapterContent: chapterDoc.format(),
        );
      }
      bool result = chapterDoc != null;
      callback?.call(chapter, result);
    }
    packer.pack();
    return File(dest).absolute.path;
  }

  _resolveImage(
    Document doc,
    EpubPacker packer,
    _Index index,
  ) async {
    var imgList = doc.querySelectorAll("img");
    for (var img in imgList) {
      index.increment();
      String src = img.attributes["src"]!;
      if (src.startsWith("//")) {
        src = "https:$src";
      }
      // TODO: fix get方法不稳定
      var data = (await get(Uri.parse(src))).bodyBytes;
      var imageInfo = getImageInfo(InputStream(data));
      String name = "images/${index.val.toString().padLeft(4, "0")}.jpg";
      String pathInEpub = "OEBPS/$name";
      packer.addImage(
        id: name,
        name: pathInEpub,
        data: data,
        mediaType: imageInfo.mimeType,
      );
      img.replaceWith(Element.tag("img")..attributes["src"] = name);
      // 设置封面
      if (imageInfo.ratio < 1 && packer.cover == null) {
        packer.cover = name;
      }
    }
    return;
  }
}

class _Index {
  int _index;

  _Index([this._index = 0]);

  int increment() {
    return ++_index;
  }

  int get val => _index;
}
