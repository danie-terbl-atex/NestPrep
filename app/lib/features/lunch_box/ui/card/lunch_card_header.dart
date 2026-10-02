import 'package:flutter/material.dart';

import '../../../../design/nest_kit.dart';
import '../../../../shared/copy/app_copy.dart';
import '../../../../shared/format/nest_dates.dart';
import '../../model/lunch_card_content.dart';
import 'lunch_card_child_tag.dart';
import 'lunch_card_layout.dart';

/// The top of a card: the logo, the school week, the headline, and whose
/// box it is when the parent chose to say (lunch-box ADR-0005).
///
/// The logo keeps the brand's clear space — a quarter of the nest's width —
/// and is drawn only through the kit.
class LunchCardHeader extends StatelessWidget {
  const LunchCardHeader({
    required this.content,
    required this.layout,
    required this.surface,
    super.key,
  });

  final LunchCardContent content;
  final LunchCardLayout layout;

  /// What the child's tag sits on — the same as each day's row.
  final Color surface;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final clearSpace = layout.markWidth / 4;
    final titles = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _WeekLine(content: content, surface: surface),
        const SizedBox(height: NestSpace.xxs),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            LunchShareCopy.headline,
            maxLines: 1,
            style: layout.isStacked ? nest.text.display : nest.text.headline,
          ),
        ),
      ],
    );
    if (!layout.isStacked) {
      return Row(
        children: [
          Expanded(child: titles),
          SizedBox(width: clearSpace),
          NestBrandMark(size: layout.markWidth),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            NestBrandMark(size: layout.markWidth),
            SizedBox(width: clearSpace),
            const NestWordmark(
              semanticsLabel: LunchShareCopy.plannedWithNestPrep,
              size: NestSize.wordmarkSmall,
            ),
          ],
        ),
        SizedBox(height: clearSpace),
        titles,
      ],
    );
  }
}

/// The school week's dates, and the child's tag beside them when the card
/// is one child's and the parent chose to name them.
class _WeekLine extends StatelessWidget {
  const _WeekLine({required this.content, required this.surface});

  final LunchCardContent content;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final only = content.isFamily ? null : content.children.firstOrNull;
    final label = only?.label;
    return Row(
      children: [
        Text(
          NestDates.schoolWeekRange(content.week.monday),
          maxLines: 1,
          style: nest.text.label.copyWith(color: nest.colors.accentInk),
        ),
        if (only != null && label != null) ...[
          const SizedBox(width: NestSpace.md),
          Flexible(
            child: LunchCardChildTag(
              child: only,
              surface: surface,
              text: only.isFirstName ? label : null,
            ),
          ),
        ],
      ],
    );
  }
}
