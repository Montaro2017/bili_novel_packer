import 'package:bili_novel_packer/bili_novel/bili_novel_model.dart';

abstract class PackerCallback {
  /// 打包前
  void onBeforePack(Volume volume, String dest);

  /// 下载章节前
  void onBeforeResolveChapter(Chapter chapter);

  /// 章节url为空
  void onChapterUrlEmpty(Chapter chapter);

  /// 下载图片前
  void onBeforeResolveImage(String src);

  /// 下载图片后
  void onCompleteResolveImage(String src);

  /// 下载章节后
  void onAfterBeforeResolveChapter(Chapter chapter);

  /// 打包完成
  void onCompletePack(Volume volume, String dest);

  /// 发生错误
  void onError(error);
}
