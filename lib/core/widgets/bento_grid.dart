import 'package:flutter/material.dart';

enum BentoSize { small, wide, tall }

class BentoTile {
  const BentoTile({
    required this.child,
    this.size = BentoSize.small,
  });

  final Widget child;
  final BentoSize size;
}

class BentoGrid extends StatelessWidget {
  const BentoGrid({
    super.key,
    required this.tiles,
    this.spacing = 12,
    this.crossAxisCount = 2,
  });

  final List<BentoTile> tiles;
  final double spacing;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth =
            (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                crossAxisCount;
        final tileHeight = tileWidth; // 1:1 base aspect ratio

        final children = <Widget>[];
        for (final tile in tiles) {
          double w, h;
          switch (tile.size) {
            case BentoSize.small:
              w = tileWidth;
              h = tileHeight;
            case BentoSize.wide:
              w = tileWidth * 2 + spacing;
              h = tileHeight;
            case BentoSize.tall:
              w = tileWidth;
              h = tileHeight * 2 + spacing;
          }
          children.add(
            SizedBox(width: w, height: h, child: tile.child),
          );
        }

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children,
        );
      },
    );
  }
}
