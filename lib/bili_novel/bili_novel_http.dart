import 'package:bili_novel_packer/bili_novel/bili_novel_constant.dart';
import 'package:bili_novel_packer/bili_novel/bili_novel_model.dart';
import 'package:bili_novel_packer/bili_novel/bili_novel_parser.dart' as parser;
import 'package:bili_novel_packer/extension/node_wrap_extension.dart';
import 'package:bili_novel_packer/http_retry.dart';
import 'package:html/dom.dart';

const String html =
    "<html lang='zh-CN'><body></body></html>";

/// 通过小说[id]获取对应小说详情
Future<Novel> getNovel(int id) async {
  String url = "$domain/novel/$id.html";
  var resp = (await retryGet(url));
  return parser.parseNovel(id, resp.body);
}

/// 通过小说[id]获取小说目录
/// 获取到的章节url可能为空
Future<Catalog> getCatalog(int id) async {
  String url = "$domain/novel/$id/catalog";
  var resp = (await retryGet(url));
  return parser.parseCatalog(resp.body);
}

/// 通过章节[url]获取小说章节内容
Future<Document> getChapter(String url) async {
  Document doc = Document.html(html);
  String? nextPageUrl = url;
  do {
    ChapterPage page = await getChapterPage(nextPageUrl!);
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

Future<ChapterPage> getChapterPage(String url) async {
  var req = (await retryGet(url));
  return parser.parsePage(req.body);
}

void _replaceSecretText(Element element) {
    element.innerHtml = _replaceText(element.innerHtml);
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
