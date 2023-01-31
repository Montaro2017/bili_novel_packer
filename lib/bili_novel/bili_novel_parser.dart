import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;
import 'package:bili_novel_packer/bili_novel/bili_novel_model.dart';
import 'package:bili_novel_packer/bili_novel/bili_novel_constant.dart';

Novel parseNovel(int id, String html) {
  var doc = parse(html);
  Novel novel = Novel();
  novel.id = id;
  novel.title = doc.querySelector(".book-info>h1.book-name")!.text;
  novel.coverUrl = doc.querySelector(".book-img.fl > img")!.attributes["src"]!;
  novel.tags =
      doc.querySelectorAll(".book-label a").map((e) => e.text).toList();
  novel.status = novel.tags[0];
  novel.author = doc.querySelector(".au-name a")!.text;
  novel.description = doc.querySelector(".book-dec > p")!.text;
  return novel;
}

Catalog parseCatalog(String html) {
  var doc = parse(html);
  Catalog catalog = Catalog();
  var children = doc.querySelector("ul.chapter-list")!.children;
  Volume? volume;
  for (var child in children) {
    if (child.classes.contains("volume")) {
      if (volume != null) {
        catalog.volumes.add(volume);
      }
      volume = Volume(child.text);
    } else if (child.classes.contains("col-4")) {
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
  var content = doc.querySelector("#TextContent")!;

  String? prevPage;
  String? nextPage;
  String? prevChapter;
  String? nextChapter;
  var prev = doc.querySelector(".mlfy_page a:first-child");
  var next = doc.querySelector(".mlfy_page a:last-child");
  if (prev != null && prev.text == "上一章") {
    prevChapter = domain + prev.attributes["href"]!;
  }
  if (prev != null && prev.text == "上一页") {
    prevPage = domain + prev.attributes["href"]!;
  }
  if (next != null && next.text == "下一章") {
    nextChapter = domain + next.attributes["href"]!;
  }
  if (next != null && next.text == "下一页") {
    nextPage = domain + next.attributes["href"]!;
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

