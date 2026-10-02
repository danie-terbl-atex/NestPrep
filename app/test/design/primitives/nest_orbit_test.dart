import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/shared/copy/app_copy.dart';

import '../../support/pump_kit.dart';

/// The picture the app opens on. What is worth holding: it is **one node** to
/// a screen reader rather than a dozen decorative ones, its entrance **ends**,
/// it turns only when asked and never under reduce-motion, and it stays inside
/// its own box whatever it is given (`FE-13`, `FE-14`, `FE-15`,
/// design-system ADR-0006).
void main() {
  List<NestOrbitItem> items({int count = 6}) => [
    for (var index = 0; index < count; index++)
      NestOrbitItem(
        ring: index.isEven ? NestOrbitRing.inner : NestOrbitRing.outer,
        turns: index / count,
        child: NestAvatar(
          name: AppCopy.signInOrbitInitials,
          color: MemberColor.values[index % MemberColor.values.length],
        ),
      ),
  ];

  Widget orbit({
    List<NestOrbitItem>? given,
    double maxWidth = 300,
    bool spins = false,
  }) => NestOrbit(
    semanticsLabel: AppCopy.signInOrbitLabel,
    centre: const NestIconTile(icon: Icons.home_rounded),
    items: given ?? items(),
    maxWidth: maxWidth,
    spins: spins,
  );

  List<Offset> centresOfMarks(WidgetTester tester) => [
    for (final mark in find.byType(NestAvatar).evaluate())
      tester.getCenter(find.byWidget(mark.widget)),
  ];

  /// The suite holds every orbit still so `pumpAndSettle` can settle
  /// (`test/flutter_test_config.dart`); these tests are about the turning.
  void letItTurn() {
    NestMotion.debugHoldStill = false;
    addTearDown(() => NestMotion.debugHoldStill = true);
  }

  for (final brightness in bothThemes) {
    testWidgets('it settles and is square, in ${brightness.name}', (
      tester,
    ) async {
      await pumpKit(tester, orbit(), brightness: brightness);
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byType(NestOrbit));
      expect(size.width, size.height);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a screen reader is told one sentence, not nine glyphs', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpKit(tester, orbit());
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel(AppCopy.signInOrbitLabel), findsOneWidget);
    expect(
      find.bySemanticsLabel(AppCopy.signInOrbitInitials),
      findsNothing,
      reason: 'the marks are an illustration, not a list to read out',
    );
    handle.dispose();
  });

  testWidgets('nothing rides off the edge, however many things orbit', (
    tester,
  ) async {
    await pumpKit(tester, orbit(given: items(count: 12)));
    await tester.pumpAndSettle();

    final box = tester.getRect(find.byType(NestOrbit));
    for (final mark in find.byType(NestAvatar).evaluate()) {
      final rect = tester.getRect(find.byWidget(mark.widget));
      expect(
        box.inflate(0.5).contains(rect.topLeft) &&
            box.inflate(0.5).contains(rect.bottomRight),
        isTrue,
        reason: 'the geometry is exact, not fitted — $rect escaped $box',
      );
    }
  });

  testWidgets('it takes the width it is given when that is less', (
    tester,
  ) async {
    await pumpKit(tester, SizedBox(width: 160, child: orbit()));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(NestOrbit)).width, 160);
  });

  testWidgets('with reduce-motion the whole picture is on the first frame', (
    tester,
  ) async {
    await pumpKit(tester, orbit(), reduceMotion: true);

    final marks = find.byType(NestAvatar);
    final placed = [
      for (final mark in marks.evaluate())
        tester.getCenter(find.byWidget(mark.widget)),
    ];
    await tester.pumpAndSettle();

    expect(placed, [
      for (final mark in marks.evaluate())
        tester.getCenter(find.byWidget(mark.widget)),
    ], reason: 'nothing left to drift once motion is off');
  });

  testWidgets('the last thing in arrives after the first', (tester) async {
    await pumpKit(tester, orbit(given: items(count: 4)));
    // Six steps of 70ms with a 220ms fade each: the first mark is well into
    // its own window here and the last has not opened yet.
    await tester.pump(const Duration(milliseconds: 300));

    final marks = find.byType(NestAvatar).evaluate().toList();
    double opacityOf(Element element) => tester
        .widget<Opacity>(
          find
              .ancestor(
                of: find.byWidget(element.widget),
                matching: find.byType(Opacity),
              )
              .first,
        )
        .opacity;

    expect(opacityOf(marks.first), greaterThan(opacityOf(marks.last)));
  });

  testWidgets('a spinning orbit keeps turning after it has arrived', (
    tester,
  ) async {
    letItTurn();
    await pumpKit(tester, orbit(spins: true));
    await tester.pump(const Duration(seconds: 2));
    final arrived = centresOfMarks(tester);
    await tester.pump(const Duration(seconds: 5));

    expect(
      centresOfMarks(tester),
      isNot(arrived),
      reason: 'the ring carries the marks round',
    );
    expect(tester.binding.hasScheduledFrame, isTrue);

    // Unmounting stops the ticker; a leak fails the test here.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a spinning orbit keeps its marks upright and in its box', (
    tester,
  ) async {
    letItTurn();
    await pumpKit(tester, orbit(spins: true, given: items(count: 12)));
    final box = tester.getRect(find.byType(NestOrbit));
    for (var second = 0; second < 40; second += 3) {
      await tester.pump(const Duration(seconds: 3));
      for (final mark in find.byType(NestAvatar).evaluate()) {
        final rect = tester.getRect(find.byWidget(mark.widget));
        expect(box.inflate(0.5).contains(rect.topLeft), isTrue);
        expect(box.inflate(0.5).contains(rect.bottomRight), isTrue);
        expect(rect.width, closeTo(rect.height, 0.01));
      }
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an orbit that is not asked to spin comes to rest', (
    tester,
  ) async {
    letItTurn();
    await pumpKit(tester, orbit());
    await tester.pumpAndSettle();
    final rested = centresOfMarks(tester);
    await tester.pump(const Duration(seconds: 5));

    expect(centresOfMarks(tester), rested);
  });

  testWidgets('with reduce-motion a spinning orbit does not turn', (
    tester,
  ) async {
    letItTurn();
    await pumpKit(tester, orbit(spins: true), reduceMotion: true);
    final placed = centresOfMarks(tester);
    await tester.pumpAndSettle();

    expect(centresOfMarks(tester), placed);
  });
}
