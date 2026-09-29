import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../design/nest_kit.dart';
import '../../model/lunch_slot.dart';
import '../art/lunch_glyph.dart';

/// The brand on paper (lunch-box ADR-0005): the app's two faces, the nest,
/// the wordmark tinted forest green, and the light token set as PDF colours
/// — so a printed planner is plainly the same app as the screen (`FE-02`).
final class LunchPlannerKit {
  LunchPlannerKit._({
    required this.headingFont,
    required this.bodyFont,
    required this.strongFont,
    required this.mark,
    required this.wordmark,
  });

  static Future<LunchPlannerKit> load(AssetBundle bundle) async {
    Future<pw.Font> font(String path) async =>
        pw.Font.ttf(await bundle.load(path));
    final wordmark = await bundle.load(NestBrandAssets.wordmark);
    return LunchPlannerKit._(
      headingFont: await font('assets/fonts/Nunito-ExtraBold.ttf'),
      bodyFont: await font('assets/fonts/PlusJakartaSans-Regular.ttf'),
      strongFont: await font('assets/fonts/PlusJakartaSans-SemiBold.ttf'),
      mark: pw.MemoryImage(
        (await bundle.load(NestBrandAssets.mark)).buffer.asUint8List(),
      ),
      wordmark: pw.MemoryImage(
        _tinted(wordmark.buffer.asUint8List(), colors.accent),
      ),
    );
  }

  /// Paper is light: the light token set, always.
  static const colors = NestColors.light;

  final pw.Font headingFont;
  final pw.Font bodyFont;
  final pw.Font strongFont;
  final pw.MemoryImage mark;
  final pw.MemoryImage wordmark;

  static PdfColor pdf(Color color) => PdfColor.fromInt(color.toARGB32());

  PdfColor get ink => pdf(colors.ink);
  PdfColor get inkSecondary => pdf(colors.inkSecondary);
  PdfColor get inkTertiary => pdf(colors.inkTertiary);
  PdfColor get accent => pdf(colors.accent);
  PdfColor get accentSoft => pdf(colors.accentSoft);
  PdfColor get outline => pdf(colors.outline);
  PdfColor get outlineStrong => pdf(colors.outlineStrong);
  PdfColor get surface => pdf(colors.surface);

  /// A compartment's tint, as the drawn box paints it.
  PdfColor slotTint(LunchSlot slot) => pdf(slotFill(colors, slot));

  pw.TextStyle heading(double size) =>
      pw.TextStyle(font: headingFont, fontSize: size, color: accent);

  pw.TextStyle body(double size, {PdfColor? color}) =>
      pw.TextStyle(font: bodyFont, fontSize: size, color: color ?? ink);

  pw.TextStyle strong(double size, {PdfColor? color}) =>
      pw.TextStyle(font: strongFont, fontSize: size, color: color ?? ink);

  /// The wordmark is an alpha mask; the app tints it with `accent` as it
  /// draws, and paper cannot, so the colour is baked into a copy.
  static Uint8List _tinted(Uint8List png, Color color) {
    final decoded =
        img.decodePng(png) ?? (throw StateError('the wordmark is not a PNG'));
    final rgba = decoded.convert(numChannels: 4);
    final argb = color.toARGB32();
    final (r, g, b) = ((argb >> 16) & 0xFF, (argb >> 8) & 0xFF, argb & 0xFF);
    for (final pixel in rgba) {
      pixel
        ..r = r
        ..g = g
        ..b = b;
    }
    return img.encodePng(rgba);
  }
}
