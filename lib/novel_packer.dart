import 'dart:io';
import 'dart:typed_data';

import 'package:bili_novel_packer/epub_packer/epub_packer.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_cover_detector.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_source.dart';
import 'package:bili_novel_packer/light_novel/bili_novel/bili_novel_source.dart';
import 'package:bili_novel_packer/pack_argument.dart';
import 'package:bili_novel_packer/pack_callback.dart';
import 'package:bili_novel_packer/util/http_util.dart';
import 'package:bili_novel_packer/util/url_util.dart';
import 'package:html/dom.dart';
import 'package:path/path.dart';

class NovelPacker {
  static final List<LightNovelSource> sources = [
    BiliLightNovelSource(),
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
        await _packVolume(volume, callback);
      }
    }
  }

  Future<void> _packVolume(Volume volume, [PackCallback? callback]) async {
    callback?.beforePackVolume(volume);
    EpubPacker packer = EpubPacker(_getEpubName(volume));
    packer.docTitle = "${volume.catalog.novel.title} ${volume.volumeName}";
    packer.creator = volume.catalog.novel.author;
    List<Future<Document>> chapterFutures = [];
    for (var chapter in volume.chapters) {
      chapterFutures.add(lightNovelSource.getNovelChapter(chapter));
    }
    List<Document> chapterDocuments = await Future.wait(chapterFutures);
    List<Element> imageElements = [];
    for (var chapterDocument in chapterDocuments) {
      imageElements.addAll(chapterDocument.querySelectorAll("img"));
    }
    // 下载所有图片
    List<MapEntry<String, Uint8List>?> images =
        await _resolveImages("", imageElements);

    LightNovelCoverDetector detector = LightNovelCoverDetector();

    // 添加图片资源
    for (var image in images) {
      if (image == null) continue;
      detector.add(image.key, image.value);
      packer.addImage(name: image.key, data: image.value);
    }
    // 设置封面
    packer.cover = detector.detectCover().replaceFirst("OEBPS/", "");
    // 添加章节资源
    for (int i = 0; i < volume.chapters.length; i++) {
      Chapter chapter = volume.chapters[i];
      Document chapterDocument = chapterDocuments[i];
      packer.addChapter(
        name: "OEBPS/chapter${(i + 1).toString().padLeft(4, "0")}.xhtml",
        title: chapter.chapterName,
        chapterContent: chapterDocument.outerHtml,
      );
    }
    // 写出目标文件
    packer.pack();
    callback?.afterPackVolume(volume);
  }

  /// 下载所有图片
  Future<List<MapEntry<String, Uint8List>?>> _resolveImages(
    String baseUri,
    List<Element> imageElements,
  ) async {
    List<Future<MapEntry<String, Uint8List>?>> imageFutures = [];
    for (var image in imageElements) {
      imageFutures.add(_resolveImage(baseUri, image));
    }
    return await Future.wait(imageFutures);
  }

  /// 下载单张图片 并替换img标签中的src
  Future<MapEntry<String, Uint8List>?> _resolveImage(
    String baseUri,
    Element image,
  ) async {
    String? src = image.attributes["src"];
    if (src == null) return null;
    if (!src.startsWith("http")) {
      src = (toUri(baseUri)..pathSegments.add(src)).path;
    }
    Uint8List data = (await HttpUtil.get(
      src,
      headers: {
        "referer": "https://w.linovelib.com/",
      },
    ))
        .bodyBytes;
    String href = "images/${URLUtil.getFileName(src)}";
    image.attributes["src"] = href;
    return MapEntry("OEBPS/$href", data);
  }

  String _getEpubName(Volume volume) {
    return _sanitizeFileName(
      "${volume.catalog.novel.title}${Platform.pathSeparator}${volume.catalog.novel.title} ${volume.volumeName}.epub",
    );
  }

  String _sanitizeFileName(String name) {
    return name.replaceAllMapped(
      "<|>|:|\"|/|\\\\|\\?|\\*|\\\\|\\|",
      (match) => " ",
    );
  }
}
