import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';

void main() {
  Future<void> pump(WidgetTester tester, {bool reduced = false}) =>
      tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: NestEggWobble(child: ColoredBox(color: Colors.amber)),
            ),
          ),
        ),
      );

  Finder turning() => find.descendant(
    of: find.byType(NestEggWobble),
    matching: find.byType(Transform),
  );

  testWidgets('an egg that is hatching rocks, then rests, and keeps going', (
    tester,
  ) async {
    NestMotion.debugHoldStill = false;
    addTearDown(() => NestMotion.debugHoldStill = true);
    await pump(tester);
    await tester.pump(const Duration(milliseconds: 200));
    expect(turning(), findsOneWidget);
    final rocking = tester.widget<Transform>(turning()).transform;
    expect(rocking.isIdentity(), isFalse);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(tester.widget<Transform>(turning()).transform.isIdentity(), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('under reduce motion it sits still', (tester) async {
    NestMotion.debugHoldStill = false;
    addTearDown(() => NestMotion.debugHoldStill = true);
    await pump(tester, reduced: true);
    await tester.pump(const Duration(milliseconds: 200));
    expect(turning(), findsNothing);
  });

  testWidgets('and in the widget suite, so pumpAndSettle settles', (
    tester,
  ) async {
    await pump(tester);
    await tester.pumpAndSettle();
    expect(turning(), findsNothing);
  });
}
