import 'package:bili_novel_packer/bili_novel/bili_novel_http.dart' as bili_http;
import 'package:bili_novel_packer/bili_novel/bili_novel_http.dart';
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
      print(doc.format());
    });

    test("NodeExtension", () {
      String html =
          "<html><head></head><body><div>aaa<!-- 这是一条注释 --><div>bbb</div></div></body></html>";
      var doc = Document.html(html);
      print(doc.format());
    });

    // TODO: 处理解析 https://www.linovelib.com/novel/2704/135520_6.html 问题

    test("tryParse", () async {
      String url = "https://www.linovelib.com/novel/2704/135520_6.html";
      String html = """<p>「好好好、好的！内、内容、要写些什么呢……？」
</p><p>「你替我问她，她是要选铁处女<iron maiden="">、断头台、露天葬、活埋&lt;打西瓜&gt;，还是要全身着火&lt;火不倒翁&gt;。」
</iron></p>
      """;
      var doc = Document.html(html);
      print(doc.querySelector("打西瓜"));
    });

    test("tryParse2", () async {
      String url = "https://www.linovelib.com/novel/2704/135520_6.html";
      Document chapter = await getChapter(url);
      print(chapter.format());
      print(chapter.outerHtml);
    });
  });
}
