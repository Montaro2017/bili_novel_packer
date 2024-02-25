import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bili_novel_packer/epub_packer/epub_navigator.dart';
import 'package:bili_novel_packer/epub_packer/epub_packer.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_cover_detector.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_source.dart';
import 'package:bili_novel_packer/light_novel/bili_novel/bili_novel_source.dart';
import 'package:bili_novel_packer/light_novel/wenku_novel/wenku_novel_source.dart';
import 'package:bili_novel_packer/pack_argument.dart';
import 'package:bili_novel_packer/util/html_util.dart';
import 'package:bili_novel_packer/util/sequence.dart';
import 'package:console/console.dart';
import 'package:html/dom.dart';

class NovelPacker {
  static final List<LightNovelSource> sources = [
    BiliNovelSource(),
    WenkuNovelSource()
  ];

  String url;
  LightNovelSource lightNovelSource;

  final Sequence _imageSequence = Sequence();
  final Sequence _chapterSequence = Sequence();

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

  Future<Novel> init({
    Function(Novel novel)? novelCallback,
    Function(Catalog catalog)? catalogCallback,
  }) async {
    novel = await getNovel();
    novelCallback?.call(novel);
    catalog = await getCatalog();
    catalogCallback?.call(catalog);
    return novel;
  }

  Future<Novel> getNovel() async {
    return lightNovelSource.getNovel(url).then((novel) => this.novel = novel);
  }

  Future<Catalog> getCatalog() async {
    return lightNovelSource
        .getNovelCatalog(novel)
        .then((catalog) => this.catalog = catalog);
  }

  Future<void> pack(PackArgument arg) async {
    if (lightNovelSource is WenkuNovelSource) {
      print("[注意]: 轻小说文库设置了速率限制，不能请求过快，因此打包速度较慢，请耐心等待.\n");
    }
    if (lightNovelSource is BiliNovelSource) {
      await BiliNovelSource.init();
    }
    if (!arg.combineVolume) {
      for (var volume in arg.packVolumes) {
        _imageSequence.reset();
        _chapterSequence.reset();
        await _packVolume(volume, arg.addChapterTitle);
      }
    } else {
      // 合并分卷
      String title = _sanitizeFileName(novel.title);
      String path = "$title${Platform.pathSeparator}$title.epub";
      await _combineVolume(path, arg);
    }
  }

  Future<void> _combineVolume(
    String path,
    PackArgument arg,
  ) async {
    EpubPacker packer = EpubPacker(path);
    packer.docTitle = novel.title;
    packer.creator = novel.author;
    packer.source = novel.url;
    packer.publisher = novel.publisher;
    packer.subjects = novel.tags ?? [];
    packer.description = novel.description;
    // 封面使用小说封面
    Uint8List coverData = await _getSingleImage(novel.coverUrl);
    String coverName =
        "images/${_imageSequence.next.toString().padLeft(6, '0')}.jpg";
    packer.addImage(name: "OEBPS/$coverName", data: coverData);
    packer.cover = coverName;

    for (Volume volume in arg.packVolumes) {
      Console.write("正在处理: ${volume.volumeName}\n");
      NavPoint volumeNavPoint = NavPoint(volume.volumeName);
      List<Future<Document>> futures = volume.chapters
          .map((chapter) =>
              _resolveChapter(chapter, packer, arg.addChapterTitle))
          .toList();

      List<Document> chapterDocuments = await Future.wait(futures);
      for (int i = 0; i < chapterDocuments.length; i++) {
        Chapter chapter = volume.chapters[i];
        Document document = chapterDocuments[i];
        String html = _closeTag(document);
        String name =
            "chapter${_chapterSequence.next.toString().padLeft(6, "0")}.xhtml";
        packer.addChapter(
          addNavPoint: false,
          name: "OEBPS/$name",
          title: chapter.chapterName,
          chapterContent: html,
        );
        NavPoint chapterNavPoint = NavPoint(chapter.chapterName, src: name);
        volumeNavPoint.addChild(chapterNavPoint);
        if (i == 0) {
          volumeNavPoint.src = name;
        }
      }
      packer.addNavPoint(volumeNavPoint);
    }
    packer.pack();
    Console.write("打包完成: ${packer.absolutePath}");
  }

  Future<Document> _resolveChapter(
    Chapter chapter,
    EpubPacker packer,
    bool addChapterTitle, [
    LightNovelCoverDetector? detector,
  ]) async {
    Document doc = await lightNovelSource.getNovelChapter(chapter);

    // 下载图片 添加到epub中
    List<Element> imgList = doc.querySelectorAll("img");
    List<String?> srcList = imgList.map((e) => e.attributes["src"]).toList();
    List<Uint8List> imageDataList = await _getImages(srcList);
    for (int i = 0; i < imageDataList.length; i++) {
      Element imageElement = imgList[i];
      Uint8List data = imageDataList[i];
      // 跳过错误的图片
      if (data.isEmpty) {
        continue;
      }

      String name = "${_imageSequence.next.toString().padLeft(6, '0')}.jpg";
      String relativeSrc = "images/$name";
      packer.addImage(name: "OEBPS/$relativeSrc", data: data);
      imageElement.attributes["src"] = relativeSrc;
      detector?.add("OEBPS/$relativeSrc", data);
    }

    HTMLUtil.wrapDuoKanImage(doc.body!);
    // 添加章节标题
    if (addChapterTitle) {
      var firstChild = doc.body!.firstChild;
      Node chapterTitle = Element.html(
        '<div style="margin-top:0.5em;font-size:1.25em;font-weight: 800;text-align:center;">${chapter.chapterName}</div>',
      );
      doc.body!.insertBefore(chapterTitle, firstChild);
    }
    return doc;
  }

  Future<List<Uint8List>> _getImages(List<String?> srcList) async {
    List<Future<Uint8List>> futures = [];
    for (var src in srcList) {
      futures.add(_getSingleImage(src).catchError(
        (e) {
          print("下载图片失败: $src");
          return Uint8List(0);
        },
      ));
    }
    return Future.wait(futures);
  }

  Future<Uint8List> _getSingleImage(String? src) async {
    try {
      if (src == null) {
        return Uint8List(0);
      }
      return lightNovelSource.getImage(src);
    } catch (e) {
      return Uint8List(0);
    }
  }

  Future<void> _packVolume(
    Volume volume,
    bool addChapterTitle,
  ) async {
    Console.write("开始打包 ${volume.volumeName}...\n");
    EpubPacker packer = EpubPacker(_getEpubName(volume));
    packer.docTitle = "${volume.catalog.novel.title} ${volume.volumeName}";
    packer.creator = volume.catalog.novel.author;
    packer.source = novel.url;
    packer.publisher = novel.publisher;
    packer.subjects = novel.tags ?? [];
    packer.description = novel.description;

    LightNovelCoverDetector detector = LightNovelCoverDetector();

    List<Future<Document>> futures = volume.chapters
        .map((chapter) =>
            _resolveChapter(chapter, packer, addChapterTitle, detector))
        .toList();

    List<Document> chapterDocuments = await Future.wait(futures);

    // 添加章节资源
    for (int i = 0; i < chapterDocuments.length; i++) {
      var chapter = volume.chapters[i];
      var document = chapterDocuments[i];
      String html = _closeTag(document);
      packer.addChapter(
        name:
            "OEBPS/chapter${_chapterSequence.next.toString().padLeft(6, "0")}.xhtml",
        title: chapter.chapterName,
        chapterContent: html,
      );
    }

    // 设置封面
    await _resolveCover(volume, packer, detector);
    // 写出目标文件
    packer.pack();
    Console.write("打包完成: ${packer.absolutePath}\n\n");
  }

  Future<void> _resolveCover(
    Volume volume,
    EpubPacker packer,
    LightNovelCoverDetector coverDetector,
  ) async {
    // 优先使用目录中的封面 否则自动检测
    if (volume.cover != null) {
      Uint8List coverData = await _getSingleImage(volume.cover).catchError((e) {
        throw "下载封面失败 ${volume.cover}\n$e";
      });
      String coverName =
          "images/${_imageSequence.next.toString().padLeft(6, '0')}.jpg";
      packer.addImage(name: "OEBPS/$coverName", data: coverData);
      packer.cover = coverName;
    } else {
      String? cover = coverDetector.detectCover();
      if (cover != null) {
        packer.cover = cover.replaceFirst("OEBPS/", "");
      }
    }
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

  /// 将标签闭合
  String _closeTag(Document document) {
    String html = document.outerHtml;
    RegExp regExp = RegExp("(<img.*?)>");
    Iterable<RegExpMatch> matches = regExp.allMatches(html);
    for (var match in matches) {
      String img = match.group(0)!;
      if (!img.endsWith("/>")) {
        String newImg = "${match.group(1)!}/>";
        html = html.replaceAll(img, newImg);
      }
    }
    return html;
  }
}
