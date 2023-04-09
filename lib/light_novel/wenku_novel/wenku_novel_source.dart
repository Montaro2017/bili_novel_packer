import 'dart:typed_data';

import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_source.dart';
import 'package:bili_novel_packer/light_novel/wenku_novel/wenku_novel.dart';
import 'package:bili_novel_packer/util/html_util.dart';
import 'package:bili_novel_packer/util/http_util.dart';
import 'package:bili_novel_packer/util/url_util.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';

class WenkuNovelSource implements LightNovelSource {
  @override
  final String name = "轻小说文库";
  @override
  final String sourceUrl = "https://www.wenku8.net/login.php";

  static final RegExp _exp1 = RegExp("wenku8.net/book/(\\d+)");
  static final RegExp _exp2 = RegExp("wenku8.net/novel/\\d+/(\\d+)/");
  static final String domain = "https://www.wenku8.net";

  @override
  Future<Novel> getNovel(String url) async {
    String id = _getId(url);
    WenkuNovel novel = WenkuNovel();
    var doc = parse(await HttpUtil.getStringFromGbk("$domain/book/$id.htm"));

    novel.id = id.toString();
    novel.title = doc.querySelector("#content table:nth-child(1) span b")!.text;
    novel.coverUrl =
        doc.querySelector("#content table img")!.attributes["src"]!;
    List<Element> details = doc
        .querySelector("#content table:nth-child(1) tr:nth-child(2)")!
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

    return novel;
  }

  @override
  Future<Catalog> getNovelCatalog(Novel novel) async {
    String url = (novel as WenkuNovel).catalogUrl;
    String prefix = URLUtil.resolve(url, "./");
    var doc = parse(await HttpUtil.getStringFromGbk(url));
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
    String url = chapter.chapterUrl!;
    var doc = parse(await HttpUtil.getStringFromGbk(url));
    var content = doc.querySelector("#content")!;
    HTMLUtil.removeElements(content.querySelectorAll("#contentdp"));
    HTMLUtil.removeElements(content.querySelectorAll("br"));
    return _wrapDocument(content);
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
    return HttpUtil.getBytes(src);
  }
}
