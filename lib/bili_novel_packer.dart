import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:bili_novel_packer/bili_novel/bili_novel_http.dart' as http;
import 'package:bili_novel_packer/bili_novel/bili_novel_model.dart';
import 'package:bili_novel_packer/bili_novel/bili_novel_util.dart' as util;
import 'package:bili_novel_packer/epub_packer/epub_packer.dart';
import 'package:bili_novel_packer/http_retry.dart';
import 'package:bili_novel_packer/packer_callback.dart';
import 'package:html/dom.dart';

class BiliNovelVolumePacker {
  /// 打包文件路径
  final String dest;
  final Volume volume;
  final Catalog catalog;
  final EpubPacker packer;
  final PackerCallback? callback;

  int imageCount = 0;
  int chapterCount = 0;

  // Map<图片src,图片信息>
  Map<String, util.ImageInfo?> imageInfoMap = {};

  // Map<图片src,图片EPUB路径>
  Map<String, String> imageHrefMap = {};

  BiliNovelVolumePacker({
    required this.catalog,
    required this.volume,
    required this.dest,
    this.callback,
  }) : packer = EpubPacker(dest);

  /// 打包EPUB
  Future<void> pack() async {
    callback?.onBeforePack.call(volume, dest);
    try {
      await _pack();
      callback?.onCompletePack.call(volume, dest);
    } catch (e) {
      callback?.onError(e);
    }
  }

  Future<void> _pack() async {}

  /// 下载章节内容并处理图片
  Future<Document?> _resolveChapter(Chapter chapter) async {
    callback?.onBeforeResolveChapter(chapter);
    chapter.url = await _getChapterUrl(catalog, chapter);
    if (chapter.url == null || chapter.url!.isEmpty) {
      callback?.onChapterUrlEmpty(chapter);
      return null;
    }
    Document chapterDocument = await http.getChapter(chapter.url!);
    await _resolveChapterImage(chapterDocument);
    callback?.onAfterBeforeResolveChapter(chapter);
    return chapterDocument;
  }

  /// 处理章节中的图片 保存到EPUB中
  Future<void> _resolveChapterImage(Document document) async {
    List<Future> imageResolveFutures = [];
    List<Element> imageList = document.querySelectorAll("img");
    for (Element img in imageList) {
      imageResolveFutures.add(_resolveSingleImage(img));
    }
    await Future.wait(imageResolveFutures);
  }

  Future<void> _resolveSingleImage(Element img) async {
    String? src = img.attributes["src"];
    if (src == null || src.isEmpty) return;
    if (src.startsWith("//")) {
      src = "https:$src";
    }
    callback?.onBeforeResolveImage(src);

    String? relativeImgPath;
    relativeImgPath = imageHrefMap[src];

    if (relativeImgPath == null) {
      Uint8List imgData = (await retryGet(src)).bodyBytes;

      relativeImgPath = _getRelativeImagePath();
      String absoluteImagePath = "OEBPS/$relativeImgPath";

      imageHrefMap[src] = relativeImgPath;
      imageInfoMap[src] = util.getImageInfo(InputStream(imgData));

      packer.addImage(name: absoluteImagePath, data: imgData);
    }
    img.attributes["src"] = relativeImgPath;
  }

  String _getRelativeImagePath() {
    return "images/${(++imageCount).toString().padLeft(4, "0")}.jpg";
  }

  String _getRelativeChapterPath() {
    return "chapter${(++chapterCount).toString().padLeft(4, "0")}.xhtml";
  }
}

Future<String?> _getChapterUrl(Catalog catalog, Chapter chapter) async {
  if (chapter.url != null && chapter.url!.isNotEmpty) return chapter.url;
  return util.getChapterUrl(catalog, chapter);
}
