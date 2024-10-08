import 'dart:typed_data';

import 'package:bili_novel_packer/light_novel/bili_novel/bili_novel_source.dart';
import 'package:bili_novel_packer/light_novel/wenku_novel/wenku_novel_source.dart';
import 'package:bili_novel_packer/scheduler/scheduler.dart';
import 'package:bili_novel_packer/util/http_util.dart';
import 'package:fast_gbk/fast_gbk.dart';
import 'package:test/test.dart';

void main() {
  test(
    "BiliNovel Rate",
    () async {
      // 极限大约为49/min
      Scheduler scheduler = Scheduler(49, Duration(minutes: 1));
      // 先等待半分钟 等RateLimit解除
      await Future.delayed(Duration(seconds: 40));
      for (int i = 1; i <= 100; i++) {
        scheduler.run((_) async {
          String html = await httpGetString(
            "https://www.bilinovel.com/novel/1860/67643.html",
          );
          if (html.contains("nginx") ||
              html.contains("rate limited") ||
              html.contains("Error") ||
              html.contains("error code")) {
            throw "ERROR";
          } else {
            print("$i OK");
          }
        });
      }
      await scheduler.wait();
    },
    timeout: Timeout(Duration(hours: 1)),
  );

  test(
    "BiliNovel Image Rate",
    () async {
      // 图片无限制 不过还是控制速度
      Scheduler scheduler = Scheduler(1, Duration(seconds: 1));
      // 先等待半分钟 等RateLimit解除
      // await Future.delayed(Duration(seconds: 40));
      for (int i = 1; i <= 100; i++) {
        scheduler.run((_) async {
          Uint8List image = await httpGetBytes(
            "https://img3.readpai.com/2/2923/144358/170510.jpg",
            headers: {
              "Referer": BiliNovelSource.domain,
              "User-Agent": BiliNovelSource.userAgent,
              "Cache-Control": "public",
              "Accept-Language": "zh-CN,zh;q=0.9"
            },
          );
          String str = String.fromCharCodes(image);
          var unAuth = str.contains("403");
          var notFound = str.contains("404");
          var nginxErr = str.contains("nginx");
          if ((unAuth || notFound) && nginxErr) {
            throw "ERROR";
          } else {
            print("$i OK");
          }
        });
      }
      await scheduler.wait();
    },
    timeout: Timeout(Duration(hours: 1)),
  );

  test(
    "Wenku Rate",
    () async {
      // 无限制
      Scheduler scheduler = Scheduler(0, Duration(minutes: 1));
      // 先等待半分钟 等RateLimit解除
      // await Future.delayed(Duration(seconds: 40));
      for (int i = 1; i <= 100; i++) {
        scheduler.run((_) async {
          String html = await httpGetString(
            "",
            codec: gbk,
          );
          if (html.contains("nginx") ||
              html.contains("rate limited") ||
              html.contains("Error") ||
              html.contains("error code")) {
            throw "ERROR";
          } else {
            print("$i OK");
          }
        });
      }
      await scheduler.wait();
    },
    timeout: Timeout(Duration(hours: 1)),
  );

  test(
    "Wenku Image Rate",
    () async {
      // 图片无限制 不过还是控制速度
      Scheduler scheduler = Scheduler(1, Duration(seconds: 1));
      // Scheduler scheduler = Scheduler.unlimited();
      // 先等待半分钟 等RateLimit解除
      // await Future.delayed(Duration(seconds: 40));
      for (int i = 1; i <= 100; i++) {
        scheduler.run((_) async {
          Uint8List image = await httpGetBytes(
            "https://pic.wenku8.com/pictures/3/3762/157104/193649.jpg",
            headers: {
              "User-Agent": WenkuNovelSource.userAgent,
            },
          );
          String str = String.fromCharCodes(image);
          var unAuth = str.contains("403");
          var notFound = str.contains("404");
          var nginxErr = str.contains("nginx");
          if ((unAuth || notFound) && nginxErr) {
            throw "ERROR";
          } else {
            print("$i OK");
          }
        });
      }
      await scheduler.wait();
    },
    timeout: Timeout(Duration(hours: 1)),
  );
}
