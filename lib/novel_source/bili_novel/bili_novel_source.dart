import 'dart:async';
import 'dart:convert';

import 'package:bili_novel_packer/extension/string_extension.dart';
import 'package:bili_novel_packer/novel_source/base/cloudflare_interceptor.dart';
import 'package:bili_novel_packer/novel_source/base/novel_model.dart';
import 'package:bili_novel_packer/novel_source/base/novel_source.dart';
import 'package:bili_novel_packer/novel_source/bili_novel/bili_novel_secret.dart';
import 'package:bili_novel_packer/scheduler/scheduler.dart';
import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:synchronized/synchronized.dart';

class BiliNovelSource implements NovelSource {
  static final Map<String, String> secretMap = {};
  static final Scheduler _scheduler = Scheduler(15, Duration(minutes: 1));
  static final Scheduler _imageScheduler = Scheduler(10, Duration(seconds: 1));

  static const String domain = "https://www.bilinovel.com";
  static const String userAgent =
      "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36";
  static const String cookie = "night=1";

  static Lock lock = Lock();
  static bool warnFlag = false;

  final Dio dio = _dio();

  @override
  final String name = "哔哩轻小说";

  static Dio _dio() {
    const headers = {
      "Accept": "*/*",
      "Accept-Language": " zh-CN,zh;q=0.9",
      "User-Agent": userAgent,
      "Cookie": cookie,
      "Referer": "$domain/",
    };
    BaseOptions options = BaseOptions(
      headers: headers,
      responseType: ResponseType.plain,
    );
    var dio = Dio(options);
    dio.interceptors.add(CloudflareInterceptor(dio));
    return dio;
  }

  static Future<void> init() async {
    BiliNovelSource.secretMap.clear();
    BiliNovelSource.secretMap.addAll(await BiliNovelHelper.getSecretMap());
  }

  @override
  Future<List<NovelSection>> explore() async {
    var resp = await dio.get(domain);
    var html = resp.data.toString();
    return _parseIndex(html);
  }

  List<NovelSection> _parseIndex(String html) {
    var doc = parse(html);
    var bookOls = doc.querySelectorAll(".module-header + .book-ol");
    if (bookOls.isEmpty) {
      return [];
    }
    List<NovelSection> novelSections = [];
    for (var bookOl in bookOls) {
      var moduleHeader = bookOl.previousElementSibling;
      var name = moduleHeader?.querySelector(".module-title")?.text;
      if (name == null) {
        continue;
      }
      var bookLis = bookOl.querySelectorAll(".book-li");
      var novels = bookLis
          .map(
            (bookLi) => _parseNovel(bookLi),
          )
          .toList();
      NovelSection section = NovelSection(name, novels);
      novelSections.add(section);
    }
    return novelSections;
  }

  static Novel _parseNovel(Element bookLi) {
    Novel novel = Novel();
    // id
    var anchor = bookLi.querySelector(".book-li > a");
    var href = anchor!.attributes["href"]!;
    novel.id = href.subBetween("/novel/", ".")!;
    // 封面图
    var img = bookLi.querySelector(".book-cover > img");
    novel.coverUrl = img?.attributes["src"];
    // 标题 简介
    novel.title = bookLi.querySelector(".book-title")!.text;
    novel.description = bookLi.querySelector(".book-desc")!.text.trim();
    // 作者
    novel.author = bookLi.querySelector(".book-author")!.nodes.last.text;
    // 状态
    novel.status = bookLi.querySelector(".tag-small.red")!.text;
    // 标签
    novel.tags = bookLi.querySelector(".tag-small.yellow")!.text.split(" ");
    return novel;
  }

  @override
  FutureIterator<List<Novel>> search(String keyword) {
    return _BiliNovelSearchIterator(dio, keyword);
  }

  @override
  Future<Novel> loadNovel(String id) {
    // TODO: implement loadNovel
    throw UnimplementedError();
  }

  @override
  Future<Catalog> loadCatalog(Novel novel) {
    // TODO: implement loadCatalog
    throw UnimplementedError();
  }

  @override
  Future<Document> loadChapter(Catalog catalog, Chapter chapter) {
    // TODO: implement loadChapter
    throw UnimplementedError();
  }

  @override
  Future<List<int>> loadImage(String src) {
    return _imageScheduler.run((c) {
      return _loadImage(src);
    });
  }

  String _transformImageSrc(String src) {
    if (!src.startsWith("http")) {
      src = "$domain/$src";
    }
    src = src.replaceFirst("https://https://", "https://");
    // 处理图片url域名特殊字符 𝘣 = \ud835\ude23
    src = src.replaceAll("\ud835\ude23", "b");
    return src;
  }

  Future<List<int>> _loadImage(String src) async {
    if (src.startsWith("data:image")) {
      src = src.split(",")[1];
      return Future.value(base64.decode(src));
    }
    src = _transformImageSrc(src);
    var resp = await dio.get(
      src,
      options: Options(responseType: ResponseType.bytes),
    );
    return resp.data as List<int>;
  }

  // /// 获取小说基本信息
  // @override
  // Future<Novel> getNovelByUrl(String url) async {
  //   String id = _getId(url);
  //   Novel novel = Novel();
  //   String html = await httpGetString(
  //     "$domain/novel/$id.html",
  //     headers: {"Accept-Language": " zh-CN,zh;q=0.9"},
  //   );
  //   try {
  //     var doc = parse(html);
  //     novel.id = id.toString();
  //     novel.title = doc.querySelector(".book-title")!.text;

  //     // 解析别名信息
  //     var backupNameElement = doc.querySelector(
  //       ".backupname .bkname-body.gray",
  //     );
  //     if (backupNameElement != null) {
  //       novel.alias = backupNameElement.text.trim();
  //     }

  //     novel.coverUrl = doc
  //         .querySelector(".book-layout img")!
  //         .attributes["src"]!;
  //     novel.tags = doc
  //         .querySelectorAll(".book-cell .book-meta span em")
  //         .map((e) => e.text)
  //         .toList();
  //     novel.publisher = doc.querySelector(".tag-small.orange")?.text;
  //     novel.status = doc
  //         .querySelector(".book-cell .book-meta+.book-meta")!
  //         .nodes
  //         .last
  //         .text!;
  //     novel.author = doc.querySelector(".book-rand-a span")!.text;
  //     novel.description = doc.querySelector("#bookSummary content")!.text;
  //     return novel;
  //   } catch (e) {
  //     logger.e(e);
  //     logger.i(html);
  //     rethrow;
  //   }
  // }

  // String _getId(String url) {
  //   var match = _exp.firstMatch(url);
  //   if (match == null || match.groupCount < 1) {
  //     throw "Unsupported url: $url";
  //   }
  //   return match.group(1)!;
  // }

  // /// 获取小说目录
  // @override
  // Future<Catalog> getNovelCatalog(Novel novel) async {
  //   String url = "$domain/novel/${novel.id}/catalog";
  //   String html = await httpGetString(
  //     url,
  //     headers: {"Accept-Language": " zh-CN,zh;q=0.9"},
  //   );
  //   var doc = parse(html);
  //   var catalog = Catalog();
  //   var seq = Sequence();
  //   _replaceImageSrc(doc.body!);
  //   Volume? volume;
  //   // 如果没有卷标题 则将书名直接作为卷名
  //   if (doc.querySelector(".chapter-bar") == null) {
  //     volume = Volume(id: seq.next);
  //   }
  //   var lis = doc.querySelectorAll(".volume-chapters>li");
  //   if (lis.isEmpty) {
  //     logger.i("GET $url");
  //     logger.i(html);
  //     throw "目录获取为空";
  //   }
  //   for (var li in lis) {
  //     if (li.classes.contains("chapter-bar")) {
  //       if (volume != null) {
  //         catalog.volumes.add(volume);
  //       }
  //       volume = Volume(id: seq.next)..name = li.text;
  //     } else if (li.classes.contains("volume-cover")) {
  //       volume?.coverUrl = li
  //           .querySelector("a")
  //           ?.querySelector("img")
  //           ?.attributes["src"];
  //     } else if (li.classes.contains("jsChapter")) {
  //       var link = li.querySelector("a")!;
  //       String name = link.text;
  //       String? href = link.attributes["href"];
  //       if (href == null || href.contains("javascript")) {
  //         href = null;
  //       } else {
  //         href = "$domain$href";
  //       }
  //       if (volume != null) {
  //         var chapter = Chapter(name: name);
  //         volume.chapters.add(chapter);
  //       }
  //     }
  //   }

  //   if (volume != null) {
  //     catalog.volumes.add(volume);
  //   }
  //   return catalog;
  // }

  // @override
  // Future<Document> getNovelChapter(Chapter chapter) async {
  //   Document doc = Document.html(LightNovelSource.html);

  //   chapter.id ??= await _getChapterUrl(chapter);
  //   if (chapter.id == null) {
  //     throw "Empty chapter url";
  //   }
  //   logger.i(
  //     " ==> ${chapter.volume.volumeName} ${chapter.chapterName} ${chapter.chapterUrl}",
  //   );
  //   String? nextPageUrl = chapter.chapterUrl!;
  //   do {
  //     ChapterPage page = await _getChapterPage(nextPageUrl!);
  //     // 处理目录标题与章节中获取的标题不一致情况
  //     if (page.title != null &&
  //         page.title != chapter.chapterName &&
  //         !page.title!.contains("〇")) {
  //       chapter.chapterName = page.title!;
  //     }
  //     for (var content in page.contents) {
  //       doc.body!.append(content);
  //     }
  //     nextPageUrl = page.nextPageUrl;
  //   } while (nextPageUrl != null);

  //   HTMLUtil.removeLineBreak(doc.body!);
  //   // 处理图片lazy load 实际src为data-src
  //   _replaceImageSrc(doc.body!);
  //   return doc;
  // }

  // Future<String?> _getChapterUrl(Chapter chapter) async {
  //   if (chapter.chapterUrl != null && chapter.chapterUrl!.isNotEmpty) {
  //     return chapter.chapterUrl;
  //   }
  //   Catalog catalog = chapter.volume.catalog;
  //   // 先获取下一章节 再通过下一章节中的"上一章"获取链接
  //   var nextChapter = _getNextChapter(catalog, chapter);
  //   if (nextChapter != null && nextChapter.chapterUrl != null) {
  //     ChapterPage chapterPage = await _getChapterPage(nextChapter.chapterUrl!);
  //     if (chapterPage.prevChapterUrl != null) {
  //       return chapterPage.prevChapterUrl;
  //     }
  //   }
  //   // 先获取上一章节 再通过上一章节的"下一页"一直到"下一章"获取链接
  //   var prevChapter = _getPrevChapter(catalog, chapter);
  //   if (prevChapter != null && prevChapter.chapterUrl != null) {
  //     ChapterPage chapterPage = await _getChapterPage(prevChapter.chapterUrl!);
  //     String? nextPageUrl;
  //     ChapterPage page = chapterPage;
  //     for (int i = 0; i < 20; i++) {
  //       nextPageUrl = page.nextPageUrl;
  //       if (nextPageUrl == null) {
  //         return page.nextChapterUrl;
  //       }
  //       page = await _getChapterPage(nextPageUrl);
  //     }
  //   }
  //   return null;
  // }

  // // 根据目录查找上一章
  // Chapter? _getPrevChapter(Catalog catalog, Chapter chapter) {
  //   List<Chapter> allChapter = catalog.volumes
  //       .expand((volume) => volume.chapters)
  //       .toList();
  //   int pos = allChapter.indexOf(chapter);
  //   if (pos < 1) return null;
  //   return allChapter[pos - 1];
  // }

  // // 根据目录查找下一章
  // Chapter? _getNextChapter(Catalog catalog, Chapter chapter) {
  //   List<Chapter> chapters = catalog.volumes
  //       .expand((volume) => volume.chapters)
  //       .toList();
  //   int pos = chapters.indexOf(chapter);
  //   if (pos < 0 || pos >= chapters.length - 1) return null;
  //   return chapters[pos + 1];
  // }

  // @override
  // bool supportUrl(String url) {
  //   return _exp.hasMatch(url);
  // }

  // /// 获取章节一页内容
  // Future<ChapterPage> _getChapterPage(String url) async {
  //   String html = await _httpGetString(url);
  //   var doc = parse(html);

  //   String? title;
  //   if (!url.contains("_")) {
  //     title = doc.querySelector("#atitle")?.text;
  //   }
  //   var selectors = ["#acontent", ".bcontent"];
  //   var content = selectors
  //       .map((selector) => doc.querySelector(selector))
  //       .firstOrNull;
  //   if (content == null) {
  //     logger.i("GET $url ERROR");
  //     logger.i(html);
  //     throw "运行出错，请提交Issues并上传日志文件($logFilePath)，下次运行会清空日志。";
  //   } else {
  //     logger.i("GET $url OK");
  //   }

  //   String? prevPage;
  //   String? nextPage;
  //   String? prevChapter;
  //   String? nextChapter;

  //   RegExp regExp = RegExp("url_previous:'(.*?)',url_next:'(.*?)'");
  //   RegExpMatch? match = regExp.firstMatch(doc.outerHtml);
  //   String? prevUrl = match?.group(1);
  //   String? nextUrl = match?.group(2);
  //   var prev = doc.querySelector("#footlink a:first-child");
  //   var next = doc.querySelector("#footlink a:last-child");

  //   if (prev != null &&
  //       (prev.text == "上一页" || prev.text == "上一頁") &&
  //       prevUrl != null) {
  //     prevPage = domain + prevUrl;
  //   } else if (prev != null && prevUrl != null) {
  //     prevChapter = domain + prevUrl;
  //   }

  //   if (next != null &&
  //       (next.text == "下一页" || next.text == "下一頁") &&
  //       nextUrl != null) {
  //     nextPage = domain + nextUrl;
  //   } else if (next != null && nextUrl != null) {
  //     nextChapter = domain + nextUrl;
  //   }
  //   HTMLUtil.removeElements(content.querySelectorAll("div"));
  //   HTMLUtil.removeElements(content.querySelectorAll("ins"));
  //   HTMLUtil.removeElements(content.querySelectorAll("figure"));
  //   HTMLUtil.removeElements(content.querySelectorAll("fig"));
  //   HTMLUtil.removeElements(content.querySelectorAll("br"));
  //   HTMLUtil.removeElements(content.querySelectorAll("script"));
  //   HTMLUtil.removeElements(content.querySelectorAll(".tp"));
  //   HTMLUtil.removeElements(content.querySelectorAll(".bd"));
  //   HTMLUtil.removeElementsByPattern(content, r"[a-z]\d{4}");

  //   Map<String, int>? params = await _getShuffleParams(doc);
  //   if (params != null) {
  //     _shuffle(content, params);
  //   }

  //   return ChapterPage(
  //     title: title,
  //     content.children,
  //     prevPageUrl: prevPage,
  //     nextPageUrl: nextPage,
  //     prevChapterUrl: prevChapter,
  //     nextChapterUrl: nextChapter,
  //   );
  // }

  // Future<Map<String, int>?> _getShuffleParams(Document doc) async {
  //   return await lock.synchronized(() async {
  //     var script = doc
  //         .querySelectorAll("script")
  //         .where(
  //           (s) => s.attributes["src"]?.contains("chapterlog.js?v") ?? false,
  //         )
  //         .firstOrNull;
  //     if (script == null) {
  //       return null;
  //     }
  //     int? chapterId = int.tryParse(
  //       RegExp("chapterid:'(\\d+)'").firstMatch(doc.outerHtml)?.group(1) ?? '',
  //     );
  //     String jsSrc = script.attributes["src"]!;
  //     String currentVersion = "v1006c1";
  //     String matchedVersion = jsSrc.substring(jsSrc.lastIndexOf("v"));
  //     if (currentVersion != matchedVersion && !warnFlag) {
  //       print(
  //         "[警告]: chapterlog版本号不匹配，当前版本: $currentVersion, 实际版本: $matchedVersion, 可能导致章节内容顺序错乱",
  //       );
  //       warnFlag = true;
  //     }

  //     if (chapterId == null) {
  //       return null;
  //     }
  //     return {
  //       "fixedLength": 20,
  //       "seed": chapterId * 127 + 235,
  //       "a": 9302,
  //       "c": 49397,
  //       "mod": 233280,
  //     };
  //   });
  // }

  // _shuffle(Element content, Map<String, int> shuffleParams) {
  //   var pElements = content
  //       .querySelectorAll("p")
  //       .where((p) => p.text.trim().isNotEmpty)
  //       .toList();
  //   var paragraphs = [];
  //   for (var i = 0; i < pElements.length; i++) {
  //     var node = pElements[i];
  //     paragraphs.add(node);
  //   }

  //   if (paragraphs.isEmpty) {
  //     return;
  //   }
  //   var nodes = content.children;

  //   var indices = [];
  //   List<int> fixed = [];
  //   List<int> shuffled = [];

  //   int fixedLength = shuffleParams["fixedLength"]!;
  //   for (var i = 0; i < paragraphs.length; i++) {
  //     i < fixedLength ? fixed.add(i) : shuffled.add(i);
  //   }

  //   if (paragraphs.length > fixedLength) {
  //     _shuffleArr(shuffled, shuffleParams);
  //     indices = [...fixed, ...shuffled];
  //   } else {
  //     indices = [...fixed];
  //   }

  //   List<Element> mapped = List.filled(paragraphs.length, Element.tag("p"));
  //   for (var i = 0; i < paragraphs.length; i++) {
  //     mapped[indices[i]] = paragraphs[i];
  //   }
  //   var replacedIndex = 0;
  //   for (var i = 0; i < nodes.length; i++) {
  //     var node = nodes[i];
  //     if (node.localName == 'p' && node.text.trim().isNotEmpty) {
  //       content.children[i] = mapped[replacedIndex++].clone(true);
  //     }
  //   }
  // }

  // _shuffleArr(List<int> arr, Map<String, int> shuffleParams) {
  //   int a = shuffleParams["a"]!;
  //   int c = shuffleParams["c"]!;
  //   int mod = shuffleParams["mod"]!;
  //   int seed = shuffleParams["seed"]!;
  //   for (int i = arr.length - 1; i > 0; i--) {
  //     seed = (seed * a + c) % mod;
  //     int j = (seed / mod * (i + 1)).floor();
  //     int tmp = arr[i];
  //     arr[i] = arr[j];
  //     arr[j] = tmp;
  //   }
  //   return arr;
  // }

  // /// 处理所有img标签src
  // _replaceImageSrc(Element element) {
  //   List<Element> images = element.querySelectorAll("img");
  //   for (var image in images) {
  //     String? src = image.attributes["data-src"];
  //     src ??= image.attributes["src"];
  //     if (src != null) {
  //       // 过滤src有问题的img
  //       if (src.contains("<")) {
  //         image.remove();
  //         continue;
  //       }
  //       if (src.startsWith("//")) {
  //         src = "https:$src";
  //       }
  //       image.attributes["src"] = src;
  //     }
  //     // 移除img无效属性
  //     _removeImageAttr(image);
  //     // 添加alt属性
  //     _addAlt(image);
  //   }
  // }

  // /// 移除img标签无法识别的属性
  // _removeImageAttr(Element image) {
  //   var attrs = [
  //     "alt",
  //     "class",
  //     "dir",
  //     "height",
  //     "id",
  //     "ismap",
  //     "lang",
  //     "longdesc",
  //     "style",
  //     "title",
  //     "usemap",
  //     "width",
  //     "src",
  //     "xml:lang",
  //   ];
  //   for (var attr in image.attributes.keys.toList()) {
  //     if (!attrs.contains(attr as String)) {
  //       image.attributes.remove(attr);
  //     }
  //   }
  // }

  // _addAlt(Element image, [String? alt]) {
  //   image.attributes["alt"] = alt ?? "";
  // }

  // Future<String> _httpGetString(String url) {
  //   return _scheduler.run((c) async {
  //     String html = await httpGetString(
  //       url,
  //       headers: {
  //         "User-Agent": userAgent,
  //         "Accept": "*/*",
  //         "Accept-Language": "zh-CN,zh;q=0.9",
  //         "Cookie": cookie,
  //       },
  //     );
  //     if (html.contains("Cloudflare to restrict access") ||
  //         html.contains("503 Service Temporarily Unavailable")) {
  //       c.pause();
  //       await Future.delayed(Duration(seconds: 10));
  //       c.resume();
  //       return _httpGetString(url);
  //     }
  //     return html;
  //   });
  // }

  // @override
  // Future<Uint8List> getImage(String src) async {
  //   if (src.startsWith("data:image")) {
  //     src = src.split(",")[1];
  //     return Future.value(base64.decode(src));
  //   }
  //   if (!src.startsWith("http")) {
  //     src = "$domain/$src";
  //   }
  //   src = src.replaceFirst("https://https://", "https://");
  //   // 处理图片url域名特殊字符 𝘣 = \ud835\ude23
  //   src = src.replaceAll("\ud835\ude23", "b");
  //   return _imageScheduler.run((_) async {
  //     return httpGetBytes(
  //       src,
  //       headers: {
  //         "Referer": domain,
  //         "User-Agent": userAgent,
  //         "Cache-Control": "public",
  //         "Accept": "*/*",
  //         "Accept-Language": "zh-CN,zh;q=0.9",
  //         "Cookie": cookie,
  //       },
  //     );
  //   });
  // }
}

class _BiliNovelSearchIterator implements FutureIterator<List<Novel>> {
  int _currPage = 0;
  int _maxPage = 0;

  final Dio dio;
  final String keyword;

  _BiliNovelSearchIterator(this.dio, this.keyword);

  @override
  Future<List<Novel>> get current async {
    String url = "${BiliNovelSource.domain}/search/${keyword}_$_currPage.html";
    var resp = await dio.get(url);
    var html = resp.data.toString();
    var doc = parse(html);
    _maxPage = _parseMaxPage(doc);
    return _parseSearchResults(doc);
  }

  int _parseMaxPage(Document doc) {
    var text = doc.querySelector("#pagelink > span")!.text;
    RegExpMatch match = RegExp("(\\d+)/(\\d+)").firstMatch(text)!;
    return int.parse(match.group(2)!);
  }

  List<Novel> _parseSearchResults(Document doc) {
    var bookLis = doc.querySelectorAll(".book-li");
    if (bookLis.isEmpty) {
      return [];
    }
    return bookLis
        .map((bookLi) => BiliNovelSource._parseNovel(bookLi))
        .toList();
  }

  @override
  Future<bool> moveNext() async {
    if (_currPage == 0 || _currPage < _maxPage) {
      _currPage++;
      return true;
    }
    return false;
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
