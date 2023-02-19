import 'package:bili_novel_packer/epub_packer/epub_node.dart';
import 'package:bili_novel_packer/media_type.dart' as media_type;
import 'package:xml/xml.dart';

/// content.opf
class EpubOpenPackageFormat implements EpubNode {
  final XmlBuilder _builder = XmlBuilder();

  late final _MetaData _metaData;
  late final _Manifest _manifest;
  late final _Spine _spine;
  String? _cover;

  String get bookUuid => _metaData.bookUuid;

  set bookUuid(String bookUuid) => _metaData.bookUuid = bookUuid;

  String get docTitle => _metaData.docTitle;

  set docTitle(String docTitle) => _metaData.docTitle = docTitle;

  String get creator => _metaData.creator;

  set creator(String creator) => _metaData.creator = creator;

  String? get cover => _cover;

  set cover(String? cover) {
    _cover = cover;
    _manifest.cover = cover;
  }

  EpubOpenPackageFormat() {
    _metaData = _MetaData(_builder);
    _manifest = _Manifest(_builder);
    _spine = _Spine(_builder);
    _builder.declaration(encoding: "UTF-8");
  }

  void addImage(ManifestItem item) {
    _manifest.addManifestItem(item);
  }

  void addChapter(ManifestItem item) {
    _manifest.addManifestItem(item);
    _spine.addRef(item.id);
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
        _metaData.build();
        _manifest.build();
        _spine.build();
      },
    );
    return _builder.buildDocument();
  }
}

class _MetaData extends EpubChildNode {
  _MetaData(super.builder);

  String? coverContent;
  String language = "zh-CN";
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

class _Manifest extends EpubChildNode {
  _Manifest(super.builder);

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

class _Spine extends EpubChildNode {
  _Spine(super.builder);

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
