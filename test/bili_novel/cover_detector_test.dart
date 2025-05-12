import 'dart:io';
import 'dart:typed_data';

import 'package:bili_novel_packer/light_novel/base/light_novel_cover_detector.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart';
import 'package:bili_novel_packer/light_novel/bili_novel/bili_novel_source.dart';
import 'package:bili_novel_packer/novel_packer.dart';
import 'package:html/dom.dart';
import 'package:test/test.dart';

void main() {
  test("testIsColorful", () async {
    List<String> urls = [
      "https://img3.readpai.com/1/1860/115869/38718.jpg",
      "https://img3.readpai.com/1/1860/115869/38719.jpg",
      "https://img3.readpai.com/1/1860/115869/38720.jpg",
      "https://img3.readpai.com/1/1860/115869/38721.jpg",
      "https://img3.readpai.com/1/1860/115869/38722.jpg",
      "https://img3.readpai.com/1/1860/115869/38723.jpg",
      "https://img3.readpai.com/1/1860/115869/38724.jpg",
      "https://img3.readpai.com/1/1860/115869/38725.jpg",
      "https://img3.readpai.com/1/1860/115869/38726.jpg",
      "https://img3.readpai.com/1/1860/115869/38727.jpg",
      "https://img3.readpai.com/1/1860/115869/38728.jpg",
      "https://img3.readpai.com/1/1860/115869/38729.jpg",
      "https://img3.readpai.com/1/1860/115869/38730.jpg",
      "https://img3.readpai.com/1/1860/115869/38731.jpg",
      "https://img3.readpai.com/1/1860/115869/38732.jpg",
      "https://img3.readpai.com/1/1860/115869/38733.jpg",
      "https://img3.readpai.com/1/1860/115869/38734.jpg",
      "https://img3.readpai.com/1/1860/115869/38735.jpg",
      "https://img3.readpai.com/1/1860/115869/38736.jpg",
      "https://img3.readpai.com/1/1860/115869/38737.jpg",
      "https://img3.readpai.com/1/1860/115869/38738.jpg",
      "https://img3.readpai.com/1/1860/115869/38739.jpg"
    ];
    var source = BiliNovelSource();
    Map<String, Uint8List> imageMap = {};
    for (String url in urls) {
      Uint8List imgData = await source.getImage(url);
      String name = "images/test/${url.substring(url.lastIndexOf("/") + 1)}";
      File(name)
        ..createSync(recursive: true)
        ..writeAsBytesSync(imgData);
      imageMap[url] = imgData;
    }
    for (String url in urls) {
      int start = DateTime.now().millisecondsSinceEpoch;
      ImageInfo imageInfo = getImageInfo(imageMap[url]!);
      int end = DateTime.now().millisecondsSinceEpoch;
      print(
          "${url.substring(url.lastIndexOf("/") + 1)} colorful = ${imageInfo.colorful}, spent ${end - start} ms");
    }
  }, timeout: Timeout(Duration(hours: 1)));

  test("detectCover", () async {
    List<String> novelUrls = [
      "https://www.bilinovel.com/novel/1860.html",
      "https://www.bilinovel.com/novel/2013.html",
      "https://www.bilinovel.com/novel/2547.html",
      "https://www.bilinovel.com/novel/2773.html",
      "https://www.bilinovel.com/novel/2014.html",
      "https://www.bilinovel.com/novel/2939.html",
      "https://www.bilinovel.com/novel/2139.html",
      "https://www.bilinovel.com/novel/2321.html",
      "https://www.bilinovel.com/novel/75.html",
      "https://www.bilinovel.com/novel/6.html",
      "https://www.bilinovel.com/novel/2890.html",
      "https://www.bilinovel.com/novel/2342.html",
      "https://www.bilinovel.com/novel/2044.html",
      "https://www.bilinovel.com/novel/2.html",
      "https://www.bilinovel.com/novel/2025.html",
      "https://www.bilinovel.com/novel/2499.html",
      "https://www.bilinovel.com/novel/9.html",
      "https://www.bilinovel.com/novel/2741.html",
      "https://www.bilinovel.com/novel/1855.html",
      "https://www.bilinovel.com/novel/2356.html"
    ];
    var source = BiliNovelSource();
    for (String novelUrl in novelUrls) {
      print("Novel = $novelUrl");
      Novel novel = await source.getNovel(novelUrl);
      Catalog catalog = await source.getNovelCatalog(novel);
      for (var volume in catalog.volumes) {
        if (volume.chapters.first.chapterName == "插图") {
          print("Volume = ${volume.volumeName}");
          String dir = "images/test/${NovelPacker.sanitizeFileName(novel.title)}/${NovelPacker.sanitizeFileName(volume.volumeName)}/";
          Directory(dir).createSync(recursive: true);

          var detector = LightNovelCoverDetector();
          Document doc = await source.getNovelChapter(volume.chapters.first);
          List<Element> imgList = doc.querySelectorAll("img");
          Map<String, Uint8List> imageMap = {};
          for (var img in imgList) {
            String url = img.attributes["src"]!;
            print("fetch image $url");
            String name = url.substring(url.lastIndexOf("/") + 1);
            Uint8List imgData = await source.getImage(url);
            File("$dir$name").writeAsBytesSync(imgData);
            detector.add(name, imgData);
            imageMap[name] = imgData;
          }
          String? cover = detector.detectCover();
          if (cover != null) {
            File("${dir}cover.jpg").writeAsBytesSync(imageMap[cover]!);
          }
        } else {
          continue;
        }
      }
    }
  }, timeout: Timeout(Duration(hours: 12)));
}
