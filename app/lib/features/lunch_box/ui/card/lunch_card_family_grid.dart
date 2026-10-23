import 'package:flutter/material.dart';

import '../../../../design/nest_kit.dart';
import '../../../../shared/copy/app_copy.dart';
import '../../model/lunch_card_content.dart';
import 'lunch_card_child_tag.dart';
import 'lunch_card_day_label.dart';
import 'lunch_card_family_cell.dart';
import 'lunch_card_layout.dart';
import 'lunch_card_text_fit.dart';

/// Every child's week on one card (lunch-box ADR-0005): a column per child
/// under their tag and a row per school day, each box drawn as big as its
/// cell allows. Two children leave room to name each day's main in its cell
/// — under the box, or beside it on a short row; three or four do not, and
/// what is in the boxes is listed under the grid instead.
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
    final namesInCells = children.length <= _maxChildrenWithNames;
    final days = children.first.days.length;
    return LayoutBuilder(
      builder: (context, constraints) => Column(
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
          for (var index = 0; index < days; index++) ...[
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
            _InTheBoxes(
              content: content,
              maxHeight: constraints.maxHeight - _heightBeside(nest, days),
            ),
          ],
          if (content.hiddenChildCount > 0)
            Text(
              LunchShareCopy.andMore(content.hiddenChildCount),
              style: nest.text.caption,
            ),
        ],
      ),
    );
  }

  /// Everything in the grid but the list under it, with each day's row as
  /// short as it gets while its name still shows whole: what the list may
  /// not take.
  double _heightBeside(NestTheme nest, int days) {
    final shortestRow = lineHeightOf(nest.text.title) + layout.rowInset * 2;
    final andMore = content.hiddenChildCount > 0
        ? lineHeightOf(nest.text.caption)
        : 0.0;
    return LunchCardChildTag.height +
        layout.gap +
        days * shortestRow +
        (days - 1) * layout.gap +
        layout.gap +
        andMore;
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
              child: LunchCardFamilyCell(
                day: child.days[dayIndex],
                showsName: namesInCells,
              ),
            ),
        ],
      ),
    ),
  );
}

/// Under a grid too narrow to name each box: everything in the week's boxes,
/// once each, in as much of the card as the rows can spare — shrinking to
/// say it all before any of it is cut off. A week with more in it than that
/// says each day's main instead, whole, rather than half of everything.
class _InTheBoxes extends StatelessWidget {
  const _InTheBoxes({required this.content, required this.maxHeight});

  final LunchCardContent content;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final style = nest.text.caption.copyWith(color: nest.colors.inkSecondary);
    TextSpan list(String label, List<String> names) => TextSpan(
      style: style,
      children: [
        TextSpan(
          text: '$label  ',
          style: nest.text.label.copyWith(color: nest.colors.accentInk),
        ),
        TextSpan(text: LunchShareCopy.itemList(names)),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final room = Size(constraints.maxWidth, maxHeight);
        double? fit(TextSpan span) => LunchCardTextFit.scaleFor(context, [
          (span: span, maxLines: null),
        ], room);
        var span = list(LunchShareCopy.inTheBoxes, content.itemNames);
        var scale = fit(span);
        if (scale == null) {
          span = list(LunchShareCopy.mains, content.mainNames);
          scale = fit(span);
        }
        final scaler = TextScaler.linear(scale ?? LunchCardTextFit.minScale);
        final lines = maxHeight ~/ scaler.scale(lineHeightOf(nest.text.label));
        return Text.rich(
          span,
          maxLines: scale != null ? null : (lines < 1 ? 1 : lines),
          overflow: scale != null ? null : TextOverflow.ellipsis,
          textScaler: scaler,
        );
      },
    );
  }
}
