import 'package:bili_novel_packer/epub_packer/epub_navigator.dart';
import 'package:test/scaffolding.dart';

void main() {
  test("EpubNavigator Test", () {
    var nav = EpubNavigator();
    nav.bookUuid = "dffb4170-fc27-4122-9103-aec8afd91ab7";
    nav.docTitle = "测试测试";
    nav.addNavPoint(NavPoint("第一章", src: "chapter001.xhtml"));
    nav.addNavPoint(NavPoint("第一章", src: "chapter001.xhtml"));
    nav.addNavPoint(NavPoint("第一章", src: "chapter001.xhtml"));
    var doc = nav.build();
    print(doc.toXmlString(pretty: true));
  });

  test("EpubNavigator Nested", () {
    var nav = EpubNavigator();
    nav.bookUuid = "dffb4170-fc27-4122-9103-aec8afd91ab7";
    nav.docTitle = "测试测试";
    nav.addNavPoint(
      NavPoint(
        "第一章",
        children: [
          NavPoint(
            "101",
            src: "chapter101.xhtml",
            children: [
              NavPoint("101-1", src: "chapter101-1.xhtml"),
            ],
          ),
          NavPoint("102", src: "chapter102.xhtml"),
        ],
      ),
    );
    nav.addNavPoint(NavPoint(
      "第二章",
      children: [
        NavPoint("201", src: "chapter201.xhtml"),
        NavPoint("202", src: "chapter202.xhtml"),
      ],
    ));
    nav.addNavPoint(NavPoint(
      "第三章",
      children: [
        NavPoint("301", src: "chapter301.xhtml"),
        NavPoint("302", src: "chapter302.xhtml"),
      ],
    ));
    var doc = nav.build();
    print(doc.toXmlString(pretty: true));
  });
}
