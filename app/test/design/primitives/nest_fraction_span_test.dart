import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';

import '../../support/pump_kit.dart';

/// Kitchen fractions in the app's own face: every `n/d` drawn alike, a
/// whole number against its fraction, and the rest left as text.
void main() {
  const style = TextStyle(fontSize: 16);

  List<InlineSpan> partsOf(String text) =>
      (nestFractionSpan(text, style) as TextSpan).children!;

  test('a whole number sits against its fraction, the rest is text', () {
    final parts = partsOf('1 1/3 tbsp');
    expect((parts[0] as TextSpan).text, '1');
    expect(parts[1], isA<WidgetSpan>());
    expect((parts[2] as TextSpan).text, ' tbsp');
  });

  test('text with no fraction in it is only text', () {
    final parts = partsOf('665 g');
    expect(parts.single, isA<TextSpan>());
    expect((parts.single as TextSpan).text, '665 g');
  });

  testWidgets('draws the numerator, the slash and the denominator', (
    tester,
  ) async {
    await pumpKit(tester, Text.rich(nestFractionSpan('2/3 cup', style)));
    expect(find.text('2'), findsOneWidget);
    expect(find.text('⁄'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('a tag that is a figure sets its fractions the same way', (
    tester,
  ) async {
    await pumpKit(tester, const NestTag(label: '×2/3', isFigure: true));
    expect(find.text('⁄'), findsOneWidget);
  });
}
