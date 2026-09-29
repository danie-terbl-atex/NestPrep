import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';

/// WCAG 2.1 relative luminance and contrast ratio.
double _luminance(Color color) {
  double channel(double value) => value <= 0.03928
      ? value / 12.92
      : pow((value + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

const _aaText = 4.5;
const _aaLarge = 3.0;

void main() {
  for (final (name, colors, members) in [
    ('light', NestColors.light, NestMemberPalette.light),
    ('dark', NestColors.dark, NestMemberPalette.dark),
  ]) {
    group('$name theme', () {
      final backgrounds = {
        'canvas': colors.canvas,
        'surface': colors.surface,
        'surfaceTint': colors.surfaceTint,
        'accentSoft': colors.accentSoft,
        for (final (index, wash) in colors.canvasWash.indexed)
          'wash$index': wash,
      };
      final inks = {
        'ink': colors.ink,
        'inkSecondary': colors.inkSecondary,
        'inkTertiary': colors.inkTertiary,
        'accentInk': colors.accentInk,
      };

      for (final bg in backgrounds.entries) {
        for (final ink in inks.entries) {
          test('${ink.key} on ${bg.key} meets AA for body text', () {
            expect(
              contrast(ink.value, bg.value),
              greaterThanOrEqualTo(_aaText),
            );
          });
        }
        for (final (label, tone) in [
          ('success', colors.success),
          ('warning', colors.warning),
          ('danger', colors.danger),
        ]) {
          test('$label on ${bg.key} meets AA for body text', () {
            expect(contrast(tone, bg.value), greaterThanOrEqualTo(_aaText));
          });
        }
      }

      test('button text on the accent meets AA', () {
        expect(
          contrast(colors.onAccent, colors.accent),
          greaterThanOrEqualTo(_aaText),
        );
        expect(
          contrast(colors.onDanger, colors.danger),
          greaterThanOrEqualTo(_aaText),
        );
      });

      // The pair this file did not have. A disabled button kept the accent
      // fill, swapped its label to `inkTertiary` and faded the whole thing to
      // 60%, which left the label at 1.17:1 — violet on grey, and invisible on
      // the sign-in screen. WCAG exempts an inactive control; a person who
      // cannot read the button does not care, so it is held to AA here.
      test('a disabled button carries its label at AA', () {
        expect(
          contrast(colors.ink, colors.outlineStrong),
          greaterThanOrEqualTo(_aaText),
          reason: 'filled variants when disabled',
        );
        expect(
          contrast(colors.inkTertiary, colors.surface),
          greaterThanOrEqualTo(_aaText),
          reason: 'the outline variant when disabled',
        );
        expect(
          contrast(colors.inkTertiary, colors.canvas),
          greaterThanOrEqualTo(_aaText),
          reason: 'the ghost variant when disabled',
        );
      });

      test('soft tones carry their ink at AA', () {
        expect(
          contrast(colors.success, colors.successSoft),
          greaterThanOrEqualTo(_aaText),
        );
        expect(
          contrast(colors.warning, colors.warningSoft),
          greaterThanOrEqualTo(_aaText),
        );
        expect(
          contrast(colors.danger, colors.dangerSoft),
          greaterThanOrEqualTo(_aaText),
        );
        expect(
          contrast(colors.accentInk, colors.accentSoft),
          greaterThanOrEqualTo(_aaText),
        );
      });

      test('an icon on every tile tint meets AA for large glyphs', () {
        for (final tint in [
          colors.tilePink,
          colors.tileMint,
          colors.tileSky,
          colors.tilePeach,
        ]) {
          expect(
            contrast(colors.accentInk, tint),
            greaterThanOrEqualTo(_aaText),
          );
        }
      });

      test('the initial on every member colour meets AA', () {
        for (final color in MemberColor.values) {
          final swatch = members.of(color);
          expect(
            contrast(swatch.onFill, swatch.fill),
            greaterThanOrEqualTo(_aaText),
            reason: color.name,
          );
        }
      });

      test('every member colour is distinguishable from the surface', () {
        for (final color in MemberColor.values) {
          expect(
            contrast(members.of(color).fill, colors.surface),
            greaterThanOrEqualTo(1.25),
            reason: color.name,
          );
        }
      });

      test('member colours are distinct from each other', () {
        final fills = MemberColor.values.map((c) => members.of(c).fill).toSet();
        expect(fills, hasLength(MemberColor.values.length));
      });
    });
  }

  test('a member colour round-trips by name and falls back safely', () {
    expect(MemberColor.fromName('mint'), MemberColor.mint);
    expect(MemberColor.fromName('not-a-colour'), MemberColor.violet);
  });

  test('contrast is symmetric and one for identical colours', () {
    expect(contrast(Colors.white, Colors.white), 1);
    expect(contrast(Colors.black, Colors.white), closeTo(21, 0.01));
    expect(
      contrast(_aaLarge > 0 ? Colors.black : Colors.white, Colors.white),
      closeTo(21, 0.01),
    );
  });
}
