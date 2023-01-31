import 'package:archive/archive.dart';
import 'package:bili_novel_packer/bili_novel/bili_novel_http.dart';
import 'package:bili_novel_packer/bili_novel/bili_novel_model.dart';
import 'package:bili_novel_packer/media_type.dart';

Chapter? getPrevChapter(Catalog catalog, Chapter chapter) {
  List<Chapter> chapters = catalog.volumes
      .expand(
        (volume) => volume.chapters,
      )
      .toList();
  int pos = chapters.indexOf(chapter);
  if (pos < 1) return null;
  return chapters[pos - 1];
}

Chapter? getNextChapter(Catalog catalog, Chapter chapter) {
  List<Chapter> chapters = catalog.volumes
      .expand(
        (volume) => volume.chapters,
      )
      .toList();
  int pos = chapters.indexOf(chapter);
  if (pos < 0 || pos > chapters.length - 1) return null;
  return chapters[pos + 1];
}

Future<String?> _getPrevChapterUrl(String url) async {
  return (await getChapterPage(url)).prevChapterUrl;
}

Future<String?> _getNextChapterUrl(String url) async {
  String? nextPageUrl = url;
  do {
    var page = await getChapterPage(nextPageUrl!);
    nextPageUrl = page.nextPageUrl;
    if (nextPageUrl == null) {
      return page.nextChapterUrl;
    }
  } while (true);
}

/// 通过目录[catalog]和章节[chapter]获取章节的url
/// 其原理是通过上下章节页面中的“上一章”和“下一章”的链接获取
/// 可能返回空
Future<String?> getChapterUrl(Catalog catalog, Chapter chapter) async {
  String? chapterUrl = chapter.url;
  if (chapterUrl != null && chapterUrl.isNotEmpty) return chapterUrl;

  Chapter? nextChapter = getNextChapter(catalog, chapter);
  chapterUrl = nextChapter?.url == null
      ? null
      : await _getPrevChapterUrl(nextChapter!.url!);
  if (chapterUrl != null && chapterUrl.isNotEmpty) return chapterUrl;

  Chapter? prevChapter = getPrevChapter(catalog, chapter);
  chapterUrl = prevChapter?.url == null
      ? null
      : await _getNextChapterUrl(prevChapter!.url!);

  return chapterUrl;
}

class ImageInfo {
  int width;
  int height;
  String mimeType;

  ImageInfo(this.width, this.height, this.mimeType);

  double get ratio => width / height;

  @override
  String toString() {
    return "ImageInfo(width = $width, height = $height, ratio = $ratio, mimeType = $mimeType)";
  }
}

ImageInfo? getImageInfo(InputStreamBase isb, [String? src]) {
  int width;
  int height;
  String mimeType;
  int c1 = isb.readByte();
  int c2 = isb.readByte();
  int c3 = isb.readByte();
  // GIF
  if (c1 == 0x47 && c2 == 0x49 && c3 == 0x46) {
    isb.skip(3);
    width = isb.readUint16();
    height = isb.readUint16();
    mimeType = gif;
    return ImageInfo(width, height, mimeType);
  }
  // JPG
  if (c1 == 0xFF && c2 == 0xD8) {
    while (c3 == 255) {
      int marker = isb.readByte();
      int len = _readInt(isb, 2, true);
      if (marker == 192 || marker == 193 || marker == 194) {
        isb.skip(1);
        height = _readInt(isb, 2, true);
        width = _readInt(isb, 2, true);
        mimeType = jpeg;
        return ImageInfo(width, height, mimeType);
      }
      isb.skip(len - 2);
      c3 = isb.readByte();
    }
  }
  // PNG
  if (c1 == 137 && c2 == 80 && c3 == 78) {
    isb.skip(15);
    width = _readInt(isb, 2, true);
    isb.skip(2);
    height = _readInt(isb, 2, true);
    mimeType = png;
    return ImageInfo(width, height, mimeType);
  }
  // BMP
  if (c1 == 66 && c2 == 77) {
    isb.skip(15);
    width = _readInt(isb, 2, false);
    isb.skip(2);
    height = _readInt(isb, 2, false);
    mimeType = bmp;
    return ImageInfo(width, height, mimeType);
  }
  // WEBP
  if (c1 == 0x52 && c2 == 0x49 && c3 == 0x46) {
    var bytes = isb.readBytes(27).toUint8List();
    width = (bytes[24] & 0xFF) << 8 | (bytes[23] & 0xFF);
    height = (bytes[26] & 0xFF) << 8 | (bytes[25] & 0xFF);
    mimeType = webp;
    return ImageInfo(width, height, mimeType);
  }
  return null;
  // throw "Unsupported image type $src";
}

int _readInt(InputStreamBase isb, int count, bool bigEndian) {
  int ret = 0;
  int sv = bigEndian ? ((count - 1) * 8) : 0;
  int cnt = bigEndian ? -8 : 8;
  for (int i = 0; i < count; i++) {
    ret |= isb.readByte() << sv;
    sv += cnt;
  }
  return ret;
}
