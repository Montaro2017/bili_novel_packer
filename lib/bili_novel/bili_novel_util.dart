import 'bili_novel_model.dart';


Chapter? getPrevChapter(Catalog catalog, Chapter chapter) {
  List<Chapter> chapters = catalog.volumes
      .expand(
        (volume) => volume.chapters,
      )
      .toList();
  int pos = chapters.indexOf(chapter);
  if (pos < 1) return null;
  return chapters[pos - 1];
}

Chapter? getNextChapter(Catalog catalog, Chapter chapter) {
  List<Chapter> chapters = catalog.volumes
      .expand(
        (volume) => volume.chapters,
      )
      .toList();
  int pos = chapters.indexOf(chapter);
  if (pos < 0 || pos > chapters.length - 1) return null;
  return chapters[pos + 1];
}
