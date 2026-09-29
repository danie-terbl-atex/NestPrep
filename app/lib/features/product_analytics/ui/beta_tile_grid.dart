import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';

/// Beta number tiles side by side while they fit, then wrapping — all across,
/// then one fewer, down to one a row, never narrower than a minimum that grows
/// with the text setting, so 200% text wraps sooner instead of clipping
/// (`FE-13`, `FE-14`). The weekly numbers and the premium numbers share it
/// (`ENG-02`).
class BetaTileGrid extends StatelessWidget {
  const BetaTileGrid({required this.tiles, super.key});

  final List<Widget> tiles;

  /// Narrower than this at 100% text, tiles wrap rather than squeeze.
  static const _tileMinWidth = 88.0;

  @override
  Widget build(BuildContext context) {
    final minWidth = MediaQuery.textScalerOf(context).scale(_tileMinWidth);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = _tileWidth(
          available: constraints.maxWidth,
          count: tiles.length,
          minWidth: minWidth,
        );
        return Wrap(
          spacing: NestSpace.lg,
          runSpacing: NestSpace.lg,
          children: [
            for (final tile in tiles) SizedBox(width: width, child: tile),
          ],
        );
      },
    );
  }

  double _tileWidth({
    required double available,
    required int count,
    required double minWidth,
  }) {
    const gap = NestSpace.lg;
    for (var across = count; across > 1; across -= 1) {
      final width = (available - gap * (across - 1)) / across;
      if (width >= minWidth) return width;
    }
    return available;
  }
}
