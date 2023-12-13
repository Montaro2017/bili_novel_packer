import 'package:bili_novel_packer/novel_packer.dart';
import 'package:bili_novel_packer/pack_argument.dart';
import 'package:test/scaffolding.dart';

import '../bin/main.dart';

void main() {
  test("testBiliNovel", () async {
    String url = "https://www.bilinovel.com/novel/3765.html";
    NovelPacker packer = NovelPacker.fromUrl(url);
    await packer.init();
    printNovelDetail(packer.novel);
    await packer.pack(PackArgument.all(
      addChapterTitle: false,
      combineVolume: false,
      packVolumes: packer.catalog.volumes,
    ));
  });

  test("testWenku", () async {
    String url = "https://www.wenku8.net/book/3537.htm";
    NovelPacker packer = NovelPacker.fromUrl(url);
    await packer.init();
    printNovelDetail(packer.novel);
    await packer.pack(PackArgument.all(
      addChapterTitle: false,
      combineVolume: false,
      packVolumes: packer.catalog.volumes,
    ));
  });
}
