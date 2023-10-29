import 'dart:typed_data';

import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_source.dart';
import 'package:bili_novel_packer/light_novel/wenku_novel/wenku_novel.dart';
import 'package:bili_novel_packer/util/html_util.dart';
import 'package:bili_novel_packer/util/http_util.dart';
import 'package:bili_novel_packer/util/url_util.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:retry/retry.dart';
import 'package:synchronized/synchronized.dart';

class WenkuNovelSource implements LightNovelSource {
  @override
  final String name = "轻小说文库";
  @override
  final String sourceUrl = "https://www.wenku8.net/login.php";

  static final RegExp _exp1 = RegExp("wenku8.net/book/(\\d+)");
  static final RegExp _exp2 = RegExp("wenku8.net/novel/\\d+/(\\d+)/");
  static final String domain = "https://www.wenku8.net";

  static final String userAgent =
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36";

  static final Lock lock = Lock();

  @override
  Future<Novel> getNovel(String url) async {
    String id = _getId(url);
    WenkuNovel novel = WenkuNovel();
    var doc = parse(
      await HttpUtil.getStringFromGbk(
        "$domain/book/$id.htm",
        headers: {
          "User-Agent": userAgent,
        },
      ),
    );

    novel.id = id.toString();
    novel.title = doc
        .querySelector("#content")!
        .querySelector("table:nth-child(1)")!
        .querySelector("span b")!
        .text;
    novel.coverUrl =
        doc.querySelector("#content table img")!.attributes["src"]!;
    List<Element> details = doc
        .querySelector("#content table:nth-child(1)")!
        .querySelector("tr:nth-child(2)")!
        .querySelectorAll("td");
    novel.status = details[2].text.replaceFirst("文章状态：", "");
    novel.author = details[1].text.replaceFirst("小说作者：", "");

    Element td =
        doc.querySelectorAll("#content table")[2].querySelectorAll("td")[1];

    novel.tags =
        td.querySelector("span")!.text.replaceFirst("作品Tags：", "").split(" ");
    novel.description = td.querySelectorAll("span")[5].text;

    novel.catalogUrl =
        doc.querySelector("legend + div > a")!.attributes["href"]!;
    if (!novel.catalogUrl.startsWith("http")) {
      novel.catalogUrl = domain +
          (novel.catalogUrl.startsWith("/") ? "" : "/") +
          novel.catalogUrl;
    }
    return novel;
  }

  @override
  Future<Catalog> getNovelCatalog(Novel novel) async {
    String url = (novel as WenkuNovel).catalogUrl;
    String prefix = URLUtil.resolve(url, "./");
    var doc = parse(
      await HttpUtil.getStringFromGbk(
        url,
        headers: {
          "User-Agent": userAgent,
        },
      ),
    );
    var tdList = doc.querySelectorAll("table td");
    var catalog = Catalog(novel);
    Volume? volume;
    for (var td in tdList) {
      var styleClass = td.attributes["class"];
      if (styleClass == "vcss") {
        if (volume != null) {
          catalog.volumes.add(volume);
        }
        volume = Volume(td.text, catalog);
      } else if (styleClass == "ccss") {
        var link = td.querySelector("a");
        if (link == null) continue;
        var href = link.attributes["href"];
        if (volume == null) continue;
        var chapter = Chapter(
          link.text,
          "$prefix/$href",
          volume,
        );
        // 将插图移动至最前面
        if (chapter.chapterName == "插图") {
          volume.chapters.insert(0, chapter);
        } else {
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
    return retry(
      maxAttempts: 10,
      retryIf: (e) => true,
      delayFactor: Duration(milliseconds: 300),
      maxDelay: Duration(seconds: 3),
      () => _getNovelChapter(chapter),
    );
  }

  Future<Document> _getNovelChapter(Chapter chapter) async {
    return await lock.synchronized(() async {
      String url = chapter.chapterUrl!;
      // await Future.delayed(Duration(milliseconds: 0));
      var doc = parse(await HttpUtil.getStringFromGbk(
        url,
        headers: {
          "User-Agent": userAgent,
          "Accept":
              "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"
        },
      ));
      var content = doc.querySelector("#content");
      if (content == null && doc.outerHtml.contains("Cloudflare")) throw Exception("Cloudflare Error");
      HTMLUtil.removeElements(content!.querySelectorAll("#contentdp"));
      HTMLUtil.removeElements(content.querySelectorAll("br"));
      return _wrapDocument(content);
    });
  }

  @override
  bool supportUrl(String url) {
    return _exp1.hasMatch(url) || _exp2.hasMatch(url);
  }

  String _getId(String url) {
    var match = _exp1.firstMatch(url);
    if (match != null && match.groupCount > 0) {
      return match.group(1)!;
    }
    match = _exp2.firstMatch(url);
    if (match != null && match.groupCount > 0) {
      return match.group(1)!;
    }
    throw "Unsupported url: $url";
  }

  Document _wrapDocument(Element content) {
    Document doc = Document.html(LightNovelSource.html);
    var nodes = content.nodes;
    for (var node in nodes) {
      if (node is Text) {
        String text = node.data.trim();
        if (text.isEmpty) continue;
        var element = Element.tag("p")..text = text;
        doc.body!.append(element);
      } else {
        doc.body!.append(node.clone(true));
      }
    }
    var links = doc.querySelectorAll("a");
    for (var link in links) {
      HTMLUtil.unwrap(link);
    }
    return doc;
  }

  @override
  Future<Uint8List> getImage(String src) {
    return HttpUtil.getBytes(
      src,
      headers: {
        "User-Agent": userAgent,
      },
    );
  }
}
