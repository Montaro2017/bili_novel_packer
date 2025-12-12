import 'dart:math';

import 'package:bili_novel_packer/novel_source/base/novel_model.dart';
import 'package:bili_novel_packer/widget/novel_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NovelCardGridView extends StatelessWidget {
  final List<Novel> novels;
  final void Function(Novel novel)? onTap;

  const NovelCardGridView({
    super.key,
    required this.novels,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    var spacing = 16.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        var maxWidth = constraints.maxWidth;
        var itemBaseWidth = 350.0;
        var itemMinWidth = itemBaseWidth * 0.9;

        var baseItemCount = ((maxWidth + spacing) / (itemBaseWidth + spacing))
            .floor();
        var maxItemCount = ((maxWidth + spacing) / (itemMinWidth + spacing))
            .floor();
        var itemCount = max(baseItemCount, maxItemCount);
        if (itemCount < 1) itemCount = 1;
        var itemWidth = (maxWidth - spacing * (itemCount - 1)) / itemCount;

        if (baseItemCount < 1) baseItemCount = 1;
        if (kDebugMode) {
          print("itemCount = $baseItemCount, itemWidth = $itemWidth");
        }
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: novels
              .map((novel) => _novelCard(novel, itemWidth))
              .toList(),
        );
      },
    );
  }

  Widget _novelCard(Novel novel, double width) {
    return NovelCard(
      novel: novel,
      width: width,
      onTap: onTap != null
          ? () {
              onTap!(novel);
            }
          : null,
    );
  }
}
