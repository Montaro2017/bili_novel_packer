import 'package:bili_novel_packer/epub_packer/epub_node.dart';
import 'package:bili_novel_packer/util/sequence.dart';
import 'package:xml/xml.dart';

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

  void addNavPoint(NavPoint navPoint) {
    _navMap.addNavPoint(navPoint);
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
  final List<NavPoint> _navPointList = [];
  final Sequence _seq = Sequence();

  _NavMap(super.builder);

  void addNavPoint(NavPoint navPoint) {
    _navPointList.add(navPoint);
  }

  @override
  void build() {
    builder.element("navMap", nest: () {
      for (int i = 0; i < _navPointList.length; i++) {
        NavPoint navPoint = _navPointList[i];
        String id = "navPoint-${_seq.next}";
        _navPoint(navPoint, id);
      }
    });
  }

  void _navPoint(NavPoint navPoint, String id) {
    builder.element(
      "navPoint",
      attributes: {"id": id},
      nest: () {
        navLabel(navPoint.title);
        if (navPoint.src != null) {
          content(navPoint.src!);
        }
        Sequence seq = Sequence();
        for (var child in navPoint.children) {
          String childId = "$id-${seq.next}";
          _navPoint(child, childId);
        }
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

class NavPoint {
  String title;
  String? src;
  List<NavPoint> children = [];

  NavPoint(
    this.title, {
    this.src,
    children,
  }): children = children ?? [];

  void addChild(NavPoint navPoint) {
    children.add(navPoint);
  }
}
