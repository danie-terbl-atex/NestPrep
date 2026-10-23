import 'package:flutter/material.dart';

import '../../../../design/nest_kit.dart';
import '../../model/lunch_card_content.dart';
import '../art/lunch_box_art.dart';
import 'lunch_card_day_label.dart';
import 'lunch_card_day_words.dart';
import 'lunch_card_layout.dart';

/// One school day of one child's week on a card: the day, the box drawn
/// [artHeight] tall, and what is in it, all of it (`LunchCardDayWords`).
class LunchCardDayRow extends StatelessWidget {
  const LunchCardDayRow({
    required this.day,
    required this.layout,
    required this.surface,
    required this.artHeight,
    super.key,
  });

  final LunchCardDay day;
  final LunchCardLayout layout;
  final Color surface;
  final double artHeight;

  /// Everything across a row but its words, beside a box [artHeight] tall.
  static double widthBesideWords(double artHeight) =>
      NestSpace.md * 2 +
      LunchCardDayLabel.width +
      NestSpace.xs +
      artHeight * LunchBoxArt.aspect +
      NestSpace.md;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(NestRadius.md),
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: NestSpace.md,
        vertical: layout.rowInset,
      ),
      child: Row(
        children: [
          LunchCardDayLabel(date: day.date),
          const SizedBox(width: NestSpace.xs),
          LunchBoxArt(box: day.box, height: artHeight, isRaised: false),
          const SizedBox(width: NestSpace.md),
          Expanded(child: LunchCardDayWords(day: day)),
        ],
      ),
    ),
  );
}
