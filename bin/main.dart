const String gitUrl = "https://gitee.com/Montaro2017/bili_novel_packer";
const String version = "0.1.0-beta-multi";

void main(List<String> args) async {
  printWelcome();
  // TODO
}

void printWelcome() {
  print("欢迎使用轻小说打包器!");
  print("作者: Sparks");
  print("当前版本: $version");
  print("如遇报错请先查看能否正常访问 https://w.linovelib.com");
  print("否则请至开源地址携带报错信息进行反馈: $gitUrl");
}
