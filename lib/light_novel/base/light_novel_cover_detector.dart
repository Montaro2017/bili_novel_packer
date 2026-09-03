import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:bili_novel_packer/media_type.dart';

class LightNovelCoverDetector {
  // 最佳封面图片比率
  static final double coverRatio = 3 / 4;

  final Map<String, ImageInfo> _imageInfoMap = {};

  void add(String name, Uint8List imageData) {
    ImageInfo imageInfo = _getImageInfo(InputMemoryStream(imageData));
    _imageInfoMap[name] = imageInfo;
  }

  void addFirst(String name, Uint8List imageData) {
    Map<String, ImageInfo> map = {};
    ImageInfo imageInfo = _getImageInfo(InputMemoryStream(imageData));
    map[name] = imageInfo;
    for (var entry in _imageInfoMap.entries) {
      map[entry.key] = entry.value;
    }
    _imageInfoMap.clear();
    _imageInfoMap.addAll(map);
  }

  String? detectCover() {
    if (_imageInfoMap.isEmpty) {
      return null;
    }
    for (var entry in _imageInfoMap.entries) {
      if (entry.value.ratio < 1) {
        return entry.key;
      }
    }
    return _imageInfoMap.keys.first;
  }
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

ImageInfo _getImageInfo(InputStream inputStream) {
  int width;
  int height;
  String mimeType;
  int c1 = inputStream.readByte();
  int c2 = inputStream.readByte();
  int c3 = inputStream.readByte();
  // GIF
  if (c1 == 0x47 && c2 == 0x49 && c3 == 0x46) {
    inputStream.skip(3);
    width = inputStream.readUint16();
    height = inputStream.readUint16();
    mimeType = gif;
    return ImageInfo(width, height, mimeType);
  }
  // JPG
  if (c1 == 0xFF && c2 == 0xD8) {
    while (c3 == 255) {
      int marker = inputStream.readByte();
      int len = _readInt(inputStream, 2, true);
      if (marker == 192 || marker == 193 || marker == 194) {
        inputStream.skip(1);
        height = _readInt(inputStream, 2, true);
        width = _readInt(inputStream, 2, true);
        mimeType = jpeg;
        return ImageInfo(width, height, mimeType);
      }
      inputStream.skip(len - 2);
      c3 = inputStream.readByte();
    }
  }
  // PNG
  if (c1 == 137 && c2 == 80 && c3 == 78) {
    inputStream.skip(15);
    width = _readInt(inputStream, 2, true);
    inputStream.skip(2);
    height = _readInt(inputStream, 2, true);
    mimeType = png;
    return ImageInfo(width, height, mimeType);
  }
  // BMP
  if (c1 == 66 && c2 == 77) {
    inputStream.skip(15);
    width = _readInt(inputStream, 2, false);
    inputStream.skip(2);
    height = _readInt(inputStream, 2, false);
    mimeType = bmp;
    return ImageInfo(width, height, mimeType);
  }
  // WEBP
  if (c1 == 0x52 && c2 == 0x49 && c3 == 0x46) {
    var bytes = inputStream.readBytes(27).toUint8List();
    width = (bytes[24] & 0xFF) << 8 | (bytes[23] & 0xFF);
    height = (bytes[26] & 0xFF) << 8 | (bytes[25] & 0xFF);
    mimeType = webp;
    return ImageInfo(width, height, mimeType);
  }

  String head =
      "0x${c1.toRadixString(16)} 0x${c2.toRadixString(16)} 0x${c3.toRadixString(16)}";
  throw UnsupportedImageException("不支持的图片类型($head)");
}

int _readInt(InputStream inputStream, int count, bool bigEndian) {
  int ret = 0;
  int sv = bigEndian ? ((count - 1) * 8) : 0;
  int cnt = bigEndian ? -8 : 8;
  for (int i = 0; i < count; i++) {
    ret |= inputStream.readByte() << sv;
    sv += cnt;
  }
  return ret;
}

class UnsupportedImageException implements Exception {
  final String message;

  UnsupportedImageException(this.message);
}
