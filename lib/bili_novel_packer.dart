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
  final Novel novel;
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

  List<String?> imageSrcList = [];

  BiliNovelVolumePacker({
    required this.novel,
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
      callback?.onAfterPack.call(volume, dest);
    } catch (e, stack) {
      callback?.onError(e, stackTrace: stack);
    }
  }

  Future<void> _pack() async {
    List<Future<_ChapterInfo>> chapterFutures = [];
    for (var chapter in volume.chapters) {
      chapterFutures.add(_resolveChapter(chapter));
    }
    List<_ChapterInfo> chapterInfoList = await Future.wait(chapterFutures);
    for (_ChapterInfo chapterInfo in chapterInfoList) {
      String chapterPath = _getAbsoluteChapterPath();
      if (chapterInfo.document == null) continue;
      packer.addChapter(
        name: chapterPath,
        title: chapterInfo.chapter.name,
        chapterContent: chapterInfo.document!.outerHtml,
      );
      _resolveCover(chapterInfo.imageSrcList);
    }
    packer.docTitle = "${novel.title} ${volume.name}";
    packer.creator = novel.author;
    packer.pack();
  }

  /// 下载章节内容并处理图片
  Future<_ChapterInfo> _resolveChapter(Chapter chapter) async {
    callback?.onBeforeResolveChapter(chapter);
    chapter.url = await _getChapterUrl(catalog, chapter);
    if (chapter.url == null || chapter.url!.isEmpty) {
      callback?.onChapterUrlEmpty(chapter);
      return _ChapterInfo(chapter, null, []);
    }
    Document chapterDocument = await http.getChapter(chapter.url!);
    List<String?> imageSrcList = await _resolveChapterImage(chapterDocument);
    callback?.onAfterResolveChapter(chapter);
    return _ChapterInfo(chapter, chapterDocument, imageSrcList);
  }

  /// 处理章节中的图片 保存到EPUB中
  Future<List<String?>> _resolveChapterImage(Document document) async {
    List<Future> imageResolveFutures = [];
    List<Element> imageList = document.querySelectorAll("img");
    List<String?> imageSrcList =
        imageList.map((e) => e.attributes["src"]).toList();
    for (Element img in imageList) {
      imageResolveFutures.add(_resolveSingleImage(img));
    }
    await Future.wait(imageResolveFutures).catchError((error, stackTrace) {
      callback?.onError(error, stackTrace: stackTrace);
    });
    return imageSrcList;
  }

  Future<void> _resolveSingleImage(Element img) async {
    String? src = img.attributes["src"];
    if (src == null || src.isEmpty) return;
    if (src.startsWith("//")) {
      src = "https:$src";
    }
    callback?.onBeforeResolveImage(src);

    String? relativeImgPath = imageHrefMap[src];

    if (relativeImgPath == null || relativeImgPath.isEmpty) {
      Uint8List imgData = (await retryGet(src)).bodyBytes;
      util.ImageInfo? imageInfo = util.getImageInfo(InputStream(imgData));

      relativeImgPath = _getRelativeImagePath();
      String absoluteImagePath = "OEBPS/$relativeImgPath";

      imageHrefMap[src] = relativeImgPath;
      imageInfoMap[src] = imageInfo;

      packer.addImage(name: absoluteImagePath, data: imgData);
    }
    img.attributes["src"] = relativeImgPath;
    callback?.onAfterResolveImage(src, relativeImgPath);
  }

  String _getRelativeImagePath() {
    return "images/${(++imageCount).toString().padLeft(4, "0")}.jpg";
  }

  String _getAbsoluteChapterPath() {
    return "OEBPS/chapter${(++chapterCount).toString().padLeft(4, "0")}.xhtml";
  }

  void _resolveCover(List<String?> imageSrcList) {
    if (packer.cover != null && packer.cover!.isNotEmpty) return;
    for (var src in imageSrcList) {
      if (src == null || src.isEmpty) continue;
      util.ImageInfo? imageInfo = imageInfoMap[src];
      if (imageInfo == null) continue;
      if (imageInfo.ratio < 1) {
        packer.cover = imageHrefMap[src];
        callback?.onSetCover(src, packer.cover!);
        return;
      }
    }
  }
}

Future<String?> _getChapterUrl(Catalog catalog, Chapter chapter) async {
  if (chapter.url != null && chapter.url!.isNotEmpty) return chapter.url;
  return util.getChapterUrl(catalog, chapter);
}

class _ChapterInfo {
  final Chapter chapter;
  final Document? document;
  final List<String?> imageSrcList;

  _ChapterInfo(
    this.chapter,
    this.document,
    this.imageSrcList,
  );
}
