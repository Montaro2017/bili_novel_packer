import 'dart:io';

import 'package:bili_novel_packer/console/console.dart';
import 'package:bili_novel_packer/console/prompt.dart';
import 'package:bili_novel_packer/console/selector.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_source.dart';
import 'package:bili_novel_packer/light_novel/bili_novel/bili_novel_source.dart';
import 'package:bili_novel_packer/light_novel/wenku_novel/wenku_novel_source.dart';
import 'package:bili_novel_packer/logger.dart';
import 'package:bili_novel_packer/novel_packer.dart';
import 'package:bili_novel_packer/pack_option.dart';

const String gitUrl = "https://github.com/Montaro2017/bili_novel_packer";
const String version = "0.2.46";

List<LightNovelSource> sources = [
  BiliNovelSource(),
  WenkuNovelSource(),
];

void main(List<String> args) async {
  printWelcome();
  try {
    await start();
  } catch (e, stackTrace) {
    logger.e(e, stackTrace: stackTrace);
    console.writeLine(e);
    console.writeLine(stackTrace);
    console.write("运行出错，按回车键退出.($version)");
    console.readLine();
  }
}

void printWelcome() {
  console.writeLine("欢迎使用轻小说打包器!");
  console.writeLine("作者: Spark");
  console.writeLine("当前版本: $version");
  console.writeLine("如遇报错请先查看能否正常访问输入网址");
  console.writeLine("否则请至开源地址携带报错信息进行反馈: $gitUrl");
}

Future<void> start() async {
  logger.i("version: $version");
  var (url, source) = readUrlSource();
  logger.i("URL: $url");

  console.writeLine("正在加载数据...");
  var novel = await source.getNovel(url);
  logger.i(novel);
  printNovelDetail(novel);
  var catalog = await source.getNovelCatalog(novel);
  var (option, combineVolume) = readPackOption(catalog);
  logger.i("option: $option, combineVolume: $combineVolume");

  await pack(
    source: source,
    novel: novel,
    option: option,
    combineVolume: combineVolume,
  );
  console.write("全部任务已完成，按回车键退出.");
  console.readLine();
  exit(0);
}

(String, LightNovelSource) readUrlSource() {
  do {
    console.writeLine("请输入URL(支持哔哩轻小说&轻小说文库):");
    var input = console.readLine();
    if (input == null || input.trim() == "") {
      continue;
    }
    var s = detectSource(input);
    if (s == null) {
      console.writeLine("不支持的URL: $input\n");
    } else {
      return (input, s);
    }
  } while (true);
}

LightNovelSource? detectSource(String url) {
  for (var source in sources) {
    if (source.supportUrl(url)) {
      return source;
    }
  }
  return null;
}

void printNovelDetail(Novel novel) {
  console.writeLine();
  console.write(novel.toString());
  console.writeLine();
}

(PackOption, bool) readPackOption(Catalog catalog) {
  var option = PackOption();
  var combineVolume = false;
  option.selectedVolumes = Selector(
    options: catalog.volumes,
    message: "请选择要下载的分卷: ",
    suffix: "选择全部",
  ).selectMany();

  if (option.selectedVolumes.length > 1) {
    console.writeLine();
    combineVolume = Prompt(
      "是否合并选择的分卷为一个文件? ",
      defaultValue: false,
    ).prompt();
  }

  console.writeLine();
  option.addChapterTitle = Prompt(
    "是否在每章开头添加章节标题? ",
    defaultValue: false,
  ).prompt();
  console.writeLine();
  return (option, combineVolume);
}

Future<void> pack({
  required LightNovelSource source,
  required Novel novel,
  required PackOption option,
  required bool combineVolume,
}) async {
  if (combineVolume && option.selectedVolumes.length <= 1) {
    combineVolume = false;
  }
  var packer = NovelPacker(source);
  if (combineVolume) {
    await packer.packCombine(source: source, novel: novel, option: option);
  } else {
    for (var volume in option.selectedVolumes) {
      await packer.packVolume(source: source, volume: volume, option: option);
    }
  }
}
