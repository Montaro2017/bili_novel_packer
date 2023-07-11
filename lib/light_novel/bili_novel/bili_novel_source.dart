import 'dart:typed_data';

import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_source.dart';
import 'package:bili_novel_packer/light_novel/bili_novel/bili_novel_constant.dart';
import 'package:bili_novel_packer/util/html_util.dart';
import 'package:bili_novel_packer/util/http_util.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';

class BiliLightNovelSource implements LightNovelSource {
  static final RegExp _exp = RegExp("linovelib\\.com/novel/(\\d+)");
  static final String domain = "https://w.linovelib.com";

  @override
  final String name = "哔哩轻小说";

  @override
  final String sourceUrl = "https://w.linovelib.com";

  /// 获取小说基本信息
  @override
  Future<Novel> getNovel(String url) async {
    String id = _getId(url);
    Novel novel = Novel();
    var doc = parse(await HttpUtil.getString("$domain/novel/$id.html"));

    novel.id = id.toString();
    novel.title = doc.querySelector(".book-title")!.text;
    novel.coverUrl = doc.querySelector(".book-layout img")!.attributes["src"]!;
    novel.tags = doc
        .querySelectorAll(".book-cell .book-meta span em")
        .map((e) => e.text)
        .toList();
    novel.status =
        doc.querySelector(".book-cell .book-meta+.book-meta")!.nodes.last.text!;
    novel.author = doc.querySelector(".book-rand-a span")!.text;
    novel.description = doc.querySelector("#bookSummary content")!.text;
    return novel;
  }

  String _getId(String url) {
    var match = _exp.firstMatch(url);
    if (match == null || match.groupCount < 1) {
      throw "Unsupported url: $url";
    }
    return match.group(1)!;
  }

  /// 获取小说目录
  @override
  Future<Catalog> getNovelCatalog(Novel novel) async {
    var doc =
        parse(await HttpUtil.getString("$domain/novel/${novel.id}/catalog"));
    var catalog = Catalog(novel);
    var children = doc.querySelector("#volumes")!.children;
    Volume? volume;
    // 如果没有卷标题 则将书名直接作为卷名
    if (doc.querySelector(".chapter-bar") == null) {
      volume = Volume("", catalog);
    }
    for (var child in children) {
      if (child.classes.contains("chapter-bar")) {
        if (volume != null) {
          catalog.volumes.add(volume);
        }
        volume = Volume(child.text, catalog);
      } else if (child.classes.contains("jsChapter")) {
        var link = child.querySelector("a")!;
        String name = link.text;
        String? href = link.attributes["href"];
        if (href == null || href.contains("javascript")) {
          href = null;
        } else {
          href = "$domain$href";
        }
        if (volume != null) {
          var chapter = Chapter(name, href, volume);
          volume.chapters.add(chapter);
        }
      }
    }

    if (volume != null) {
      catalog.volumes.add(volume);
    }
    return catalog;
  }

  @override
  Future<Document> getNovelChapter(Chapter chapter) async {
    Document doc = Document.html(LightNovelSource.html);

    chapter.chapterUrl ??= await _getChapterUrl(chapter);
    if (chapter.chapterUrl == null) {
      throw "Empty chapter url";
    }
    String? nextPageUrl = chapter.chapterUrl!;
    do {
      ChapterPage page = await _getChapterPage(nextPageUrl!);
      for (var content in page.contents) {
        doc.body!.append(content);
      }
      nextPageUrl = page.nextPageUrl;
    } while (nextPageUrl != null);
    _replaceSecretText(doc.body!);

    HTMLUtil.removeLineBreak(doc.body!);
    // 处理图片lazy load 实际src为data-src
    _replaceImageSrc(doc.body!);
    return doc;
  }

  Future<String?> _getChapterUrl(Chapter chapter) async {
    if (chapter.chapterUrl != null && chapter.chapterUrl!.isNotEmpty) {
      return chapter.chapterUrl;
    }
    Catalog catalog = chapter.volume.catalog;
    // 先获取下一章节 再通过下一章节中的"上一章"获取链接
    var nextChapter = _getNextChapter(catalog, chapter);
    if (nextChapter != null && nextChapter.chapterUrl != null) {
      ChapterPage chapterPage = await _getChapterPage(nextChapter.chapterUrl!);
      if (chapterPage.prevChapterUrl != null) {
        return chapterPage.prevChapterUrl;
      }
    }
    // 先获取上一章节 再通过上一章节的"下一页"一直到"下一章"获取链接
    var prevChapter = _getPrevChapter(catalog, chapter);
    if (prevChapter != null && prevChapter.chapterUrl != null) {
      ChapterPage chapterPage = await _getChapterPage(prevChapter.chapterUrl!);
      String? nextPageUrl;
      ChapterPage page = chapterPage;
      for (int i = 0; i < 20; i++) {
        nextPageUrl = page.nextPageUrl;
        if (nextPageUrl == null) {
          return page.nextChapterUrl;
        }
        page = await _getChapterPage(nextPageUrl);
      }
    }
    return null;
  }

  // 根据目录查找上一章
  Chapter? _getPrevChapter(Catalog catalog, Chapter chapter) {
    List<Chapter> allChapter = catalog.volumes
        .expand(
          (volume) => volume.chapters,
        )
        .toList();
    int pos = allChapter.indexOf(chapter);
    if (pos < 1) return null;
    return allChapter[pos - 1];
  }

  // 根据目录查找下一章
  Chapter? _getNextChapter(Catalog catalog, Chapter chapter) {
    List<Chapter> chapters = catalog.volumes
        .expand(
          (volume) => volume.chapters,
        )
        .toList();
    int pos = chapters.indexOf(chapter);
    if (pos < 0 || pos > chapters.length - 1) return null;
    return chapters[pos + 1];
  }

  @override
  bool supportUrl(String url) {
    return _exp.hasMatch(url);
  }

  /// 获取章节一页内容
  Future<ChapterPage> _getChapterPage(String url) async {
    var doc = parse(await HttpUtil.getString(url));
    var content = doc.querySelector("#acontent")!;

    String? prevPage;
    String? nextPage;
    String? prevChapter;
    String? nextChapter;

    RegExp regExp = RegExp("url_previous:'(.*?)',url_next:'(.*?)'");
    RegExpMatch? match = regExp.firstMatch(doc.outerHtml);
    String? prevUrl = match?.group(1);
    String? nextUrl = match?.group(2);
    var prev = doc.querySelector("#footlink a:first-child");
    var next = doc.querySelector("#footlink a:last-child");

    if (prev != null && prev.text == "上一页" && prevUrl != null) {
      prevPage = domain + prevUrl;
    } else if (prev != null && prevUrl != null) {
      prevChapter = domain + prevUrl;
    }

    if (next != null && next.text == "下一页" && nextUrl != null) {
      nextPage = domain + nextUrl;
    } else if (next != null && nextUrl != null) {
      nextChapter = domain + nextUrl;
    }

    HTMLUtil.removeElements(content.querySelectorAll("div"));
    HTMLUtil.removeElements(content.querySelectorAll("br"));
    HTMLUtil.removeElements(content.querySelectorAll("script"));
    HTMLUtil.removeElements(content.querySelectorAll(".tp"));
    HTMLUtil.removeElements(content.querySelectorAll(".bd"));

    return ChapterPage(
      content.children,
      prevPageUrl: prevPage,
      nextPageUrl: nextPage,
      prevChapterUrl: prevChapter,
      nextChapterUrl: nextChapter,
    );
  }

  /// 替换加密字体对应文字
  _replaceSecretText(Element element) {
    String str = element.innerHtml;
    StringBuffer sb = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      String? replacement = secretMap[str[i]] ?? str[i];
      sb.write(replacement);
    }
    element.innerHtml = sb.toString();
  }

  _replaceImageSrc(Element element) {
    List<Element> images = element.querySelectorAll("img");
    for (var image in images) {
      String? src = image.attributes["data-src"];
      src ??= image.attributes["src"];
      if (src != null) {
        // 过滤src有问题的img
        if (src.contains("<")) {
          image.remove();
          continue;
        }
        if (src.startsWith("//")) {
          src = "https:$src";
        }
        image.attributes["src"] = src;
      }
    }
  }

  @override
  Future<Uint8List> getImage(String src) {
    if (!src.startsWith("http")) {
      src = "$domain/$src";
    }
    return HttpUtil.getBytes(src, headers: {
      "referer": domain,
    });
  }
}

class ChapterPage {
  List<Element> contents;
  String? prevPageUrl;
  String? nextPageUrl;
  String? prevChapterUrl;
  String? nextChapterUrl;

  ChapterPage(
    this.contents, {
    this.prevPageUrl,
    this.nextPageUrl,
    this.prevChapterUrl,
    this.nextChapterUrl,
  });
}
