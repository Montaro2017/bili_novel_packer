import 'dart:io';

import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart';
import 'package:bili_novel_packer/novel_packer.dart';
import 'package:bili_novel_packer/pack_argument.dart';
import 'package:console/console.dart';

const String gitUrl = "https://gitee.com/Montaro2017/bili_novel_packer";
const String version = "0.1.0-beta-multi";

void main(List<String> args) async {
  printWelcome();
  start();
}

void printWelcome() {
  print("欢迎使用轻小说打包器!");
  print("作者: Sparks");
  print("当前版本: $version");
  print("如遇报错请先查看能否正常访问 https://w.linovelib.com");
  print("否则请至开源地址携带报错信息进行反馈: $gitUrl");
}

void start() async {
  var url = readUrl();
  var packer = NovelPacker.fromUrl(url);
  printNovelDetail(await packer.getNovel());
  Catalog catalog = await packer.getCatalog();
  packer.pack(PackArgument()
    ..packVolumes = catalog.volumes
    ..addChapterTitle = false
    ..combineVolume = false);
}

String readUrl() {
  String? url;
  do {
    print("请输入URL:");
    url = stdin.readLineSync();
  } while (url == null || url.isEmpty);
  return url;
}

void printNovelDetail(Novel novel) {
  Console.write("");
  Console.write(novel.toString());
}

// PackArgument getPackArgument(NovelPacker) {}
