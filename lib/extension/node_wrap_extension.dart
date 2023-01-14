import 'package:html/dom.dart';

extension NodeWrapExtension on Node {
  void wrap(String html) {
    Node wrapNode = Element.html(html);
    replaceWith(wrapNode);
    wrapNode.append(this);
  }

  void unwrap() {
    if (parent == null) return;
    for (var child in children) {
      parent!.insertBefore(child, this);
    }
    remove();
  }

}