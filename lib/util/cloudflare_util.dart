bool isCloudflareException(String html) {
  return isCloudflareError(html) || isCloudflareRateLimit(html);
}

bool isCloudflareRateLimit(String html) {
  return false;
}

bool isCloudflareError(String html) {
  return false;
}
