class URLUtil {
  static String getFileName(String url) {
    int start = url.lastIndexOf("/");
    int end = url.lastIndexOf("?");
    if (start < 0 && end < 0) {
      return url;
    }
    if (start < 0) {
      return url.substring(0, end);
    }
    if (end < 0) {
      return url.substring(start + 1);
    }
    return url.substring(start + 1, end);
  }

  static String resolve(String baseUrl, String relativeUrl) {
    if (relativeUrl == "./") {
      var pos = baseUrl.lastIndexOf("/");
      return baseUrl.substring(0, pos);
    }
    return baseUrl;
  }
}
