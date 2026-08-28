import 'package:bili_novel_packer/extension/node_wrap_extension.dart';
import 'package:html/dom.dart';

class HTMLUtil {
  static void _walk(Element root, Element? Function(Element e) handler) {
    if (root.children.isNotEmpty) {
      for (var child in root.children) {
        _walk(child, handler);
      }
    } else {
      var el = handler(root);
      if (el == null) {
        root.remove();
      } else {
        root.replaceWith(el);
      }
    }
  }

  static void removeElements(List<Element> elements) {
    for (var element in elements) {
      element.remove();
    }
  }

  static void removeLineBreak(Element element) {
    _walk(element, (e) {
      e.text = e.text.replaceAll("\n", "");
      return e;
    });
  }

  static void removeWhiteSpace(Element element) {
    String remove(String text) {
      for (var ws in _whiteSpaces) {
        text = text.replaceAll(ws, "");
      }
      return text;
    }

    _walk(element, (e) {
      e.text = remove(e.text);
      return e;
    });
  }

  static void wrapDuoKanImage(Element element) {
    var imgList = element.querySelectorAll("img");
    for (var img in imgList) {
      img.wrap('<div class="duokan-image-single"></div>');
    }
  }

  static void unwrap(Element element) {
    var childNodes = element.nodes;
    for (var childNode in childNodes) {
      element.parent!.insertBefore(childNode.clone(true), element);
    }
    element.remove();
  }

  static void removeElementsByPattern(
    Element element,
    String pattern, {
    bool matchId = false,
    bool matchTagName = true,
    bool matchClassName = false,
  }) {
    String id = element.id;
    String tagName = element.localName ?? '';
    String className = element.className;
    RegExp regExp = RegExp(pattern);
    if (matchId && regExp.hasMatch(id)) {
      element.remove();
      return;
    }
    if (matchTagName && regExp.hasMatch(tagName)) {
      element.remove();
      return;
    }
    if (matchClassName && regExp.hasMatch(className)) {
      element.remove();
      return;
    }
    if (element.children.isNotEmpty) {
      for (var e in element.children) {
        removeElementsByPattern(e, pattern);
      }
    }
  }

  static void unescape(Element element) {
    _walk(element, (e) {
      e.text = _unescape(e.text);
      return e;
    });
  }

  static String _unescape(String text) {
    _unescapeTable.forEach((key, value) {
      text = text.replaceAll(key, value);
    });
    return text;
  }
}

const List<String> _whiteSpaces = [
  "\u0020",
  "\u00A0",
  "\u2000",
  "\u2001",
  "\u2002",
  "\u2003",
  "\u2004",
  "\u2005",
  "\u2006",
  "\u2007",
  "\u2008",
  "\u2009",
  "\u200A",
  "\u200B",
  "\u200C",
  "\u200D",
  "\u200E",
  "\u200F",
  "\u2060",
  "\uFEFF",
  "\u180E",
  "\u202F",
  "\u205F",
  "\u3000",
];

const Map<String, String> _unescapeTable = {
  "&quot;": "\"",
  "＆quot;": "\"",
  "&amp;": "&",
  "＆amp;": "&",
  "&lt;": "<",
  "＆lt;": "<",
  "&gt;": ">",
  "＆gt;": ">",
  "&nbsp;": " ",
  "＆nbsp;": " ",
  "&middot;": "·",
  "＆middot;": "·",
  "&raquo;": "?",
  "＆raquo;": "?",
  "&frac14;": "?",
  "＆frac14;": "?",
  "&frac12;": "?",
  "＆frac12;": "?",
  "&frac34;": "?",
  "＆frac34;": "?",
  "&iquest;": "?",
  "＆iquest;": "?",
};
