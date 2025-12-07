extension StringExtension on String {
  String? subBetween(String before, String after) {
    var start = indexOf(before);
    var end = indexOf(after);
    if (start == -1 || end == -1) {
      return null;
    }
    start = start + before.length;
    return substring(start, end);
  }
}
