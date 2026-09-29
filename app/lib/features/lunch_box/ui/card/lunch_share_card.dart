import 'package:flutter/material.dart';

import '../../../../design/nest_kit.dart';

import '../../model/lunch_card_content.dart';
import '../../model/lunch_card_format.dart';
import '../../model/lunch_card_style.dart';
import 'lunch_card_backdrop.dart';
import 'lunch_card_day_row.dart';
import 'lunch_card_family_grid.dart';
import 'lunch_card_footer.dart';
import 'lunch_card_frame.dart';
import 'lunch_card_header.dart';
import 'lunch_card_layout.dart';
import 'lunch_card_palette.dart';

/// A week's lunches as the picture a parent posts (lunch-box ADR-0005): the
/// week and the nest at the top, a row per school day with the box drawn and
/// what is in it — or every child side by side — and the wordmark's
/// signature at the foot.
///
/// It is the same widget in the share screen's preview and in the exported
/// image, inside a `LunchCardFrame` that fixes its look and size, so what the
/// parent sees is what is sent.
class LunchShareCard extends StatelessWidget {
  const LunchShareCard({
    required this.content,
    required this.format,
    required this.style,
    required this.showsInvite,
    this.inviteHost,
    super.key,
  });

  final LunchCardContent content;
  final LunchCardFormat format;
  final LunchCardStyle style;
  final bool showsInvite;
  final String? inviteHost;

  @override
  Widget build(BuildContext context) {
    final palette = LunchCardPalette.of(style);
    final layout = LunchCardLayout.of(format);
    return LunchCardFrame(
      palette: palette,
      format: format,
      child: Stack(
        fit: StackFit.expand,
        children: [
          LunchCardBackdrop(palette: palette),
          Padding(
            padding: layout.padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LunchCardHeader(
                  content: content,
                  layout: layout,
                  surface: palette.rowSurface,
                ),
                SizedBox(height: layout.gap * 2),
                Expanded(
                  child: content.isFamily
                      ? LunchCardFamilyGrid(
                          content: content,
                          layout: layout,
                          surface: palette.rowSurface,
                        )
                      : _WeekRows(
                          content: content,
                          layout: layout,
                          surface: palette.rowSurface,
                        ),
                ),
                SizedBox(height: layout.gap + NestSpace.xs),
                LunchCardFooter(
                  layout: layout,
                  showsInvite: showsInvite,
                  inviteHost: inviteHost,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One child's five days, sharing the height between them.
class _WeekRows extends StatelessWidget {
  const _WeekRows({
    required this.content,
    required this.layout,
    required this.surface,
  });

  final LunchCardContent content;
  final LunchCardLayout layout;
  final Color surface;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (index, day) in content.children.first.days.indexed) ...[
        if (index > 0) SizedBox(height: layout.gap),
        Expanded(
          child: LunchCardDayRow(day: day, layout: layout, surface: surface),
        ),
      ],
    ],
  );
}
