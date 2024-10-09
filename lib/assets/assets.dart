import 'package:archive/archive.dart';

ArchiveFile styleCss() {
  return ArchiveFile.string(
    "OEBPS/styles/style.css",
    """.chapter-title {
    margin-top: 0.5em!important;
    font-size: 1.25em!important;
    font-weight: 800!important;
    text-align: center!important;
  }""",
  );
}
