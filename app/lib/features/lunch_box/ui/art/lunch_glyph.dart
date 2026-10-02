import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../design/nest_kit.dart';
import '../../model/lunch_slot.dart';

/// The little drawing that stands for a slot — a sandwich, an apple, veg
/// sticks, crackers, a cookie — so a box reads at a glance before anybody
/// reads a word (lunch-box ADR-0004). Drawn from tokens, never from hex
/// (`FE-02`), so it follows the brand and dark mode. Decorative: the slot's
/// name is always beside it, and it is silent to a screen reader.
class LunchGlyph extends StatelessWidget {
  const LunchGlyph({
    required this.slot,
    this.size = NestSize.iconLarge,
    super.key,
  });

  final LunchSlot slot;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: LunchGlyphPainter(
        slot: slot,
        colors: NestTheme.of(context).colors,
      ),
    ),
  );
}

/// The tile a slot's glyph sits on, tinted by the slot.
class LunchSlotTile extends StatelessWidget {
  const LunchSlotTile({
    required this.slot,
    this.size = NestSize.avatarMedium,
    this.isEmpty = false,
    super.key,
  });

  final LunchSlot slot;
  final double size;

  /// An empty slot is drawn quieter, so a full box stands out.
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = NestTheme.of(context).colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isEmpty ? colors.surfaceTint : slotFill(colors, slot),
        borderRadius: BorderRadius.circular(NestRadius.sm),
      ),
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: Opacity(
            opacity: isEmpty ? 0.45 : 1,
            child: LunchGlyph(slot: slot, size: size * 0.62),
          ),
        ),
      ),
    );
  }
}

/// The pastel a slot's compartment is painted.
Color slotFill(NestColors colors, LunchSlot slot) => switch (slot) {
  LunchSlot.main => colors.tileButter,
  LunchSlot.fruit => colors.tileGuava,
  LunchSlot.veg => colors.tileBasil,
  LunchSlot.snack => colors.tileLilac,
  LunchSlot.treat => colors.accentSoft,
};

class LunchGlyphPainter extends CustomPainter {
  const LunchGlyphPainter({required this.slot, required this.colors});

  final LunchSlot slot;
  final NestColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide;
    canvas.save();
    canvas.translate((size.width - unit) / 2, (size.height - unit) / 2);
    switch (slot) {
      case LunchSlot.main:
        _sandwich(canvas, unit);
      case LunchSlot.fruit:
        _apple(canvas, unit);
      case LunchSlot.veg:
        _vegSticks(canvas, unit);
      case LunchSlot.snack:
        _crackers(canvas, unit);
      case LunchSlot.treat:
        _cookie(canvas, unit);
    }
    canvas.restore();
  }

  Paint _fill(Color color) => Paint()..color = color;

  Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void _sandwich(Canvas canvas, double u) {
    final bread = Path()
      ..moveTo(u * 0.12, u * 0.82)
      ..lineTo(u * 0.5, u * 0.14)
      ..lineTo(u * 0.88, u * 0.82)
      ..close();
    canvas.drawPath(bread, _fill(colors.surface));
    canvas.drawLine(
      Offset(u * 0.24, u * 0.66),
      Offset(u * 0.76, u * 0.66),
      _stroke(colors.success, u * 0.09),
    );
    canvas.drawLine(
      Offset(u * 0.33, u * 0.52),
      Offset(u * 0.67, u * 0.52),
      _stroke(colors.danger, u * 0.08),
    );
    canvas.drawPath(bread, _stroke(colors.warning, u * 0.08));
  }

  void _apple(Canvas canvas, double u) {
    final body = Rect.fromCircle(
      center: Offset(u * 0.5, u * 0.58),
      radius: u * 0.32,
    );
    canvas.drawOval(body, _fill(colors.danger));
    canvas.drawCircle(
      Offset(u * 0.4, u * 0.48),
      u * 0.07,
      _fill(colors.surface.withValues(alpha: 0.55)),
    );
    canvas.drawLine(
      Offset(u * 0.5, u * 0.28),
      Offset(u * 0.54, u * 0.12),
      _stroke(colors.inkSecondary, u * 0.06),
    );
    final leaf = Path()
      ..moveTo(u * 0.55, u * 0.2)
      ..quadraticBezierTo(u * 0.78, u * 0.06, u * 0.84, u * 0.2)
      ..quadraticBezierTo(u * 0.7, u * 0.3, u * 0.55, u * 0.2)
      ..close();
    canvas.drawPath(leaf, _fill(colors.success));
  }

  void _vegSticks(Canvas canvas, double u) {
    final stick = _stroke(colors.success, u * 0.14);
    final tip = _fill(colors.warning);
    for (final (x, top) in [(0.3, 0.26), (0.5, 0.16), (0.7, 0.3)]) {
      canvas.drawLine(Offset(u * x, u * top), Offset(u * x, u * 0.84), stick);
      canvas.drawCircle(Offset(u * x, u * top), u * 0.07, tip);
    }
  }

  void _crackers(Canvas canvas, double u) {
    for (final centre in [
      Offset(u * 0.38, u * 0.42),
      Offset(u * 0.62, u * 0.62),
    ]) {
      canvas.drawCircle(centre, u * 0.26, _fill(colors.warningSoft));
      canvas.drawCircle(centre, u * 0.26, _stroke(colors.warning, u * 0.06));
      for (var i = 0; i < 3; i++) {
        final angle = i * 2 * math.pi / 3;
        canvas.drawCircle(
          centre + Offset(math.cos(angle), math.sin(angle)) * u * 0.1,
          u * 0.025,
          _fill(colors.warning),
        );
      }
    }
  }

  void _cookie(Canvas canvas, double u) {
    final centre = Offset(u * 0.5, u * 0.5);
    canvas.drawCircle(centre, u * 0.36, _fill(colors.warningSoft));
    canvas.drawCircle(centre, u * 0.36, _stroke(colors.warning, u * 0.06));
    for (final chip in const [
      Offset(0.38, 0.38),
      Offset(0.6, 0.34),
      Offset(0.44, 0.62),
      Offset(0.64, 0.58),
    ]) {
      canvas.drawCircle(
        Offset(u * chip.dx, u * chip.dy),
        u * 0.05,
        _fill(colors.ink),
      );
    }
  }

  @override
  bool shouldRepaint(LunchGlyphPainter oldDelegate) =>
      oldDelegate.slot != slot || oldDelegate.colors != colors;
}
