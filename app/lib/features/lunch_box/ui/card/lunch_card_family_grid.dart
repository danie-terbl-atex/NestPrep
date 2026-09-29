import 'package:flutter/material.dart';

import '../../../../design/nest_kit.dart';
import '../../../../shared/copy/app_copy.dart';
import '../../model/lunch_card_content.dart';
import '../art/lunch_box_art.dart';
import 'lunch_card_child_tag.dart';
import 'lunch_card_day_label.dart';
import 'lunch_card_layout.dart';

/// Every child's week on one card (lunch-box ADR-0005): a column per child
/// under their tag and a row per school day, each box drawn as big as its
/// cell allows. Two children leave room to name each day's main under its
/// box; three or four do not, and what is in the boxes is listed under the
/// grid instead.
class LunchCardFamilyGrid extends StatelessWidget {
  const LunchCardFamilyGrid({
    required this.content,
    required this.layout,
    required this.surface,
    super.key,
  });

  final LunchCardContent content;
  final LunchCardLayout layout;
  final Color surface;

  static const _maxChildrenWithNames = 2;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final children = content.children;
    final namesInCells =
        layout.isStacked && children.length <= _maxChildrenWithNames;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const SizedBox(width: LunchCardDayLabel.width + NestSpace.md),
            for (final child in children)
              Expanded(
                child: Center(
                  child: LunchCardChildTag(
                    child: child,
                    surface: surface,
                    text: child.isFirstName ? child.label : null,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: layout.gap),
        for (var index = 0; index < children.first.days.length; index++) ...[
          if (index > 0) SizedBox(height: layout.gap),
          Expanded(
            child: _DayRow(
              dayIndex: index,
              content: content,
              layout: layout,
              surface: surface,
              namesInCells: namesInCells,
            ),
          ),
        ],
        if (!namesInCells) ...[
          SizedBox(height: layout.gap),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${LunchShareCopy.inTheBoxes}  ',
                  style: nest.text.label.copyWith(color: nest.colors.accentInk),
                ),
                TextSpan(text: LunchShareCopy.itemList(content.itemNames)),
              ],
            ),
            maxLines: layout.isStacked ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: nest.text.caption.copyWith(color: nest.colors.inkSecondary),
          ),
        ],
        if (content.hiddenChildCount > 0)
          Text(
            LunchShareCopy.andMore(content.hiddenChildCount),
            style: nest.text.caption,
          ),
      ],
    );
  }
}

/// One school day across every child.
class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.dayIndex,
    required this.content,
    required this.layout,
    required this.surface,
    required this.namesInCells,
  });

  final int dayIndex;
  final LunchCardContent content;
  final LunchCardLayout layout;
  final Color surface;
  final bool namesInCells;

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
          LunchCardDayLabel(date: content.children.first.days[dayIndex].date),
          for (final child in content.children)
            Expanded(
              child: _Cell(day: child.days[dayIndex], showsName: namesInCells),
            ),
        ],
      ),
    ),
  );
}

/// One child's box on one day, drawn as big as the cell allows — with the
/// day's main under it, when there is room to say it.
class _Cell extends StatelessWidget {
  const _Cell({required this.day, required this.showsName});

  final LunchCardDay day;
  final bool showsName;

  /// Smaller than this and the compartments stop reading as a box.
  static const _minArtHeight = NestSize.avatarSmall;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final style = nest.text.caption.copyWith(color: nest.colors.inkSecondary);
    final main = day.itemNames.firstOrNull;
    return LayoutBuilder(
      builder: (context, cell) {
        final nameHeight = lineHeightOf(style);
        // The room for a name is kept on a day with nothing packed too, so
        // every box in a row is the same size.
        final named = showsName && cell.maxHeight - nameHeight >= _minArtHeight;
        final room = named ? cell.maxHeight - nameHeight : cell.maxHeight;
        final byWidth = (cell.maxWidth - NestSpace.sm) / LunchBoxArt.aspect;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: NestSpace.xs),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LunchBoxArt(
                box: day.box,
                height: byWidth < room ? byWidth : room,
                isRaised: false,
              ),
              // Flexible absorbs the rounding between a style's nominal line
              // height and the laid-out one.
              if (named && main != null)
                Flexible(
                  child: Text(
                    main,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
