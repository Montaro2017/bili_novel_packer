import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:bili_novel_packer/bili_novel/bili_novel_util.dart';
import 'package:bili_novel_packer/epub_packer/epub_packer.dart';
import 'package:bili_novel_packer/http_retry.dart';
import 'package:bili_novel_packer/media_type.dart';
import 'package:html/dom.dart';

import 'bili_novel/bili_novel_http.dart' as bili_http;
import 'bili_novel/bili_novel_model.dart';

class BiliNovelPacker {
  final int id;

  BiliNovelPacker(this.id);

  Future<Novel> getNovel() async {
    return bili_http.getNovel(id);
  }

  Future<Catalog> getCatalog() async {
    return bili_http.getCatalog(id);
  }

  Future<void> packVolume(Volume volume, Catalog catalog, String dest) async {
    List<Future<_ChapterInfo?>> futures = [];
    EpubPacker epubPacker = EpubPacker(dest);
    _ImageHandler imageHandler = _ImageHandler(epubPacker);
    _ChapterHandler chapterHandler = _ChapterHandler(epubPacker, imageHandler);
    for (var chapter in volume.chapters) {
      futures.add(chapterHandler.resolveChapter(catalog, chapter));
    }
    List<_ChapterInfo?> chapterDocumentList = await Future.wait(futures);
    // epubPacker.pack();
  }
}

class _ChapterHandler {
  final EpubPacker packer;
  final _ImageHandler imageHandler;

  int chapterCount = 0;

  _ChapterHandler(this.packer, this.imageHandler);

  Future<_ChapterInfo?> resolveChapter(Catalog catalog, Chapter chapter) async {
    Document? chapterDocument = await _resolveChapter(
      packer,
      imageHandler,
      catalog,
      chapter,
    );
    if (chapterDocument == null) return null;
    // return _ChapterInfo(title, content)
  }

  Future<Document?> _resolveChapter(
    EpubPacker epubPacker,
    _ImageHandler imageHandler,
    Catalog catalog,
    Chapter chapter,
  ) async {
    chapter.url = await bili_http.getChapterUrl(catalog, chapter);
    if (chapter.url == null || chapter.url!.isEmpty) return null;
    Document document = await bili_http.getChapter(chapter.url!);
    await _resolveChapterImage(document, imageHandler);
    return document;
  }

  Future<void> _resolveChapterImage(
    Document document,
    _ImageHandler imageHandler,
  ) async {
    List<Element> imgList = document.querySelectorAll("img");
    List<Future> futures = [];
    for (var img in imgList) {
      futures.add(
        Future(() async {
          String? src = img.attributes["src"];
          if (src == null || src.isEmpty) return;
          if (src.startsWith("//")) {
            src = "https:$src";
          }
          String replaceSrc = await imageHandler.resolveImage(src);
          img.attributes["src"] = replaceSrc;
        }),
      );
    }
    await Future.wait(futures);
  }
}

class _ChapterInfo {
  String title;
  String content;
  String name;

  _ChapterInfo(this.title, this.name, this.content);
}

class _ImageHandler {
  final EpubPacker packer;

  String? cover;
  int imageCount = 0;
  Map<String, Uint8List> imageCache = {};
  Map<String, ImageInfo?> imageInfoMap = {};

  _ImageHandler(this.packer);

  Future<String> resolveImage(String src) async {
    Uint8List imgData = await _getImageData(src);
    ImageInfo? imageInfo = _getImageInfo(src, imgData);

    imageCache[src] = imgData;
    imageInfoMap[src] = imageInfo;

    String relativeName = "images/${imageCount.toString().padLeft(4, "0")}.jpg";
    String absoluteName = "OEBPS/$relativeName";

    packer.addImage(
      name: absoluteName,
      data: imgData,
      mediaType: imageInfo?.mimeType ?? jpeg,
    );

    // 根据图片比例猜测封面
    if (imageInfo != null && imageInfo.ratio < 1 && cover == null) {
      cover = relativeName;
    }
    imageCount++;
    return relativeName;
  }

  Future<Uint8List> _getImageData(String src) async {
    return imageCache[src] ?? (await retryGet(src)).bodyBytes;
  }

  ImageInfo? _getImageInfo(String src, Uint8List imgData) {
    return imageInfoMap[src] ?? getImageInfo(InputStream(imgData));
  }
}
