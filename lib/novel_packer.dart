import 'dart:io';
import 'dart:typed_data';
import 'dart:async';

import 'package:bili_novel_packer/epub_packer/epub_packer.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_cover_detector.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_source.dart';
import 'package:bili_novel_packer/light_novel/bili_novel/bili_novel_source.dart';
import 'package:bili_novel_packer/light_novel/wenku_novel/wenku_novel_source.dart';
import 'package:bili_novel_packer/pack_argument.dart';
import 'package:bili_novel_packer/pack_callback.dart';
import 'package:bili_novel_packer/util/html_util.dart';
import 'package:bili_novel_packer/util/url_util.dart';
import 'package:html/dom.dart';

class NovelPacker {
  static final List<LightNovelSource> sources = [
    BiliLightNovelSource(),
    WenkuNovelSource()
  ];

  String url;
  LightNovelSource lightNovelSource;

  late Novel novel;
  late Catalog catalog;

  NovelPacker._(this.lightNovelSource, this.url);

  factory NovelPacker.fromUrl(String url) {
    for (var source in sources) {
      if (source.supportUrl(url)) {
        return NovelPacker._(source, url);
      }
    }
    throw "Unsupported url: $url";
  }

  Future<Novel> getNovel() async {
    return lightNovelSource.getNovel(url).then((novel) => this.novel = novel);
  }

  Future<Catalog> getCatalog() async {
    return lightNovelSource
        .getNovelCatalog(novel)
        .then((catalog) => this.catalog = catalog);
  }

  void pack(PackArgument arg, [PackCallback? callback]) async {
    if (arg.combineVolume) {
      // TODO
    } else {
      for (var volume in arg.packVolumes) {
        await _packVolume(volume, arg.addChapterTitle, callback);
      }
      exit(0);
    }
  }

  Future<void> _packVolume(
    Volume volume,
    bool addChapterTitle, [
    PackCallback? callback,
  ]) async {
    callback?.beforePackVolume(volume);
    EpubPacker packer = EpubPacker(_getEpubName(volume));
    packer.docTitle = "${volume.catalog.novel.title} ${volume.volumeName}";
    packer.creator = volume.catalog.novel.author;
    List<Future<MapEntry<Chapter, Document>>> chapterFutures = [];
    for (var chapter in volume.chapters) {
      chapterFutures.add(Future(() => lightNovelSource
          .getNovelChapter(chapter)
          .then((doc) => MapEntry(chapter, doc))));
    }
    List<MapEntry<Chapter, Document>> chapterDocuments =
        await Future.wait(chapterFutures);
    List<Element> imageElements = [];

    for (var chapterDocument in chapterDocuments) {
      var chapter = chapterDocument.key;
      var document = chapterDocument.value;
      HTMLUtil.wrapDuoKanImage(document.body!);
      var images = document.querySelectorAll("img");
      imageElements.addAll(images);
      if (addChapterTitle) {
        var firstChild = document.body!.firstChild;
        Node chapterTitle = Element.html(
          '<div style="margin-top:0.5em;font-size:1.25em;font-weight: 800;text-align:center;">${chapter.chapterName}</div>',
        );
        document.body!.insertBefore(chapterTitle, firstChild);
      }
    }
    // 下载所有图片
    List<MapEntry<String, Uint8List>?> images =
        await _resolveImages(imageElements);

    LightNovelCoverDetector detector = LightNovelCoverDetector();

    // 添加图片资源
    for (var image in images) {
      if (image == null) continue;

      try {
        detector.add(image.key, image.value);
        packer.addImage(name: image.key, data: image.value);
      } catch (e) {
        // 不支持的图片
      }
    }

    // 设置封面
    String? cover = detector.detectCover();
    if (cover != null) {
      packer.cover = cover.replaceFirst("OEBPS/", "");
    }

    // 添加章节资源
    for (int i = 0; i < chapterDocuments.length; i++) {
      var chapterDocument = chapterDocuments[i];
      var chapter = chapterDocument.key;
      var document = chapterDocument.value;
      packer.addChapter(
        name: "OEBPS/chapter${(i + 1).toString().padLeft(4, "0")}.xhtml",
        title: chapter.chapterName,
        chapterContent: document.outerHtml,
      );
    }

    // 写出目标文件
    packer.pack();
    callback?.afterPackVolume(volume);
  }

  /// 下载所有图片
  Future<List<MapEntry<String, Uint8List>?>> _resolveImages(
    List<Element> imageElements,
  ) async {
    List<Future<MapEntry<String, Uint8List>?>> imageFutures = [];
    for (var image in imageElements) {
      imageFutures.add(_resolveImage(image));
    }
    return await Future.wait(imageFutures);
  }

  /// 下载单张图片 并替换img标签中的src
  Future<MapEntry<String, Uint8List>?> _resolveImage(
    Element image,
  ) async {
    String? src = image.attributes["src"];
    if (src == null) return null;
    Uint8List data = Uint8List(0);
    try {
      ///  防止异常中断程序后续执行
      data = await lightNovelSource.getImage(src);
    } on TimeoutException {
      data = Uint8List(0);
    }
    String href = "images/${URLUtil.getFileName(src)}";
    image.attributes["src"] = href;
    return MapEntry("OEBPS/$href", data);
  }

  String _getEpubName(Volume volume) {
    String title = _sanitizeFileName(volume.catalog.novel.title).trim();
    String volumeName = _sanitizeFileName(volume.volumeName).trim();
    if (volumeName == "") {
      return "$title${Platform.pathSeparator}$title.epub";
    }
    return "$title${Platform.pathSeparator}$title $volumeName.epub";
  }

  String _sanitizeFileName(String name) {
    var keywords = {":", "*", "?", "\"", "<", ">", "|"};
    for (var keyword in keywords) {
      name = name.replaceAll(keyword, " ");
    }
    return name;
  }
}
