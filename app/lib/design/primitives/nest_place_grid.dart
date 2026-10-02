import 'package:flutter/material.dart';

import '../tokens/nest_spacing.dart';

/// Place tiles laid out two to a row on a phone, more on a wider screen, every
/// tile in a row as tall as the tallest so the grid reads as one surface
/// (`FE-14`). It is a column, not a scrolling grid: it sits inside the
/// screen's own list.
class NestPlaceGrid extends StatelessWidget {
  const NestPlaceGrid({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / NestSize.placeTileMaxWidth)
            .ceil()
            .clamp(2, 4);
        final rows = <Widget>[];
        for (var start = 0; start < children.length; start += columns) {
          if (rows.isNotEmpty) {
            rows.add(const SizedBox(height: NestSpace.md));
          }
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < columns; i++) ...[
                    if (i > 0) const SizedBox(width: NestSpace.md),
                    Expanded(
                      child: start + i < children.length
                          ? children[start + i]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }
}
