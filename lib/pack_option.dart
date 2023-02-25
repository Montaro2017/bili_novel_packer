import 'bili_novel/bili_novel_model.dart';

class PackOption {
  // 是否添加章节标题
  late bool addChapterTitle;
  late bool combineVolume;
  // 选择要打包的分卷
  late List<Volume> packVolumes;
}