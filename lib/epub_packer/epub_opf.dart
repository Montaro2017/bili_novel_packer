import 'package:bili_novel_packer/epub_packer/epub_node.dart';
import 'package:bili_novel_packer/media_type.dart' as media_type;
import 'package:xml/xml.dart';

/// content.opf
class EpubOpenPackageFormat implements EpubNode {
  final XmlBuilder _builder = XmlBuilder();

  late final MetaData metaData;
  late final Manifest manifest;
  late final Spine spine;
  String? _cover;

  String get bookUuid => metaData.bookUuid;

  set bookUuid(String bookUuid) => metaData.bookUuid = bookUuid;

  String get docTitle => metaData.docTitle;

  set docTitle(String docTitle) => metaData.docTitle = docTitle;

  String get creator => metaData.creator;

  set creator(String creator) => metaData.creator = creator;

  String? get cover => _cover;

  set cover(String? cover) {
    _cover = cover;
    manifest.cover = cover;
  }

  EpubOpenPackageFormat() {
    metaData = MetaData(_builder);
    manifest = Manifest(_builder);
    spine = Spine(_builder);
    _builder.declaration(encoding: "UTF-8");
  }

  void addImage(ManifestItem item) {
    manifest.addManifestItem(item);
  }

  void addChapter(ManifestItem item) {
    manifest.addManifestItem(item);
    spine.addRef(item.id);
  }

  @override
  XmlNode build() {
    _builder.element(
      "package",
      attributes: {
        "xmlns": "http://www.idpf.org/2007/opf",
        "xmlns:dc": "http://purl.org/dc/elements/1.1/",
        "unique-identifier": "bookId",
        "version": "2.0"
      },
      nest: () {
        metaData.build();
        manifest.build();
        spine.build();
      },
    );
    return _builder.buildDocument();
  }
}

class MetaData extends EpubChildNode {
  MetaData(super.builder);

  String? coverContent;
  String language = "zh-CN";
  String? source;
  String? description;
  String? publisher;
  List<String> subjects = [];
  late String bookUuid;
  late String docTitle;
  late String creator;

  @override
  void build() {
    builder.element("metadata", nest: () {
      builder.element(
        "dc:identifier",
        attributes: {"id": "bookId"},
        nest: bookUuid,
      );
      builder.element("dc:language", nest: language);
      builder.element("dc:title", nest: docTitle);
      builder.element("dc:creator", nest: creator);
      if (source != null) {
        builder.element("dc:source", nest: source);
      }
      if (description != null) {
        builder.element("dc:description", nest: description);
      }
      if (publisher != null) {
        builder.element("dc:publisher", nest: publisher);
      }
      if (subjects.isNotEmpty) {
        for (var subject in subjects) {
          builder.element("dc:subject", nest: subject);
        }
      }
      builder.element(
        "meta",
        attributes: {
          "name": "cover",
          "content": "cover-image",
        },
      );
    });
  }
}

class Manifest extends EpubChildNode {
  Manifest(super.builder);

  String? cover;

  final List<ManifestItem> _manifestList = [
    ManifestItem("ncx", "toc.ncx", media_type.ncx)
  ];

  void addManifestItem(ManifestItem item) {
    _manifestList.add(item);
  }

  @override
  void build() {
    builder.element(
      "manifest",
      nest: () {
        if (cover != null) {
          builder.element(
            "item",
            attributes: {
              "id": "cover-image",
              "href": cover!,
              "media-type": media_type.jpeg
            },
          );
        }
        for (ManifestItem item in _manifestList) {
          builder.element(
            "item",
            attributes: {
              "id": item.id,
              "href": item.href,
              "media-type": item.mediaType
            },
          );
        }
      },
    );
  }
}

class ManifestItem {
  String id;
  String href;
  String mediaType;

  ManifestItem(this.id, String href, this.mediaType)
      : href = href.replaceAll("\\", "/");
}

class Spine extends EpubChildNode {
  Spine(super.builder);

  List<String> refList = [];

  void addRef(String itemref) {
    refList.add(itemref);
  }

  @override
  void build() {
    builder.element(
      "spine",
      attributes: {
        "toc": "ncx",
      },
      nest: () {
        for (String idRef in refList) {
          builder.element(
            "itemref",
            attributes: {
              "idref": idRef,
            },
          );
        }
      },
    );
  }
}
