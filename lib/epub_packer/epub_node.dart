import 'package:xml/xml.dart';

abstract class EpubNode {
  XmlNode build();
}

abstract class EpubChildNode {

  final XmlBuilder builder;

  EpubChildNode(this.builder);

  void build();
}
