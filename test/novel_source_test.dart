import 'package:bili_novel_packer/novel_source/base/novel_model.dart';
import 'package:bili_novel_packer/novel_source/bili_novel/bili_novel_source.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  await testBiliNovelExplorer();
  await testBiliNovelSearch();
}

Future testBiliNovelExplorer() async {
  test(
    "testBiliNovelExplorer",
    () async {
      var novelSource = BiliNovelSource();
      List<NovelSection> sections = await novelSource.explore();
      for (var section in sections) {
        print("=====${section.name}=====");
        for (var novel in section.novels) {
          print(" - ${novel.title}");
        }
        print("===============");
      }
    },
    timeout: Timeout(Duration(minutes: 5)),
  );
}

Future testBiliNovelSearch() async {
  test(
    "testBiliNovelSearch",
    () async {
      var novelSource = BiliNovelSource();
      var iterator = novelSource.search("我是");
      int index = 1;
      while (await iterator.moveNext()) {
        List<Novel> novels = await iterator.current;
        for (var novel in novels) {
          if (kDebugMode) {
            print("${(index++).toString().padLeft(2)} ${novel.title}");
          }
        }
      }
    },
    timeout: Timeout(Duration(minutes: 5)),
  );
}
