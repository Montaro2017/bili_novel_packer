import 'dart:async';
import 'dart:io';

import 'package:bili_novel_packer/bili_novel/bili_novel_model.dart';
import 'package:bili_novel_packer/bili_novel_packer.dart';

void main(List<String> arguments) async {
  start().then((v) {
    print("\n全部任务已完成!");
  });

  // test();
}

Future<void> start() async {
  int id = readNovelId();
  BiliNovelPacker packer = BiliNovelPacker(id);
  Novel novel = await getNovel(packer);
  print("");
  printNovel(novel);
  Catalog catalog = await getCatalog(packer);
  pause();
  List<Future> futures = [];
  String dir = novel.title;
  print("下载已开始，请耐心等待...");
  for (var volume in catalog.volumes) {
    String file = "${novel.title} ${volume.name}.epub";
    String dest = "$dir\\$file";
    // futures.add(
    await packer.pack(volume, dest).then((path) {
      print("[${volume.name}] 打包完成: $path");
    });
    // );
  }
  // await Future.wait(futures);
}

int readNovelId() {
  print("请输入id或URL");
  String? line = stdin.readLineSync();
  if (line == null) {
    throw "输入内容不能为空";
  }
  int? id = int.tryParse(line);
  if (id != null) return id;
  RegExp exp = RegExp("novel/(\\d+)");
  RegExpMatch? match = exp.firstMatch(line);
  if (match == null || match.groupCount < 1) {
    throw "请输入正确的id或URL";
  }
  id = int.tryParse(match.group(1)!);
  if (id == null) {
    throw "请输入正确的id或URL";
  }
  return id;
}

Future<Novel> getNovel(BiliNovelPacker packer) async {
  return await packer.getNovel();
}

void pause() {
  print("请按回车键继续...");
  stdin.readLineSync();
}

Future<Catalog> getCatalog(BiliNovelPacker packer) async {
  return await packer.getCatalog();
}

void printNovel(Novel novel) {
  print("书名: ${novel.title}");
  print("作者: ${novel.author}");
  print("状态: ${novel.status}");
  print("标签: ${novel.tags}");
  print(novel.description);
}

void test() {
  runZonedGuarded(() {
    int id = 2704;
    BiliNovelPacker packer = BiliNovelPacker(id);
    packer.getNovel().then((novel) {
      print(novel);
      packer.getCatalog().then((catalog) {
        // print(catalog);
        for (var volume in catalog.volumes) {
          String dest = "${novel.title}/${novel.title} ${volume.name}.epub";
          packer.pack(volume, dest);
        }
      });
    });
  }, (error, stack) {
    print(error);
    print(stack);
  });
}
