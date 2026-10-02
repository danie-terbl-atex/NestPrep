import 'package:flutter/material.dart';

import '../../../../design/nest_kit.dart';
import '../../model/lunch_box.dart';
import '../../model/lunch_slot.dart';
import 'lunch_box_art.dart';
import 'lunch_glyph.dart';

/// What fills a lunch's photo frame (design-system ADR-0010): the drawn box
/// on a warm ground tinted by its main, until a curated photo of that food
/// exists. Sizes itself to the frame it is given.
class LunchPhoto extends StatelessWidget {
  const LunchPhoto({required this.box, super.key});

  final LunchBox box;

  @override
  Widget build(BuildContext context) {
    final colors = NestTheme.of(context).colors;
    final lead = box.filled.isEmpty ? LunchSlot.fruit : box.filled.first.$1;
    return ColoredBox(
      color: slotFill(colors, lead),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = (constraints.maxHeight * 0.62).clamp(
            0.0,
            constraints.maxWidth * 0.8 / LunchBoxArt.aspect,
          );
          return Center(
            child: LunchBoxArt(box: box, height: height),
          );
        },
      ),
    );
  }
}
