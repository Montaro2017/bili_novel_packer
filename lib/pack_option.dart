import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart';

class PackOption {
  // 是否添加章节标题
  late bool addChapterTitle;

  // 选择要打包的分卷
  late List<Volume> selectedVolumes;

  PackOption();

  PackOption.all({
    required this.addChapterTitle,
    required this.selectedVolumes,
  });

  @override
  String toString() {
    return 'addChapterTitle = $addChapterTitle, selectedVolumes = $selectedVolumes';
  }
}
