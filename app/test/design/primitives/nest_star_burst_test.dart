import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';

/// Stars that fly once and rest (design-system ADR-0002, todos ADR-0003): a
/// burst plays when its trigger changes, never on the first frame, never under
/// reduce-motion, never in a screen reader's way, and never in a tap's.
void main() {
  Future<void> pumpBurst(
    WidgetTester tester, {
    required int burst,
    bool reduceMotion = false,
    VoidCallback? onTap,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: nestThemeData(NestTheme.light()),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(
          body: Center(
            child: NestStarBurst(
              burst: burst,
              child: TextButton(onPressed: onTap, child: const Text('Twelve')),
            ),
          ),
        ),
      ),
    ),
  );

  Finder flyingStars() => find.byIcon(Icons.star_rounded);

  testWidgets('does not play on the first frame', (tester) async {
    await pumpBurst(tester, burst: 3);
    await tester.pump(const Duration(milliseconds: 100));
    expect(flyingStars(), findsNothing);
  });

  testWidgets('plays once when the trigger changes, then rests', (
    tester,
  ) async {
    await pumpBurst(tester, burst: 0);
    await pumpBurst(tester, burst: 1);
    await tester.pump(const Duration(milliseconds: 200));
    expect(flyingStars(), findsNWidgets(NestStarBurst.starCount));
    await tester.pumpAndSettle();
    expect(flyingStars(), findsNothing);
  });

  testWidgets('does nothing under reduce-motion', (tester) async {
    await pumpBurst(tester, burst: 0, reduceMotion: true);
    await pumpBurst(tester, burst: 1, reduceMotion: true);
    await tester.pump(const Duration(milliseconds: 200));
    expect(flyingStars(), findsNothing);
  });

  testWidgets('never takes a tap meant for what it celebrates', (tester) async {
    var taps = 0;
    await pumpBurst(tester, burst: 0, onTap: () => taps++);
    await pumpBurst(tester, burst: 1, onTap: () => taps++);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Twelve'));
    expect(taps, 1);
    await tester.pumpAndSettle();
  });

  testWidgets('says nothing to a screen reader', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpBurst(tester, burst: 0);
    await pumpBurst(tester, burst: 1);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.bySemanticsLabel(RegExp('star')), findsNothing);
    await tester.pumpAndSettle();
    semantics.dispose();
  });
}
