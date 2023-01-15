import 'dart:async';

import 'package:bili_novel_packer/bili_novel_packer.dart';

void main(List<String> arguments) {
  test();
}

void test(){
  runZonedGuarded(() {
    int id = 2704;
    BiliNovelPacker packer = BiliNovelPacker(id);
    packer.getNovel().then((novel) {
      print(novel);
      packer.getCatalog().then((catalog) {
        print(catalog);
        var volume = catalog.volumes[0];
        String dest = "${novel.title}/${novel.title} ${volume.name}.epub";
        packer.pack(catalog.volumes[0], dest);
      });
    });
  }, (error, stack) {
    print(error);
    print(stack);
  });
}
