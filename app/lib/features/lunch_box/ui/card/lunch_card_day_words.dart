import 'package:flutter/material.dart';

import '../../../../design/nest_kit.dart';
import '../../../../shared/copy/app_copy.dart';
import '../../model/lunch_card_content.dart';
import 'lunch_card_day_label.dart';
import 'lunch_card_text_fit.dart';

/// What is in one day's box, in words on a card: the main, then the rest
/// under it — or, on a row too short for that, all in one run, the main
/// first. The type shrinks to the room before anything is cut off
/// (lunch-box ADR-0005); only past the smallest type does an ellipsis say
/// there was more.
class LunchCardDayWords extends StatelessWidget {
  const LunchCardDayWords({required this.day, super.key});

  final LunchCardDay day;

  /// The main may wrap once rather than shrink past reading.
  static const _mainLines = 2;

  /// Whether every word of [day] fits [room] at some scale.
  static bool fits(BuildContext context, LunchCardDay day, Size room) =>
      _Words.of(context, day)?.fitIn(context, room) != null ||
      day.itemNames.isEmpty;

  @override
  Widget build(BuildContext context) {
    final words = _Words.of(context, day);
    if (words == null) {
      return Text(
        LunchShareCopy.nothingPacked,
        style: NestTheme.of(context).text.caption,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final fit = words.fitIn(context, constraints.biggest);
        if (fit case (final scale, false)) {
          return _Stacked(words: words, scale: scale);
        }
        final scale = fit?.$1;
        final scaler = TextScaler.linear(scale ?? LunchCardTextFit.minScale);
        final lines =
            constraints.maxHeight ~/
            scaler.scale(lineHeightOf(words.mainStyle));
        return Align(
          alignment: Alignment.centerLeft,
          child: Text.rich(
            words.runOn,
            maxLines: scale != null ? null : (lines < 1 ? 1 : lines),
            overflow: scale != null ? null : TextOverflow.ellipsis,
            textScaler: scaler,
          ),
        );
      },
    );
  }
}

/// A day's words as the spans a card draws them in.
class _Words {
  _Words(this.main, this.sides, this.mainStyle);

  static _Words? of(BuildContext context, LunchCardDay day) {
    final names = day.itemNames;
    if (names.isEmpty) return null;
    final nest = NestTheme.of(context);
    final mainStyle = nest.text.bodyStrong.copyWith(
      height: nest.text.label.height,
    );
    return _Words(
      TextSpan(text: names.first, style: mainStyle),
      names.length > 1
          ? TextSpan(
              text: LunchShareCopy.itemList(names.skip(1)),
              style: nest.text.caption.copyWith(
                color: nest.colors.inkSecondary,
              ),
            )
          : null,
      mainStyle,
    );
  }

  final TextSpan main;
  final TextSpan? sides;
  final TextStyle mainStyle;

  TextSpan get runOn {
    final sides = this.sides;
    return TextSpan(
      children: [
        main,
        if (sides != null) ...[
          TextSpan(text: LunchShareCopy.itemSeparator, style: sides.style),
          sides,
        ],
      ],
    );
  }

  /// The scale every word fits [room] at, and whether that is in one run —
  /// stacked preferred — or null when neither fits.
  (double, bool)? fitIn(BuildContext context, Size room) {
    final sides = this.sides;
    final stacked = LunchCardTextFit.scaleFor(context, [
      (span: main, maxLines: LunchCardDayWords._mainLines),
      if (sides != null) (span: sides, maxLines: null),
    ], room);
    if (stacked != null) return (stacked, false);
    final runOn = LunchCardTextFit.scaleFor(context, [
      (span: this.runOn, maxLines: null),
    ], room);
    return runOn == null ? null : (runOn, true);
  }
}

/// The main on its own line or two, and the rest under it.
class _Stacked extends StatelessWidget {
  const _Stacked({required this.words, required this.scale});

  final _Words words;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final scaler = TextScaler.linear(scale);
    final sides = words.sides;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          words.main,
          maxLines: LunchCardDayWords._mainLines,
          textScaler: scaler,
        ),
        // Flexible absorbs the rounding between the measured height and the
        // laid-out one.
        if (sides != null)
          Flexible(child: Text.rich(sides, textScaler: scaler)),
      ],
    );
  }
}
