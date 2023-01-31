import 'package:html/dom.dart';

class Novel {
  late int id;
  late String title;
  late String status;
  late List<String> tags;
  late String coverUrl;
  late String author;
  late String description;

  @override
  String toString() {
    return "id = $id\ntitle = $title\nstatus = $status\ntags = $tags\ncoverUrl = $coverUrl\nauthor = $author\ndescription = $description";
  }
}

class Catalog {
  List<Volume> volumes = [];

  @override
  String toString() {
    return volumes.map((e) => e.toString()).join("\n");
  }
}

class Volume {
  String name;
  List<Chapter> chapters = [];

  Volume(this.name);

  @override
  String toString() {
    return "Volume(name = $name)\n${chapters.map((e) => "\t$e").join("\n")}";
  }
}

class Chapter {
  late String name;
  late String? url;

  Chapter(this.name, [this.url]);

  @override
  String toString() {
    return "Chapter(name = $name, url = $url)";
  }

  @override
  int get hashCode => [name, url].toString().hashCode;

  @override
  bool operator ==(Object other) {
    if (other is! Chapter) return false;
    if (hashCode == other.hashCode) return true;
    return false;
  }
}

class ChapterPage {
  List<Element> contents;
  String? prevPageUrl;
  String? nextPageUrl;
  String? prevChapterUrl;
  String? nextChapterUrl;

  ChapterPage(
    this.contents, {
    this.prevPageUrl,
    this.nextPageUrl,
    this.prevChapterUrl,
    this.nextChapterUrl,
  });
}
