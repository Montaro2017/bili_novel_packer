import 'package:html/dom.dart';

const List<String> selfClosingTags = ["meta", "br", "img", "hr", "input"];

extension NodeFormatExtension on Node {
  bool hasElement() {
    for (var node in nodes) {
      if (node is Element) {
        return true;
      }
      if (node.hasElement()) {
        return true;
      }
    }
    return false;
  }

  String format({
    int indentCount = 2,
    int indentLevel = 0,
    bool insertLineBreak = false,
  }) {
    if (this is Document) {
      return (this as Document).children[0].format(
            indentCount: indentCount,
            indentLevel: indentLevel,
            insertLineBreak: insertLineBreak,
          );
    }
    if (this is Text) {
      return text ?? "";
    }
    StringBuffer sb = StringBuffer();
    _NodeFormatter? formatter;
    formatter = _NodeFormatter.source(this);
    if (insertLineBreak) sb.write("\n");
    sb.write(" " * indentCount * indentLevel);
    sb.write(formatter.beforeFormatContent());
    bool contentLineBreak = false;
    if (nodes.isNotEmpty) {
      StringBuffer csb = StringBuffer();
      for (var node in nodes) {
        csb.write(
          node.format(
            indentCount: indentCount,
            indentLevel: indentLevel + 1,
            insertLineBreak: true,
          ),
        );
      }
      if (csb.isNotEmpty && hasElement()) {
        contentLineBreak = true;
      }
      sb.write(csb);
    }
    if (contentLineBreak) {
      sb.write("\n");
      sb.write(" " * indentCount * indentLevel);
    }
    sb.write(formatter.afterFormatContent());
    return sb.toString();
  }
}

abstract class _NodeFormatter {
  factory _NodeFormatter.source(Node source) {
    if (source is Element) {
      return _ElementFormatter(source);
    } else if (source is Comment) {
      return _CommentFormatter(source);
    } else if (source is DocumentType) {
      return _DocumentTypeFormatter(source);
    }
    throw "Unknown source ${source.runtimeType}";
  }

  String beforeFormatContent();

  String afterFormatContent();
}

class _ElementFormatter implements _NodeFormatter {
  Element source;

  _ElementFormatter(this.source);

  @override
  String beforeFormatContent() {
    StringBuffer sb = StringBuffer();
    sb.write("<");
    sb.write(source.localName);
    if (source.attributes.isNotEmpty) {
      source.attributes.forEach((key, value) {
        sb.write(" ");
        sb.write(key);
        sb.write("=");
        sb.write("\"");
        sb.write(value);
        sb.write("\"");
      });
    }
    if (source.localName == 'img') {
      sb.write("/");
    }
    sb.write(">");
    return sb.toString();
  }

  @override
  String afterFormatContent() {
    if (selfClosingTags.contains(source.localName)) {
      return "";
    }
    return "</${source.localName}>";
  }
}

class _CommentFormatter implements _NodeFormatter {
  Comment source;

  _CommentFormatter(this.source);

  @override
  String afterFormatContent() {
    return "-->";
  }

  @override
  String beforeFormatContent() {
    return "<!--${source.data}";
  }
}

class _DocumentTypeFormatter implements _NodeFormatter {
  DocumentType source;

  _DocumentTypeFormatter(this.source);

  @override
  String afterFormatContent() {
    return "";
  }

  @override
  String beforeFormatContent() {
    throw source.toString();
  }
}
