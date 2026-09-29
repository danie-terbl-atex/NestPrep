import 'package:flutter/widgets.dart';

import '../../../../design/nest_kit.dart';
import '../../model/lunch_card_format.dart';

/// How a card fills its format: its margins, where the logo goes, the
/// nest's size and the space between days. Every figure is a kit token
/// (`FE-02`); only the choice between them is the format's.
///
/// A story opens with the logo's lockup — the nest beside the wordmark —
/// above a full-width headline, and signs off with one quiet line. The
/// shorter formats have no height to spare, so the nest sits beside the
/// headline and the wordmark signs the foot.
@immutable
class LunchCardLayout {
  const LunchCardLayout._({
    required this.padding,
    required this.markWidth,
    required this.isStacked,
    required this.gap,
    required this.rowInset,
  });

  factory LunchCardLayout.of(LunchCardFormat format) => switch (format) {
    // A story's top and bottom sit under the app's own bars, so the words
    // keep clear of them (`LunchCardFormat.hasSafeZones`).
    LunchCardFormat.story => const LunchCardLayout._(
      padding: EdgeInsets.fromLTRB(
        NestSpace.xxl,
        NestSpace.huge,
        NestSpace.xxl,
        NestSpace.huge + NestSpace.sm,
      ),
      markWidth: NestSize.brandMarkSmall,
      isStacked: true,
      gap: NestSpace.sm,
      rowInset: NestSpace.xs,
    ),
    LunchCardFormat.chat => const LunchCardLayout._(
      padding: EdgeInsets.all(NestSpace.xxl),
      markWidth: NestSize.brandMarkSmall,
      isStacked: false,
      gap: NestSpace.sm,
      rowInset: NestSpace.xs,
    ),
    LunchCardFormat.post => const LunchCardLayout._(
      padding: EdgeInsets.all(NestSpace.xl),
      markWidth: NestSize.brandMarkSmall,
      isStacked: false,
      gap: NestSpace.xs,
      rowInset: NestSpace.xxs,
    ),
  };

  final EdgeInsets padding;

  /// The nest's width; never under the brand's 48-point floor.
  final double markWidth;

  /// The logo's lockup above a full-width headline, rather than the nest
  /// beside it.
  final bool isStacked;

  /// Between one day and the next.
  final double gap;

  /// Above and below the content of a day's row.
  final double rowInset;
}
