import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_source.dart';
import 'package:bili_novel_packer/light_novel/bili_novel/bili_novel_source.dart';
import 'package:bili_novel_packer/pack_argument.dart';

class NovelPacker {
  static final List<LightNovelSource> sources = [
    BiliLightNovelSource(),
  ];

  String url;
  LightNovelSource lightNovelSource;

  late Novel novel;
  late Catalog catalog;

  NovelPacker._(this.lightNovelSource, this.url);

  factory NovelPacker.fromUrl(String url) {
    for (var source in sources) {
      if (source.supportUrl(url)) {
        return NovelPacker._(source, url);
      }
    }
    throw "Unsupported url: $url";
  }

  Future<Novel> getNovel() async {
    return lightNovelSource.getNovel(url).then((novel) => this.novel = novel);
  }

  Future<Catalog> getCatalog() async {
    return lightNovelSource
        .getNovelCatalog(novel)
        .then((catalog) => this.catalog = catalog);
  }

  void pack(PackArgument arg) {
    // TODO
  }

  void packVolume() {
    // TODO
  }
}
