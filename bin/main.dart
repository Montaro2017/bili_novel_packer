import 'dart:async';
import 'dart:io';

import 'package:bili_novel_packer/bili_novel/bili_novel_http.dart' as bili_http;
import 'package:bili_novel_packer/bili_novel/bili_novel_model.dart';
import 'package:bili_novel_packer/bili_novel_packer.dart';
import 'package:bili_novel_packer/packer_callback.dart';
import 'package:console/console.dart';

void main(List<String> arguments) async {
  start().then((_) {
    print("\n全部任务已完成!");
  });
}

Future<void> start() async {
  int id = readNovelId();
  Novel novel = await bili_http.getNovel(id);
  print("");
  printNovel(novel);
  Catalog catalog = await bili_http.getCatalog(id);
  pause();
  PackerCallback callback = ConsoleCallback();
  for (Volume volume in catalog.volumes) {
    String dest = getDest(novel, volume);
    BiliNovelVolumePacker packer = BiliNovelVolumePacker(
      novel: novel,
      catalog: catalog,
      volume: volume,
      dest: dest,
      // callback: callback,
    );
    await packer.pack();
  }
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
  return "$name/$epub";
}

String ensureFileName(String name) {
  return name;
}

class ConsoleCallback extends PackerCallback {
  @override
  void onAfterBeforeResolveChapter(Chapter chapter) {
    print("下载章节: ${chapter.name} ${chapter.url}");
  }

  @override
  void onAfterPack(Volume volume, String dest) {
    print("打包完成: ${volume.name} $dest");
  }

  @override
  void onAfterResolveImage(String src, String relativeImgPath) {
    print("图片下载完成: $src $relativeImgPath");
  }

  @override
  void onBeforePack(Volume volume, String dest) {
    print("[开始打包]: ${volume.name}");
  }

  @override
  void onBeforeResolveChapter(Chapter chapter) {
    // print("章节下载完成: ${chapter.name}");
  }

  @override
  void onBeforeResolveImage(String src) {
    print("下载图片: $src");
  }

  @override
  void onChapterUrlEmpty(Chapter chapter) {
    // print("章节URL为空: ${chapter.name}");
  }

  @override
  void onError(error, {StackTrace? stackTrace}) {
    print("发生错误:$error");
    print(stackTrace);
  }

  @override
  void onSetCover(String src, String relativePath) {
    print("设置封面: $src");
  }

  ConsoleCallback() {
    Console.init();
  }
}
