import 'package:bili_novel_packer/epub_packer/epub_navigator.dart';
import 'package:test/scaffolding.dart';

void main() {
  test("EpubNavigator Test", () {
    var nav = EpubNavigator();
    nav.bookUuid = "dffb4170-fc27-4122-9103-aec8afd91ab7";
    nav.docTitle = "测试测试";
    nav.addNavMapItem("第一章", "chapter001.xhtml");
    nav.addNavMapItem("第一章", "chapter001.xhtml");
    nav.addNavMapItem("第一章", "chapter001.xhtml");
    var doc = nav.build();
    print(doc.toXmlString(pretty: true));
  });
}
