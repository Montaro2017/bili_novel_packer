
import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart';

class PackArgument {
  // 是否添加章节标题
  late bool addChapterTitle;
  late bool combineVolume;
  // 选择要打包的分卷
  late List<Volume> packVolumes;
}