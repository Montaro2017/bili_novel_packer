import 'package:bili_novel_packer/light_novel/bili_novel/bili_novel_source.dart';

import 'package:bili_novel_packer/util/http_util.dart';

int codeLowerA = 'a'.codeUnitAt(0);
int codeLowerZ = 'z'.codeUnitAt(0);

int codeUpperA = 'A'.codeUnitAt(0);
int codeUpperZ = 'Z'.codeUnitAt(0);

class BiliNovelHelper {

  static Future<Map<String, String>> getSecretMap() async {
    String url = "${BiliNovelSource.domain}/themes/zhmb/js/readtool.js";
    String js = await HttpUtil.getString(url);
    String data = _extractData(js);
    String decryptJsCode = _decrypt(data);
    Map<String, String> secretMap = _toMap(decryptJsCode);
    return secretMap;
  }

  static String _extractData(String js) {
    String before = """['\\x61\\x70\\x70\\x6c\\x79'](null,\"""";
    String after = """"['\\x73\\x70\\x6c\\x69\\x74']""";
    int start = js.indexOf(before);
    int end = js.lastIndexOf(after);
    return js.substring(start + before.length, end);
  }

  static String _decrypt(String data) {
    String decryptData = "";
    String code = "";
    for (int i = 0; i < data.length; i++) {
      int charCode = data.codeUnitAt(i);
      if ((charCode >= codeUpperA && charCode <= codeUpperZ) ||
          (charCode >= codeLowerA && charCode <= codeLowerZ)) {
        decryptData += String.fromCharCode(int.parse(code));
        code = "";
      } else {
        code += data[i];
      }
    }
    return decryptData;
  }

  static Map<String, String> _toMap(String jsCode) {
    Map<String, String> map = {};
    jsCode = jsCode.replaceAll("'", '"');
    List<String> splits = jsCode.split(".replace");
    String prefix = "RegExp(\"";
    String suffix1 = "), \"";
    String suffix2 = "),\"";
    for (String split in splits) {
      int start = split.indexOf(prefix);
      if (start == -1) {
        continue;
      }
      String key =
          split.substring(start + prefix.length, start + prefix.length + 1);
      String suffix = suffix1;
      start = split.indexOf(suffix);
      if (start == -1) {
        suffix = suffix2;
        start = split.indexOf(suffix);
      }
      if (start == -1) {
        continue;
      }
      String value =
          split.substring(start + suffix.length, start + suffix.length + 1);
      map[key] = value;
    }
    return map;
  }

}
