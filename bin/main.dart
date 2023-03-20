import 'dart:async';
import 'dart:io';

import 'package:bili_novel_packer/bili_novel/bili_novel_http.dart' as bili_http;
import 'package:bili_novel_packer/bili_novel/bili_novel_model.dart';
import 'package:bili_novel_packer/bili_novel_packer.dart';
import 'package:bili_novel_packer/loading_bar.dart';
import 'package:bili_novel_packer/pack_option.dart';
import 'package:bili_novel_packer/packer_callback.dart';
import 'package:console/console.dart';

const String gitUrl = "https://gitee.com/Montaro2017/bili_novel_packer";
const String version = "0.0.4-beta";

void main(List<String> arguments) async {
  printWelcome();
  start();
}

void printWelcome() {
  print("欢迎使用哔哩轻小说打包器!");
  print("作者: Sparks");
  print("当前版本: $version");
  print("如遇报错请先查看能否正常访问 https://w.linovelib.com");
  print("否则请至开源地址携带报错信息进行反馈: $gitUrl");
}

Future<void> start() async {
  print("");
  int id = readNovelId();
  Novel novel = await bili_http.getNovel(id);
  print("");
  printNovel(novel);
  Catalog catalog = await bili_http.getCatalog(id);
  var packOption = readPackOption(catalog);
  PackerCallback callback = ConsoleCallback();
  for (Volume volume in packOption.packVolumes) {
    String dest = getDest(novel, volume);
    BiliNovelVolumePacker packer = BiliNovelVolumePacker(
      novel: novel,
      catalog: catalog,
      volume: volume,
      dest: dest,
      callback: callback,
      addChapterTitle: packOption.addChapterTitle,
    );
    await packer.pack();
  }
  (callback as ConsoleCallback).stop("全部任务已完成！");
  exit(0);
}

int readNovelId() {
  print("请输入ID或URL:");
  String? line = stdin.readLineSync();
  if (line == null) {
    throw "输入内容不能为空";
  }
  int? id = int.tryParse(line);
  if (id != null) return id;
  RegExp exp = RegExp("novel/(\\d+)");
  RegExpMatch? match = exp.firstMatch(line);
  if (match == null || match.groupCount < 1) {
    throw "请输入正确的ID或URL";
  }
  id = int.tryParse(match.group(1)!);
  if (id == null) {
    throw "请输入正确的ID或URL";
  }
  return id;
}

PackOption readPackOption(Catalog catalog) {
  var option = PackOption();
  var select = readSelectVolume(catalog);
  Console.write("\n");
  option.packVolumes = select;
  option.addChapterTitle =
      Chooser(["是", "否"], message: "是否为每章添加标题？").chooseSync() == "是";
  Console.write("\n");
  return option;
}

List<Volume> readSelectVolume(Catalog catalog) {
  Console.write("\n");
  for (int i = 0; i < catalog.volumes.length; i++) {
    Console.write("[${i + 1}] ${catalog.volumes[i].name}\n");
  }
  Console.write("[0] 选择全部\n");
  Console.write(
    "请选择需要下载的分卷(可输入如1-9进行范围选择以及如2,5单独选择):",
  );
  var input = Console.readLine();
  List<Volume> selectVolumeIndex = [];

  if (input == null || input == "0") {
    for (int i = 0; i < catalog.volumes.length; i++) {
      selectVolumeIndex.add(catalog.volumes[i]);
    }
    return selectVolumeIndex;
  }
  List<String> parts = input.split(",");
  for (var part in parts) {
    List<String> range = part.split("-");
    if (range.length == 1) {
      int index = int.parse(range[0]) - 1;
      selectVolumeIndex.add(catalog.volumes[index]);
    } else {
      int from = int.parse(range[0]);
      int to = int.parse(range[1]);
      if (from > to) {
        int tmp = from;
        from = to;
        to = tmp;
      }
      for (int i = from; i <= to; i++) {
        int index = i - 1;
        selectVolumeIndex.add(catalog.volumes[index]);
      }
    }
  }
  return selectVolumeIndex;
}

void pause() {
  print("请按回车键继续...");
  stdin.readLineSync();
}

void printNovel(Novel novel) {
  print("书名: ${novel.title}");
  print("作者: ${novel.author}");
  print("状态: ${novel.status}");
  print("标签: ${novel.tags}");
  print(novel.description);
}

String getDest(Novel novel, Volume volume) {
  String name = ensureFileName(novel.title);
  String epub = ensureFileName("$name ${volume.name}.epub");
  return "$name\\$epub";
}

String ensureFileName(String name) {
  return name.replaceAllMapped(
      "<|>|:|\"|/|\\\\|\\?|\\*|\\\\|\\|", (match) => " ");
}

class ConsoleCallback extends PackerCallback {
  String? _message;
  bool stopped = false;
  late MyLoadingBar bar = MyLoadingBar(callback: writeMessage);

  set message(String? message) {
    _message = message;
    bar.update();
  }

  String? get message => _message;

  @override
  void onAfterResolveChapter(Chapter chapter) {}

  @override
  void onAfterPack(Volume volume, String dest) {
    String absoluteDest = File(dest).absolute.path;
    Console.overwriteLine("打包完成: ${volume.name} 文件保存路径: $absoluteDest\n\n");
  }

  @override
  void onAfterResolveImage(String src, String relativeImgPath) {}

  @override
  void onBeforePack(Volume volume, String dest) {
    print("开始打包 ${volume.name}");
  }

  @override
  void onBeforeResolveChapter(Chapter chapter) {
    message = "下载章节 ${chapter.name}";
  }

  @override
  void onBeforeResolveImage(String src) {
    message = "下载图片 $src";
  }

  @override
  void onChapterUrlEmpty(Chapter chapter) {}

  @override
  void onError(error, {StackTrace? stackTrace}) {
    print(error);
    print(stackTrace);
  }

  @override
  void onSetCover(String src, String relativePath) {}

  ConsoleCallback() {
    bar.start();
  }

  void writeMessage() {
    if (stopped) return;
    Console.write("\t${message ?? ""}");
  }

  void stop([String? message]) {
    stopped = true;
    Console.overwriteLine("");
    bar.stop(message);
  }
}
