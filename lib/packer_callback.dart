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
  void onAfterResolveImage(String src, String relativeImgPath);

  /// 下载章节后
  void onAfterResolveChapter(Chapter chapter);

  /// 打包完成
  void onAfterPack(Volume volume, String dest);

  /// 设置封面
  void onSetCover(String src, String relativePath);

  /// 发生错误
  void onError(error, {StackTrace? stackTrace});
}
