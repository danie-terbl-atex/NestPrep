import 'package:flutter/material.dart';

import '../tokens/nest_spacing.dart';

class NestPickGrid extends StatelessWidget {
  const NestPickGrid({
    required this.children,
    this.tileWidth = NestSize.pickTile,
    super.key,
  });

  final List<Widget> children;
  final double tileWidth;

  @override
  Widget build(BuildContext context) {
    final grow = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = (width / (tileWidth * grow)).floor().clamp(2, 6);
        final side = (width - NestSpace.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            for (final child in children) SizedBox(width: side, child: child),
          ],
        );
      },
    );
  }
}
