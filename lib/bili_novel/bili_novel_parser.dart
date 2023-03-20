import 'package:bili_novel_packer/bili_novel/bili_novel_constant.dart';
import 'package:bili_novel_packer/bili_novel/bili_novel_model.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;

Novel parseNovel(int id, String html) {
  var doc = parse(html);
  Novel novel = Novel();
  novel.id = id;
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

Catalog parseCatalog(String html) {
  var doc = parse(html);
  Catalog catalog = Catalog();
  var children = doc.querySelector("#volumes")!.children;
  Volume? volume;
  for (var child in children) {
    if (child.classes.contains("chapter-bar")) {
      if (volume != null) {
        catalog.volumes.add(volume);
      }
      volume = Volume(child.text);
    } else if (child.classes.contains("jsChapter")) {
      var link = child.querySelector("a")!;
      String name = link.text;
      String? href = link.attributes["href"];
      if (href == null || href.contains("javascript")) {
        href = null;
      } else {
        href = "$domain$href";
      }
      volume!.chapters.add(Chapter(name, href));
    }
  }
  if (volume != null) {
    catalog.volumes.add(volume);
  }
  return catalog;
}

ChapterPage parsePage(String html) {
  var doc = parse(html);
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
  if (prev != null && prev.text == "上一章" && prevUrl != null) {
    prevChapter = domain + prevUrl;
  }
  if (prev != null && prev.text == "上一页" && prevUrl != null) {
    prevPage = domain + prevUrl;
  }
  if (next != null && next.text == "下一章" && nextUrl != null) {
    nextChapter = domain + nextUrl;
  }
  if (next != null && next.text == "下一页" && nextUrl != null) {
    nextPage = domain + nextUrl;
  }

  _removeElements(content.querySelectorAll("div"));
  _removeElements(content.querySelectorAll("br"));
  _removeElements(content.querySelectorAll("script"));
  _removeElements(content.querySelectorAll(".tp"));
  _removeElements(content.querySelectorAll(".bd"));

  return ChapterPage(
    content.children,
    prevPageUrl: prevPage,
    nextPageUrl: nextPage,
    prevChapterUrl: prevChapter,
    nextChapterUrl: nextChapter,
  );
}

void _removeElements(List<Element> elements) {
  for (var element in elements) {
    element.remove();
  }
}
