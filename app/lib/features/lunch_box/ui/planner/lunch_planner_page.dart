import 'package:pdf/widgets.dart' as pw;

import '../../../../design/nest_kit.dart';
import '../../../../shared/copy/app_copy.dart';
import '../../../../shared/format/nest_dates.dart';
import '../../model/lunch_card_content.dart';
import '../../model/lunch_slot.dart';
import '../../model/lunch_week.dart';
import 'lunch_planner_kit.dart';

/// One A4 page of the lunch planner (lunch-box ADR-0005): the title and the
/// nest, a grid of the five school days by the five compartments, then boxes
/// for Sunday prep and the shopping, and the wordmark's signature.
///
/// With a [child] the grid is their week, written in; without one every
/// cell is left with lines to write on — the free printable.
final class LunchPlannerPage {
  const LunchPlannerPage({
    required this.kit,
    required this.week,
    required this.child,
    required this.showsInvite,
    required this.inviteHost,
  });

  final LunchPlannerKit kit;
  final LunchWeek? week;
  final LunchCardChild? child;
  final bool showsInvite;
  final String? inviteHost;

  // Paper is measured in points, not the screen's logical pixels, so the
  // planner keeps its own few sizes here; its spacing and corners are still
  // the kit's.
  static const _titleSize = 26.0;
  static const _subtitleSize = 12.0;
  static const _boxTitleSize = 14.0;
  static const _labelSize = 11.0;
  static const _itemSize = 10.5;
  static const _footerSize = 9.0;
  static const _markWidth = 88.0;
  static const _wordmarkHeight = 14.0;
  static const _blankLineWidth = 180.0;
  static const _blankLineHeight = 14.0;
  static const _labelWidth = 64.0;
  static const _cellHeight = 78.0;
  static const _cellBorder = 1.5;
  static const _itemLines = 4;
  static const _writingLines = 2;
  static const _boxLines = 6;

  /// Any week names the days; a blank planner has no dates.
  static final _anyWeek = LunchWeek.parse('2026-W01');

  pw.Widget build() => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      _header(),
      pw.SizedBox(height: NestSpace.lg),
      _dayHeadings(),
      for (final slot in LunchSlot.values) ...[
        pw.SizedBox(height: NestSpace.xs),
        _slotRow(slot),
      ],
      pw.SizedBox(height: NestSpace.lg),
      pw.Expanded(
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Expanded(child: _writingBox(LunchShareCopy.plannerPrep)),
            pw.SizedBox(width: NestSpace.md),
            pw.Expanded(child: _writingBox(LunchShareCopy.plannerShopping)),
          ],
        ),
      ),
      pw.SizedBox(height: NestSpace.md),
      _footer(),
    ],
  );

  pw.Widget _header() {
    final week = this.week;
    final label = child?.label;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                LunchShareCopy.plannerTitle,
                style: kit.heading(_titleSize),
              ),
              pw.SizedBox(height: NestSpace.xs),
              week == null
                  ? _blankLine(LunchShareCopy.plannerWeekBlank)
                  : pw.Text(
                      LunchCopy.weekOf(NestDates.schoolWeekRange(week.monday)),
                      style: kit.strong(_subtitleSize, color: kit.inkSecondary),
                    ),
              pw.SizedBox(height: NestSpace.xs),
              if (week == null)
                _blankLine(LunchShareCopy.plannerForBlank)
              else if (label != null)
                pw.Text(
                  LunchShareCopy.packedFor(label),
                  style: kit.strong(_subtitleSize, color: kit.inkSecondary),
                ),
            ],
          ),
        ),
        pw.SizedBox(width: NestSpace.xxl),
        pw.Image(kit.mark, width: _markWidth),
      ],
    );
  }

  pw.Widget _blankLine(String label) => pw.Row(
    children: [
      pw.Text(label, style: kit.strong(_subtitleSize, color: kit.inkSecondary)),
      pw.SizedBox(width: NestSpace.sm),
      pw.Container(
        width: _blankLineWidth,
        height: _blankLineHeight,
        decoration: pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: kit.outlineStrong)),
        ),
      ),
    ],
  );

  pw.Widget _dayHeadings() => pw.Row(
    children: [
      pw.SizedBox(width: _labelWidth),
      for (var day = 1; day <= LunchWeek.schoolDayCount; day++)
        pw.Expanded(
          child: pw.Container(
            margin: const pw.EdgeInsets.only(left: NestSpace.xs),
            padding: const pw.EdgeInsets.symmetric(vertical: NestSpace.xs),
            decoration: pw.BoxDecoration(
              color: kit.accentSoft,
              borderRadius: pw.BorderRadius.circular(NestRadius.sm),
            ),
            alignment: pw.Alignment.center,
            child: pw.Text(_dayName(day), style: kit.strong(_labelSize)),
          ),
        ),
    ],
  );

  /// "Mon 28" for a filled week; "Mon" for a blank one.
  String _dayName(int isoWeekday) {
    final week = this.week;
    final date = (week ?? _anyWeek).dayOf(isoWeekday);
    final name = NestDates.weekday(date);
    return week == null ? name : '$name ${NestDates.dayOfMonth(date)}';
  }

  pw.Widget _slotRow(LunchSlot slot) => pw.SizedBox(
    height: _cellHeight,
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          width: _labelWidth,
          padding: const pw.EdgeInsets.all(NestSpace.sm),
          decoration: pw.BoxDecoration(
            color: kit.slotTint(slot),
            borderRadius: pw.BorderRadius.circular(NestRadius.sm),
          ),
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(
            LunchCopy.slotName(slot),
            style: kit.strong(_labelSize),
          ),
        ),
        for (var day = 1; day <= LunchWeek.schoolDayCount; day++)
          pw.Expanded(child: _cell(slot, day)),
      ],
    ),
  );

  pw.Widget _cell(LunchSlot slot, int isoWeekday) {
    final child = this.child;
    final name = child?.days[isoWeekday - 1].box[slot]?.name;
    return pw.Container(
      margin: const pw.EdgeInsets.only(left: NestSpace.xs),
      padding: const pw.EdgeInsets.all(NestSpace.sm),
      decoration: pw.BoxDecoration(
        color: kit.surface,
        border: pw.Border.all(color: kit.slotTint(slot), width: _cellBorder),
        borderRadius: pw.BorderRadius.circular(NestRadius.sm),
      ),
      child: child == null
          ? _lines(_writingLines)
          : pw.Text(
              name ?? '',
              style: kit.body(_itemSize),
              maxLines: _itemLines,
            ),
    );
  }

  pw.Widget _writingBox(String title) => pw.Container(
    padding: const pw.EdgeInsets.all(NestSpace.md),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: kit.outline, width: _cellBorder),
      borderRadius: pw.BorderRadius.circular(NestRadius.md),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(title, style: kit.heading(_boxTitleSize)),
        pw.SizedBox(height: NestSpace.xs),
        pw.Expanded(child: _lines(_boxLines)),
      ],
    ),
  );

  pw.Widget _lines(int count) => pw.Column(
    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
    children: [
      for (var line = 0; line < count; line++)
        pw.Container(
          height: _cellBorder,
          color: kit.outline,
          margin: const pw.EdgeInsets.only(top: NestSpace.md),
        ),
    ],
  );

  pw.Widget _footer() => pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
      pw.Text(
        '${LunchShareCopy.plannedWith} ',
        style: kit.body(_footerSize, color: kit.inkTertiary),
      ),
      pw.Image(kit.wordmark, height: _wordmarkHeight),
      pw.Spacer(),
      if (showsInvite)
        pw.Text(
          '${LunchShareCopy.planYours} · '
          '${inviteHost ?? LunchShareCopy.findTheApp}',
          style: kit.body(_footerSize, color: kit.inkTertiary),
        ),
    ],
  );
}
