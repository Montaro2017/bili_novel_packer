import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart';

class PackArgument {
  // 是否添加章节标题
  late bool addChapterTitle;

  // 是否合并分卷
  bool combineVolume = false;

  // 选择要打包的分卷
  late List<Volume> packVolumes;


  PackArgument();

  PackArgument.all({
    required this.addChapterTitle,
    required this.combineVolume,
    required this.packVolumes,
  });
}
