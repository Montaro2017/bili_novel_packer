import 'package:bili_novel_packer/extension/node_wrap_extension.dart';
import 'package:html/dom.dart';

class HTMLUtil {
  static void removeElements(List<Element> elements) {
    for (var element in elements) {
      element.remove();
    }
  }

  static void removeLineBreak(Element element) {
    if (element.children.isNotEmpty) {
      for (var child in element.children) {
        removeLineBreak(child);
      }
    } else {
      element.text = element.text.replaceAll("\n", "");
    }
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
}
