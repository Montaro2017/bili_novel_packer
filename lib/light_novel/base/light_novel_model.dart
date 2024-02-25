class Novel {
  // 网址
  String? url;

  // id
  late String id;

  // 书名
  late String title;

  // 作者
  late String author;

  // 连载状态
  late String status;

  // 封面图
  String? coverUrl;

  // 标签
  List<String>? tags;

  // 文库
  String? publisher;

  // 简介
  String? description;

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.writeln("书名: $title");
    sb.writeln("作者: $author");
    sb.writeln("状态: $status");
    if (tags != null && tags!.isNotEmpty) {
      sb.writeln("标签: $tags");
    }
    if (description != null) {
      sb.writeln(description);
    }
    return sb.toString();
  }
}

class Catalog {
  Novel novel;

  // 分卷列表
  List<Volume> volumes = [];

  Catalog(this.novel);
}

class Volume {
  // 卷名
  late String volumeName;

  // 所属目录
  Catalog catalog;

  // 章节列表
  List<Chapter> chapters = [];

  // 分卷封面
  String? cover;

  Volume(this.volumeName, this.catalog);

  @override
  String toString() {
    if (volumeName == "") {
      return catalog.novel.title;
    }
    return volumeName;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Volume &&
          runtimeType == other.runtimeType &&
          volumeName == other.volumeName;

  @override
  int get hashCode => volumeName.hashCode;
}

class Chapter {
  // 章节标题
  late String chapterName;

  // 章节URL
  String? chapterUrl;

  // 章节内容
  String? chapterContent;

  // 所属卷
  Volume volume;

  Chapter(this.chapterName, this.chapterUrl, this.volume);

  @override
  int get hashCode =>
      [chapterName, chapterUrl, volume.hashCode].toString().hashCode;

  @override
  bool operator ==(Object other) {
    if (other is! Chapter) return false;
    if (hashCode == other.hashCode) return true;
    return false;
  }
}
