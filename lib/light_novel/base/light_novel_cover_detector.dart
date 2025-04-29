import 'dart:typed_data';

import 'package:bili_novel_packer/novel_packer.dart';
import 'package:image/image.dart' as img;

class LightNovelCoverDetector {
  // 最佳封面图片比率
  static final double coverRatio = 3 / 4;

  final List<Pair<String, ImageInfo>> _imageList = [];

  void add(String name, Uint8List imageData, [int? index]) {
    ImageInfo imageInfo = getImageInfo(imageData);
    // 过滤掉宽图
    if (imageInfo.ratio >= 1) {
      return;
    }
    if (index != null) {
      _imageList.insert(index, Pair(name, imageInfo));
    } else {
      _imageList.add(Pair(name, imageInfo));
    }
  }

  String? detectCover() {
    if (_imageList.isEmpty) {
      return null;
    }
    List<Pair<String, ImageInfo>> list = [];
    for (Pair<String, ImageInfo> pair in _imageList) {
      ImageInfo imageInfo = pair.v2;
      if (imageInfo.ratio < 1) {
        if (imageInfo.colorful) {
          return pair.v1;
        }
        list.add(pair);
      }
    }
    if (list.isNotEmpty) {
      return list.first.v1;
    }
    return _imageList.first.v1;
  }
}

class ImageInfo {
  int width;
  int height;
  bool colorful;
  String mimeType;

  ImageInfo(this.width, this.height, this.mimeType, [this.colorful = false]);

  double get ratio => width / height;

  @override
  String toString() {
    return "ImageInfo(width = $width, height = $height, colorful = $colorful, ratio = $ratio, mimeType = $mimeType)";
  }
}

ImageInfo getImageInfo(Uint8List imgData) {
  img.Decoder? decoder = img.findDecoderForData(imgData);
  if (decoder == null) {
    throw UnsupportedImageException("不支持的图片类型");
  }
  img.Image? image = decoder.decode(imgData);
  if (image == null) {
    throw UnsupportedImageException("不支持的图片类型");
  }
  int width = image.width;
  int height = image.height;
  String mimeType = "image/${decoder.format.name.toLowerCase()}";
  bool colorful = _isColorful(image);
  return ImageInfo(width, height, mimeType, colorful);
}

/// 判断图片是否是黑白的
bool _isColorful(img.Image image, {int tolerance = 5}) {
  int width = image.width;
  int height = image.height;
  // 降采样 颜色量化
  int rx = 100;
  int ry = 100;
  // int bitShift = 4;
  int xStep = (width / (rx + 1)).ceil();
  int yStep = (height / (ry + 1)).ceil();

  int totalSampled = 0;
  int validGrayPixels = 0;

  for (int x = xStep; x < width; x = x + xStep) {
    for (int y = yStep; y < height; y = y + yStep) {
      img.Pixel p = image.getPixel(x, y);
      final r = p.r.toInt();
      final g = p.g.toInt();
      final b = p.b.toInt();
      final maxDiff = [r - g, r - b, g - b]
          .map((diff) => diff.abs())
          .reduce((a, b) => a > b ? a : b);
      if (maxDiff <= tolerance) {
        validGrayPixels++;
      }
      totalSampled++;
    }
  }
  return (validGrayPixels / totalSampled) <= 0.2;
}

class UnsupportedImageException implements Exception {
  final String message;

  UnsupportedImageException(this.message);
}
