import 'package:flutter/material.dart';

import '../../../../design/nest_kit.dart';
import '../../model/lunch_card_content.dart';
import '../art/lunch_box_art.dart';
import 'lunch_card_day_label.dart';
import 'lunch_card_text_fit.dart';

/// One child's box on one day of a family card, drawn as big as the cell
/// allows — with the day's main, whole, when [showsName]: under the box in a
/// tall cell, beside it in a short one (lunch-box ADR-0005).
class LunchCardFamilyCell extends StatelessWidget {
  const LunchCardFamilyCell({
    required this.day,
    required this.showsName,
    super.key,
  });

  final LunchCardDay day;
  final bool showsName;

  /// Smaller than this and the compartments stop reading as a box.
  static const _minArtHeight = NestSize.avatarSmall;

  /// Narrower than this beside a box and a main is a word a line.
  static const _minNameWidth = NestSize.controlLarge;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final style = nest.text.caption.copyWith(color: nest.colors.inkSecondary);
    final main = day.itemNames.firstOrNull;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: NestSpace.xs),
      child: LayoutBuilder(
        builder: (context, cell) {
          final byWidth = cell.maxWidth / LunchBoxArt.aspect;
          // The room for a name is kept on a day with nothing packed too, and
          // decided by the cell alone, so every box in a row is the same size.
          final under = showsName
              ? _nameRoomUnder(style, cell.maxHeight)
              : null;
          if (under != null) {
            return _Under(
              day: day,
              main: main,
              style: style,
              nameHeight: under,
              artHeight: _smaller(byWidth, cell.maxHeight - under),
            );
          }
          // Beside the box, which gives up width for the name, down to the
          // smallest that still reads as a box.
          final besideBox =
              (cell.maxWidth - NestSpace.sm - _minNameWidth) /
              LunchBoxArt.aspect;
          final named = showsName && besideBox >= _minArtHeight;
          final artHeight = _smaller(
            named ? besideBox : byWidth,
            cell.maxHeight,
          );
          final art = LunchBoxArt(
            box: day.box,
            height: artHeight,
            isRaised: false,
          );
          if (!named) return Center(child: art);
          return Row(
            children: [
              art,
              const SizedBox(width: NestSpace.sm),
              if (main != null)
                Expanded(
                  child: _FittedName(
                    name: main,
                    style: style,
                    room: Size(
                      cell.maxWidth -
                          artHeight * LunchBoxArt.aspect -
                          NestSpace.sm,
                      cell.maxHeight,
                    ),
                    maxLines: null,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// The height a name under the box takes — at its designed size, or at
  /// the smallest — or null when neither leaves a box that reads as one.
  static double? _nameRoomUnder(TextStyle style, double cellHeight) {
    for (final scale in const [1.0, LunchCardTextFit.minScale]) {
      final height = TextScaler.linear(scale).scale(lineHeightOf(style));
      if (cellHeight - height >= _minArtHeight) return height;
    }
    return null;
  }

  static double _smaller(double a, double b) => a < b ? a : b;
}

/// The box with its main on one line under it, in [nameHeight].
class _Under extends StatelessWidget {
  const _Under({
    required this.day,
    required this.main,
    required this.style,
    required this.nameHeight,
    required this.artHeight,
  });

  final LunchCardDay day;
  final String? main;
  final TextStyle style;
  final double nameHeight;
  final double artHeight;

  @override
  Widget build(BuildContext context) {
    final main = this.main;
    return LayoutBuilder(
      builder: (context, cell) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LunchBoxArt(box: day.box, height: artHeight, isRaised: false),
          // Flexible absorbs the rounding between a style's nominal line
          // height and the laid-out one.
          if (main != null)
            Flexible(
              child: _FittedName(
                name: main,
                style: style,
                room: Size(cell.maxWidth, nameHeight),
                maxLines: 1,
              ),
            ),
        ],
      ),
    );
  }
}

/// A main in type shrunk to say it whole in [room]; at the smallest type,
/// as much of it as fits.
class _FittedName extends StatelessWidget {
  const _FittedName({
    required this.name,
    required this.style,
    required this.room,
    required this.maxLines,
  });

  final String name;
  final TextStyle style;
  final Size room;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final scale = LunchCardTextFit.scaleFor(context, [
      (span: TextSpan(text: name, style: style), maxLines: maxLines),
    ], room);
    final scaler = TextScaler.linear(scale ?? LunchCardTextFit.minScale);
    final lines = room.height ~/ scaler.scale(lineHeightOf(style));
    return Text(
      name,
      maxLines: maxLines ?? (scale != null ? null : (lines < 1 ? 1 : lines)),
      overflow: scale != null ? null : TextOverflow.ellipsis,
      textScaler: scaler,
      style: style,
    );
  }
}
