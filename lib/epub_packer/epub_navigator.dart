import 'package:xml/xml.dart';
import 'package:bili_novel_packer/epub_packer/epub_node.dart';


/// toc.ncx
class EpubNavigator implements EpubNode {
  final XmlBuilder _builder = XmlBuilder();
  late final _Head _head;
  late final _DocTitle _docTitle;
  late final _NavMap _navMap;

  String get docTitle => _docTitle.docTitle;

  set docTitle(String docTitle) => _docTitle.docTitle = docTitle;

  String get bookUuid => _head.bookUuid;

  set bookUuid(String bookUuid) => _head.bookUuid = bookUuid;

  EpubNavigator() {
    _head = _Head(_builder);
    _docTitle = _DocTitle(_builder);
    _navMap = _NavMap(_builder);

    _builder.declaration(
      encoding: "UTF-8",
      attributes: {
        "standalone": "no",
      },
    );
  }

  void addNavMapItem(String title, String src) {
    _navMap.addNavMap(_NavMapItem(title, src));
  }

  @override
  XmlNode build() {
    _builder.element(
      "ncx",
      attributes: {
        "xmlns": "http://www.daisy.org/z3986/2005/ncx/",
      },
      nest: () {
        _head.build();
        _docTitle.build();
        _navMap.build();
      },
    );
    return _builder.buildDocument();
  }
}

class _Head extends EpubChildNode {

  // uuid
  late String bookUuid;

  _Head(super.builder);

  @override
  void build() {
    builder.element(
      "head",
      nest: () {
        builder.element(
          "meta",
          attributes: {
            "content": "urn:uuid:$bookUuid",
            "name": "dtb:uid",
          },
        );
        builder.element(
          "meta",
          attributes: {
            "content": "1",
            "name": "dtb:depth",
          },
        );
        builder.element(
          "meta",
          attributes: {
            "content": "0",
            "name": "dtb:totalPageCount",
          },
        );
        builder.element(
          "meta",
          attributes: {
            "content": "0",
            "name": "dtb:maxPageNumber",
          },
        );
      },
    );
  }
}

class _DocTitle extends EpubChildNode {
  late String docTitle;

  _DocTitle(super.builder);

  @override
  void build() {
    builder.element("docTitle", nest: () {
      builder.element("text", nest: docTitle);
    });
  }
}

class _NavMap extends EpubChildNode {
  final List<_NavMapItem> _itemList = [];

  _NavMap(super.builder);

  void addNavMap(_NavMapItem item) {
    _itemList.add(item);
  }

  @override
  void build() {
    builder.element("navMap", nest: () {
      for (int i = 0; i < _itemList.length; i++) {
        _NavMapItem item = _itemList[i];
        navPoint(item, i + 1);
      }
    });
  }

  void navPoint(_NavMapItem item, int order) {
    builder.element(
      "navPoint",
      attributes: {
        "id": "navPoint-$order",
        "playorder": "$order",
      },
      nest: () {
        navLabel(item.title);
        content(item.src);
      },
    );
  }

  void navLabel(String title) {
    builder.element("navLabel", nest: () {
      builder.element("text", nest: title);
    });
  }

  void content(String src) {
    builder.element(
      "content",
      attributes: {
        "src": src,
      },
    );
  }
}

class _NavMapItem {
  String title;
  String src;

  _NavMapItem(this.title, this.src);
}
