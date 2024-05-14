/// neat reader 和 wps 显示不正常
/// 只会显示 &lt;和&gt;
const Map<String, String> escapeMap = {
  "<": "&lt;",
  ">": "&gt;",
};

String escape(String text) {
  for (var key in escapeMap.keys) {
    text = text.replaceAll(key, escapeMap[key]!);
  }
  return text;
}
