import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../design/nest_kit.dart';
import '../../model/lunch_slot.dart';
import '../art/lunch_glyph.dart';

/// The brand on paper (lunch-box ADR-0005, design-system ADR-0008): the two
/// faces, the arch mark and the wordmark, and the light token set as PDF
/// colours, so a printed planner is plainly the same app as the screen.
final class LunchPlannerKit {
  LunchPlannerKit._({
    required this.headingFont,
    required this.bodyFont,
    required this.strongFont,
    required this.markSvg,
  });

  static const markAsset = 'assets/brand/nest_mark.svg';

  static Future<LunchPlannerKit> load(AssetBundle bundle) async {
    Future<pw.Font> font(String path) async =>
        pw.Font.ttf(await bundle.load(path));
    return LunchPlannerKit._(
      headingFont: await font('assets/fonts/Fraunces-SemiBold.ttf'),
      bodyFont: await font('assets/fonts/DMSans-Regular.ttf'),
      strongFont: await font('assets/fonts/DMSans-SemiBold.ttf'),
      markSvg: await bundle.loadString(markAsset),
    );
  }

  static const colors = NestColors.light;

  final pw.Font headingFont;
  final pw.Font bodyFont;
  final pw.Font strongFont;
  final String markSvg;

  static PdfColor pdf(Color color) => PdfColor.fromInt(color.toARGB32());

  PdfColor get ink => pdf(colors.ink);
  PdfColor get inkSecondary => pdf(colors.inkSecondary);
  PdfColor get inkTertiary => pdf(colors.inkTertiary);
  PdfColor get accent => pdf(colors.accent);
  PdfColor get accentSoft => pdf(colors.accentSoft);
  PdfColor get outline => pdf(colors.outline);
  PdfColor get outlineStrong => pdf(colors.outlineStrong);
  PdfColor get surface => pdf(colors.surface);

  PdfColor slotTint(LunchSlot slot) => pdf(slotFill(colors, slot));

  pw.TextStyle heading(double size) =>
      pw.TextStyle(font: headingFont, fontSize: size, color: ink);

  pw.TextStyle body(double size, {PdfColor? color}) =>
      pw.TextStyle(font: bodyFont, fontSize: size, color: color ?? ink);

  pw.TextStyle strong(double size, {PdfColor? color}) =>
      pw.TextStyle(font: strongFont, fontSize: size, color: color ?? ink);

  pw.Widget mark(double size) =>
      pw.SvgImage(svg: markSvg, width: size, height: size);

  pw.Widget wordmark(double size) => pw.Text(
    'nestprep',
    style: heading(size).copyWith(letterSpacing: -size * 0.04),
  );
}
