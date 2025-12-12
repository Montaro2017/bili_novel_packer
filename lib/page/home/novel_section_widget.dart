import 'package:bili_novel_packer/novel_source/base/novel_model.dart';
import 'package:bili_novel_packer/widget/novel_card_grid.dart';
import 'package:flutter/material.dart';

class NovelSectionWidget extends StatelessWidget {
  final NovelSection novelSection;
  final void Function(Novel)? onTap;

  const NovelSectionWidget(this.novelSection, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (novelSection.name != null)
          Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              novelSection.name!,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
        NovelCardGridView(novels: novelSection.novels),
      ],
    );
  }
}
