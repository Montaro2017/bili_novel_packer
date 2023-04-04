import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart';
import 'package:console/console.dart';

abstract class PackCallback {
  void beforePackVolume(Volume volume);

  void afterPackVolume(Volume volume);
}

class ConsolePackCallback implements PackCallback {
  LoadingBar loadingBar = LoadingBar();

  @override
  void beforePackVolume(Volume volume) {
    Console.write("正在打包 ${volume.volumeName}...");
    loadingBar.start();
  }

  @override
  void afterPackVolume(Volume volume) {
    Console.overwriteLine("打包完成 ${volume.volumeName}");
    loadingBar.stop();
    Console.write("\n");
    loadingBar = LoadingBar();
  }
}
