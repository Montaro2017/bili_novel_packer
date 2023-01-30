import 'package:bili_novel_packer/http_retry.dart';
import 'package:html/dom.dart';
import 'package:http/http.dart';
import 'package:bili_novel_packer/extension/node_wrap_extension.dart';

import 'bili_novel_util.dart';
import 'bili_novel_model.dart';
import 'bili_novel_constant.dart';
import 'bili_novel_parser.dart' as parser;

const String html =
    "<html lang='zh-CN'><head><title></title></head><body></body></html>";

Future<Novel> getNovel(int id) async {
  String url = "$domain/novel/$id.html";
  var resp = (await retryGet(url));
  return parser.parseNovel(id, resp.body);
}

Future<Catalog> getCatalog(int id) async {
  String url = "$domain/novel/$id/catalog";
  var resp = (await retryGet(url));
  return parser.parseCatalog(resp.body);
}

Future<Document> getChapter(String url) async {
  Document doc = Document.html(html);
  String? nextPageUrl = url;
  do {
    ChapterPage page = await _getChapterPage(nextPageUrl!);
    for (var content in page.contents) {
      doc.body!.append(content);
    }
    nextPageUrl = page.nextPageUrl;
  } while (nextPageUrl != null);
  _replaceSecretText(doc.body!);
  _removeLineBreak(doc.body!);
  _wrapDuoKanImage(doc.body!);
  return doc;
}

Future<ChapterPage> _getChapterPage(String url) async {
  var req = (await retryGet(url));
  return parser.parsePage(req.body);
}

void _replaceSecretText(Element element) {
  if (element.children.isNotEmpty) {
    for (var child in element.children) {
      _replaceSecretText(child);
    }
  } else {
    element.text = _replaceText(element.text);
  }
}

String _replaceText(String str) {
  StringBuffer sb = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    String? replacement = secretMap[str[i]] ?? str[i];
    sb.write(replacement);
  }
  return sb.toString();
}

void _removeLineBreak(Element element) {
  if (element.children.isNotEmpty) {
    for (var child in element.children) {
      _removeLineBreak(child);
    }
  } else {
    element.text = element.text.replaceAll("\n", "");
  }
}

void _unwrapImage(Element element) {
  var imgList = element.querySelectorAll("img");
  for (var img in imgList) {
    img.unwrap();
  }
}

void _wrapDuoKanImage(Element element) {
  var imgList = element.querySelectorAll("img");
  for (var img in imgList) {
    img.wrap('<div class="duokan-image-single"></div>');
  }
}

Future<String?> getChapterUrl(Catalog catalog, Chapter chapter) async {
  String? chapterUrl = chapter.url;
  if (chapterUrl != null && chapterUrl.isNotEmpty) return chapterUrl;

  Chapter? nextChapter = getNextChapter(catalog, chapter);
  chapterUrl = nextChapter?.url == null
      ? null
      : await _getPrevChapterUrl(nextChapter!.url!);
  if (chapterUrl != null && chapterUrl.isNotEmpty) return chapterUrl;

  Chapter? prevChapter = getPrevChapter(catalog, chapter);
  chapterUrl = prevChapter?.url == null
      ? null
      : await _getNextChapterUrl(prevChapter!.url!);

  return chapterUrl;
}

Future<String?> _getPrevChapterUrl(String url) async {
  return (await _getChapterPage(url)).prevChapterUrl;
}

Future<String?> _getNextChapterUrl(String url) async {
  String? nextPageUrl = url;
  do {
    var page = await _getChapterPage(nextPageUrl!);
    nextPageUrl = page.nextPageUrl;
    if (nextPageUrl == null) {
      return page.nextChapterUrl;
    }
  } while (true);
}
