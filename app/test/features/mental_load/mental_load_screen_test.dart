import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/mental_load/model/week_load.dart';
import 'package:nestprep/features/mental_load/state/mental_load_controller.dart';
import 'package:nestprep/features/mental_load/ui/load_split_bar.dart';
import 'package:nestprep/features/mental_load/ui/mental_load_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../support/household_fixtures.dart';
import '../../support/mental_load_fixtures.dart';
import '../../support/mental_load_harness.dart';
import '../../support/pump_screen.dart';

/// The shared week, as a parent sees it (calendar ADR-0006): loading, a
/// quiet week, a failure with its retry, and a busy week — a card per adult
/// in warm words, a bar with names beside the colours, and a share button
/// that sends the card as a picture.
void main() {
  late MentalLoadHarness harness;

  setUp(() => harness = MentalLoadHarness());
  tearDown(() => harness.close());

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    await pumpScreen(
      tester,
      const MentalLoadScreen(),
      brightness: brightness,
      textScale: textScale,
      view: Fixtures.view(members: LoadFixtures.members),
      providers: [
        ChangeNotifierProvider<MentalLoadController>.value(
          value: harness.controller,
        ),
      ],
    );
  }

  /// A subscription's cancel needs a real turn before the reads reopen (the
  /// vault lesson on widget tests over controllers that cancel first).
  Future<void> settleCancels(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }

  /// The week moved: its two windowed reads reopen, and answer.
  Future<void> answerTheNewWindow(WidgetTester tester) async {
    await settleCancels(tester);
    harness.calendar.emitExceptions(const []);
    harness.todos.emitCompletions(const []);
    await tester.pumpAndSettle();
  }

  testWidgets('holds its layout while the week is read', (tester) async {
    await pump(tester);
    await tester.pump();
    expect(find.text(MentalLoadCopy.title), findsOneWidget);
    expect(find.text(MentalLoadCopy.intro), findsNothing);
  });

  testWidgets('a quiet week says so, and how it fills', (tester) async {
    await pump(tester);
    harness.answer();
    await tester.pumpAndSettle();
    expect(find.text(MentalLoadCopy.emptyTitle), findsOneWidget);
  });

  testWidgets('a failed read offers the retry', (tester) async {
    await pump(tester);
    harness.calendar.failEventsWith(const UnavailableFailure());
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.retry), findsOneWidget);
    await tester.tap(find.text(AppCopy.retry));
    // The reads reopen after the old ones are cancelled.
    await settleCancels(tester);
    harness.answerABusyWeek();
    await tester.pumpAndSettle();
    expect(find.text(MentalLoadCopy.intro), findsOneWidget);
  });

  testWidgets('a busy week: a card per adult, in words, with names on the '
      'bar', (tester) async {
    await pump(tester);
    harness.answerABusyWeek();
    await tester.pumpAndSettle();
    expect(find.text(MentalLoadCopy.carried('Sam Parent', 3)), findsOneWidget);
    expect(find.text(MentalLoadCopy.carried('Alex Parent', 3)), findsOneWidget);
    expect(
      find.text('1 ${MentalLoadCopy.kind(LoadKind.todosDone, 1)}'),
      findsOneWidget,
    );
    expect(
      find.text(MentalLoadCopy.splitPart('Sam Parent', 3)),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp(MentalLoadCopy.splitLabel)),
      findsOneWidget,
    );
    expect(find.text('Thandi Helper'), findsNothing, reason: 'adults only');
    // The bar is drawn, a stretch per adult — found invisible, zero pixels
    // tall, in the design review picture before this line existed.
    final stretches = find.descendant(
      of: find.byType(LoadSplitBar),
      matching: find.byType(ColoredBox),
    );
    expect(stretches, findsNWidgets(2));
    for (final stretch in stretches.evaluate()) {
      expect(
        tester.getSize(find.byWidget(stretch.widget)).height,
        greaterThan(0),
      );
    }
  });

  testWidgets('Share sends the card as a picture', (tester) async {
    await pump(tester);
    harness.answerABusyWeek();
    await tester.pumpAndSettle();
    await tester.tap(find.text(MentalLoadCopy.share).first);
    await tester.pump();
    // The capture is real rendering work, so it needs real time.
    await tester.runAsync(() async {
      for (var i = 0; i < 40 && harness.sharer.shared.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
    await tester.pumpAndSettle();
    expect(harness.sharer.shared, hasLength(1));
    expect(harness.sharer.shared.single.bytes, greaterThan(0));
    expect(harness.sharer.shared.single.text, contains('Sam Parent'));
  });

  testWidgets('a share that fails is said in words', (tester) async {
    harness.sharer.failWith = const MentalLoadFailure(
      MentalLoadProblem.shareUnavailable,
    );
    await pump(tester);
    harness.answerABusyWeek();
    await tester.pumpAndSettle();
    await tester.tap(find.text(MentalLoadCopy.share).first);
    await tester.pump();
    await tester.runAsync(() async {
      for (var i = 0; i < 40 && harness.controller.actionFailure == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
    await tester.pumpAndSettle();
    expect(
      find.text(MentalLoadCopy.problem(MentalLoadProblem.shareUnavailable)),
      findsOneWidget,
    );
  });

  testWidgets('pages to the next week and back', (tester) async {
    await pump(tester);
    harness.answer();
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(MentalLoadCopy.nextWeek));
    await answerTheNewWindow(tester);
    expect(find.text(MentalLoadCopy.thisWeek), findsOneWidget);
    await tester.tap(find.text(MentalLoadCopy.thisWeek));
    await answerTheNewWindow(tester);
    expect(find.text(MentalLoadCopy.thisWeek), findsNothing);
  });

  testWidgets('with one parent, says who the week can be shared with', (
    tester,
  ) async {
    final alone = MentalLoadHarness(members: [Fixtures.sam, Fixtures.kid]);
    addTearDown(alone.close);
    await pumpScreen(
      tester,
      const MentalLoadScreen(),
      providers: [
        ChangeNotifierProvider<MentalLoadController>.value(
          value: alone.controller,
        ),
      ],
    );
    alone.answer();
    await tester.pumpAndSettle();
    expect(find.text(MentalLoadCopy.noAdultsTitle), findsOneWidget);
  });

  testWidgets('survives dark at 200% text on a 360-wide phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pump(tester, brightness: Brightness.dark, textScale: 2);
    harness.answerABusyWeek();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.bySemanticsLabel(MentalLoadCopy.nextWeek));
    await answerTheNewWindow(tester);
    expect(tester.takeException(), isNull);
  });
}
