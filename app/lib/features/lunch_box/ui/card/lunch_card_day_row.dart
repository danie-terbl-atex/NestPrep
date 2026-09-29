import 'package:flutter/material.dart';

import '../../../../design/nest_kit.dart';
import '../../../../shared/copy/app_copy.dart';
import '../../model/lunch_card_content.dart';
import '../art/lunch_box_art.dart';
import 'lunch_card_day_label.dart';
import 'lunch_card_layout.dart';

/// One school day of one child's week on a card: the day, the box drawn as
/// tall as the row, and what is in it — the main, then as many lines of the
/// rest as the row has room for.
class LunchCardDayRow extends StatelessWidget {
  const LunchCardDayRow({
    required this.day,
    required this.layout,
    required this.surface,
    super.key,
  });

  final LunchCardDay day;
  final LunchCardLayout layout;
  final Color surface;

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
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            LunchCardDayLabel(date: day.date),
            const SizedBox(width: NestSpace.xs),
            LunchBoxArt(
              box: day.box,
              height: constraints.maxHeight,
              isRaised: false,
            ),
            const SizedBox(width: NestSpace.md),
            Expanded(child: _Items(day: day)),
          ],
        ),
      ),
    ),
  );
}

class _Items extends StatelessWidget {
  const _Items({required this.day});

  final LunchCardDay day;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final text = nest.text;
    final mainStyle = text.bodyStrong.copyWith(height: text.label.height);
    final sideStyle = text.caption.copyWith(color: nest.colors.inkSecondary);
    final names = day.itemNames;
    if (names.isEmpty) {
      return Text(LunchShareCopy.nothingPacked, style: text.caption);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final room = constraints.maxHeight - lineHeightOf(mainStyle);
        final lines = (room / lineHeightOf(sideStyle)).floor();
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              names.first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: mainStyle,
            ),
            // Flexible absorbs the rounding between a style's nominal
            // line height and the laid-out one.
            if (names.length > 1 && lines > 0)
              Flexible(
                child: Text(
                  LunchShareCopy.itemList(names.skip(1)),
                  maxLines: lines,
                  overflow: TextOverflow.ellipsis,
                  style: sideStyle,
                ),
              ),
          ],
        );
      },
    );
  }
}
