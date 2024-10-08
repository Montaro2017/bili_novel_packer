import 'package:bili_novel_packer/util/url_util.dart';
import 'package:test/test.dart';

void main() {
  test("URLUtil.getFileName", () {
    print(
      URLUtil.getFileName(
          "https://img2023.cnblogs.com/blog/600147/202303/600147-20230329180517632-1154021792.png?abc=123"),
    );
  });
}
