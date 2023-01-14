import 'package:bili_novel_packer/bili_novel/bili_novel_http.dart' as bili_http;
import 'package:bili_novel_packer/extension/node_format_extension.dart';
import 'package:html/dom.dart';
import 'package:test/scaffolding.dart';

void main() {
  group("BiliNovelHttp Test", () {
    test("getNovel", () async {
      var novel = (await bili_http.getNovel(2704));
      print(novel);
    });

    test("getCatalog", () async {
      var catalog = (await bili_http.getCatalog(2704));
      print(catalog);
    });

    test("getChapter", () async {
      String url = "https://www.linovelib.com/novel/2547/123015.html";
      var doc = (await bili_http.getChapter(url));
      print(doc?.format());
    });

    test("NodeExtension", () {
      String html = "<html><head></head><body><div>aaa<!-- 这是一条注释 --><div>bbb</div></div></body></html>";
      var doc = Document.html(html);
      print(doc.format());
    });
  });
}
