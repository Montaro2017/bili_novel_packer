import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_source.dart';
import 'package:bili_novel_packer/light_novel/bili_novel/bili_font_secret.dart';
import 'package:bili_novel_packer/light_novel/bili_novel/bili_novel_constant.dart';
import 'package:bili_novel_packer/light_novel/bili_novel/bili_novel_secret.dart';
import 'package:bili_novel_packer/util/html_util.dart';
import 'package:bili_novel_packer/util/http_util.dart';
import 'package:bili_novel_packer/util/retry_util.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';

class BiliNovelSource implements LightNovelSource {
  static final RegExp _exp =
      RegExp("(?:linovelib|bilinovel)\\.com/novel/(\\d+)");
  static final String domain = "https://www.bilinovel.com";

  static final Map<String, String> secretMap = {};

  static final String userAgent =
      "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36";

  static final String cookie = "night=0";

  @override
  final String name = "哔哩轻小说";

  @override
  final String sourceUrl = "https://www.bilinovel.com";

  static Future<void> init() async {
    BiliNovelSource.secretMap.clear();
    BiliNovelSource.secretMap.addAll(await BiliNovelHelper.getSecretMap());
  }

  /// 获取小说基本信息
  @override
  Future<Novel> getNovel(String url) async {
    String id = _getId(url);
    Novel novel = Novel();
    var doc = parse(await HttpUtil.getString("$domain/novel/$id.html"));

    novel.id = id.toString();
    novel.url = url;
    novel.title = doc.querySelector(".book-title")!.text;
    novel.coverUrl = doc.querySelector(".book-layout img")!.attributes["src"]!;
    novel.tags = doc
        .querySelectorAll(".book-cell .book-meta span em")
        .map((e) => e.text)
        .toList();
    novel.publisher = doc.querySelector(".tag-small.orange")?.text;
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
    _replaceImageSrc(doc.body!);
    var children = doc.querySelector("#volumes")!.children;
    Volume? volume;
    // 如果没有卷标题 则将书名直接作为卷名
    if (doc.querySelector(".chapter-bar") == null) {
      volume = Volume("", catalog);
    }
    for (var child in children) {
      if (!child.classes.contains("catalog-volume")) {
        continue;
      }
      var lis = child.querySelectorAll(".volume-chapters>li");
      for (var li in lis) {
        if (li.classes.contains("chapter-bar")) {
          if (volume != null) {
            catalog.volumes.add(volume);
          }
          volume = Volume(li.text, catalog);
        } else if (li.classes.contains("volume-cover")) {
          volume?.cover =
              child.querySelector("a")?.querySelector("img")?.attributes["src"];
        } else if (li.classes.contains("jsChapter")) {
          var link = li.querySelector("a")!;
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
      // 处理目录标题与章节中获取的标题不一致情况
      if (page.title != null &&
          page.title != chapter.chapterName &&
          !page.title!.contains("〇")) {
        chapter.chapterName = page.title!;
      }
      for (var content in page.contents) {
        doc.body!.append(content);
      }
      nextPageUrl = page.nextPageUrl;
    } while (nextPageUrl != null);

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
    if (pos < 0 || pos >= chapters.length - 1) return null;
    return chapters[pos + 1];
  }

  @override
  bool supportUrl(String url) {
    return _exp.hasMatch(url);
  }

  /// 获取章节一页内容
  Future<ChapterPage> _getChapterPage(String url) async {
    String html = await _httpGetString(url);
    var doc = parse(html);

    String? title;
    if (!url.contains("_")) {
      title = doc.querySelector("#atitle")?.text;
    }
    var content = doc.querySelector("#acontentz")!;

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

    if (prev != null &&
        (prev.text == "上一页" || prev.text == "上一頁") &&
        prevUrl != null) {
      prevPage = domain + prevUrl;
    } else if (prev != null && prevUrl != null) {
      prevChapter = domain + prevUrl;
    }

    if (next != null &&
        (next.text == "下一页" || next.text == "下一頁") &&
        nextUrl != null) {
      nextPage = domain + nextUrl;
    } else if (next != null && nextUrl != null) {
      nextChapter = domain + nextUrl;
    }
    HTMLUtil.removeElements(content.querySelectorAll("div"));
    HTMLUtil.removeElements(content.querySelectorAll("ins"));
    HTMLUtil.removeElements(content.querySelectorAll("figure"));
    HTMLUtil.removeElements(content.querySelectorAll("br"));
    HTMLUtil.removeElements(content.querySelectorAll("script"));
    HTMLUtil.removeElements(content.querySelectorAll(".tp"));
    HTMLUtil.removeElements(content.querySelectorAll(".bd"));
    _replaceSecretText(content);
    // _escape(content);

    if (html.contains('font-family: "read"')) {
      _replaceFontSecretText(content);
    }

    return ChapterPage(
      title: title,
      content.children,
      prevPageUrl: prevPage,
      nextPageUrl: nextPage,
      prevChapterUrl: prevChapter,
      nextChapterUrl: nextChapter,
    );
  }

  _escape(Element content) {
    var elements = content.querySelectorAll("*");
    for (var element in elements) {
      element.text = escape(element.text);
    }
  }

  _replaceFontSecretText(Element content) {
    List<Element> ps = content.querySelectorAll("p");
    // ISSUES#29
    if (ps.isEmpty) {
      return;
    }
    Element lastP = ps.last;
    String text = lastP.text;

    StringBuffer sb = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      String beforeChar = text[i];
      if (blankUnicode.contains(beforeChar)) {
        continue;
      }
      String? replacement = fontSecretMap[beforeChar];
      String t = replacement ?? beforeChar;
      sb.write(t);
    }
    lastP.text = sb.toString();
  }

  /// 替换加密字体对应文字
  _replaceSecretText(Element element) {
    String str = element.innerHtml;
    StringBuffer sb = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      String beforeChar = str[i];
      String? replacement = secretMap[beforeChar];
      sb.write(replacement ?? beforeChar);
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

  Future<String> _httpGetString(String url) {
    Completer completer = Completer<void>();
    return retryByResult(
      () => HttpUtil.getString(
        url,
        headers: {
          "User-Agent": userAgent,
          "Accept": "*/*",
          "Accept-Language": "zh-CN,zh;q=0.9",
          "Cookie": cookie
        },
      ),
      predicate: (result) {
        return result.contains("error code") ||
            result.contains("Cloudflare to restrict access");
      },
      delay: Duration(seconds: 10),
      onFinish: () {
        completer.complete();
      },
    );
  }

  Future<Uint8List> _httpGetImage(String url) {
    Completer completer = Completer<void>();
    return retryByResult(
      () => HttpUtil.getBytes(
        url,
        headers: {
          "Referer": domain,
          "User-Agent": userAgent,
          "Cache-Control": "public",
          "Accept-Language": "zh-CN,zh;q=0.9"
        },
      ),
      maxRetries: 5,
      predicate: (result) {
        // 403 Forbidden
        String str = String.fromCharCodes(result);
        return str.contains("403") && str.contains("nginx");
      },
      delay: Duration(seconds: 5),
      onRetry: () {
        // print("$url 403");
      },
      onFinish: () {
        completer.complete();
      },
    );
  }

  @override
  Future<Uint8List> getImage(String src) async {
    if (src.startsWith("data:image")) {
      src = src.split(",")[1];
      return Future.value(base64.decode(src));
    }
    if (!src.startsWith("http")) {
      src = "$domain/$src";
    }
    // 处理图片url域名特殊字符 𝘣 = \ud835\ude23
    src = src.replaceAll("\ud835\ude23", "b");
    var ret = _httpGetImage(src);
    return ret;
  }
}

class ChapterPage {
  String? title;
  List<Element> contents;
  String? prevPageUrl;
  String? nextPageUrl;
  String? prevChapterUrl;
  String? nextChapterUrl;

  ChapterPage(
    this.contents, {
    this.title,
    this.prevPageUrl,
    this.nextPageUrl,
    this.prevChapterUrl,
    this.nextChapterUrl,
  });
}
