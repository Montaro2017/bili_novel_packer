import 'package:archive/archive.dart';

ArchiveFile getContainer() {
  return ArchiveFile.string(
    "META-INF/container.xml",
    """<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
    <rootfiles>
        <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml" />
    </rootfiles>
</container>
""",
  );
}

ArchiveFile getMimeType() {
  return ArchiveFile.string(
    "mimetype",
    "application/epub+zip",
  )..compress = false;
}
