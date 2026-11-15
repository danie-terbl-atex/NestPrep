import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';

import '../../support/pump_kit.dart';

/// The sign-in backdrop (design-system ADR-0023). What is worth holding: the
/// waves roll in, then keep swaying until the screen goes; reduce-motion draws
/// them settled and still, and turning it on mid-sway stops them; a scaffold
/// paints them edge to edge, under its body.
void main() {
  const corner = Offset(4, 4);

  Finder canvas() => find.descendant(
    of: find.byType(NestWaves),
    matching: find.byType(CustomPaint),
  );

  void letItMove() {
    NestMotion.debugHoldStill = false;
    addTearDown(() => NestMotion.debugHoldStill = true);
  }

  for (final brightness in bothThemes) {
    testWidgets('with reduce-motion they are settled at once and still, in '
        '${brightness.name}', (tester) async {
      letItMove();
      await pumpKit(
        tester,
        const NestWaves(),
        brightness: brightness,
        reduceMotion: true,
      );
      final waves = brightness == Brightness.dark
          ? NestColors.dark.waves
          : NestColors.light.waves;

      expect(
        tester.renderObject(canvas()),
        paints
          ..path(color: waves[1])
          ..path(color: waves[0], includes: [corner]),
      );
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
    });
  }

  testWidgets('they roll in from the edges, then keep swaying', (tester) async {
    letItMove();
    await pumpKit(tester, const NestWaves());
    expect(
      tester.renderObject(canvas()),
      isNot(paints..path(includes: [corner])),
    );

    await tester.pump(const Duration(seconds: 2));
    expect(tester.renderObject(canvas()), paints..path(includes: [corner]));

    await tester.pump(const Duration(seconds: 30));
    expect(tester.binding.transientCallbackCount, greaterThan(0));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reduce-motion turned on mid-sway stops them', (tester) async {
    letItMove();
    await pumpKit(tester, const NestWaves());
    await tester.pump(const Duration(seconds: 4));
    expect(tester.binding.transientCallbackCount, greaterThan(0));

    await pumpKit(tester, const NestWaves(), reduceMotion: true);
    await tester.pumpAndSettle();

    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('waves opened over waves carry on rather than rolling in again, '
      'and roll in afresh once those have gone', (tester) async {
    letItMove();
    Widget layers(List<Key> keys) => Stack(
      children: [
        for (final key in keys) Positioned.fill(child: NestWaves(key: key)),
      ],
    );
    const gate = ValueKey('gate');
    const signIn = ValueKey('sign-in');

    await pumpKit(tester, layers([gate]));
    await tester.pump(const Duration(seconds: 2));
    await pumpKit(tester, layers([gate, signIn]));
    expect(
      tester.renderObject(canvas().last),
      paints..path(includes: [corner]),
      reason: 'the gate hands over to sign-in without the waves jumping',
    );

    await pumpKit(tester, layers([]));
    await pumpKit(tester, layers([signIn]));
    expect(
      tester.renderObject(canvas()),
      isNot(paints..path(includes: [corner])),
    );

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a scaffold paints its backdrop under the body', (tester) async {
    await pumpKit(
      tester,
      const NestScaffold(backdrop: NestWaves(), body: Text('Body')),
    );

    final backdrop = tester.getRect(find.byType(NestWaves));
    expect(backdrop.size, tester.getSize(find.byType(NestScaffold)));
    expect(
      find.ancestor(of: find.text('Body'), matching: find.byType(NestWaves)),
      findsNothing,
    );
  });
}
