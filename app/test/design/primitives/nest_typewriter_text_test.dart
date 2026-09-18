import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/shared/copy/app_copy.dart';

import '../../support/pump_kit.dart';

/// A line that types itself out. The interesting parts are the ones a
/// screenshot cannot show: what a screen reader is given, whether the layout
/// below it moves while the line grows, and whether it ever stops.
void main() {
  Widget line(BuildContext context) => NestTypewriterText(
    text: AppCopy.signInTagline,
    style: NestTheme.of(context).text.body,
  );

  Widget pumped() => Builder(builder: line);

  for (final brightness in bothThemes) {
    testWidgets('it finishes on the whole sentence, in ${brightness.name}', (
      tester,
    ) async {
      await pumpKit(tester, pumped(), brightness: brightness);
      await tester.pumpAndSettle();

      expect(find.text(AppCopy.signInTagline), findsOneWidget);
    });
  }

  testWidgets('a screen reader gets the sentence whole, at once', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpKit(tester, pumped());

    // The first frame, with nothing typed yet.
    expect(
      find.bySemanticsLabel(AppCopy.signInTagline),
      findsOneWidget,
      reason: 'nobody should be read a sentence one character at a time',
    );
    await tester.pumpAndSettle();
    handle.dispose();
  });

  testWidgets('nothing below it moves while it types', (tester) async {
    await pumpKit(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [pumped(), const Text(AppCopy.appName)],
      ),
    );

    final before = tester.getTopLeft(find.text(AppCopy.appName));
    await tester.pump(const Duration(milliseconds: 200));
    final midway = tester.getTopLeft(find.text(AppCopy.appName));
    await tester.pumpAndSettle();

    expect(midway, before, reason: 'the finished line reserves its own space');
    expect(tester.getTopLeft(find.text(AppCopy.appName)), before);
  });

  /// What is actually painted this frame: the sentence is always laid out
  /// whole, so the question is how much of it is visible ink.
  int visibleCharacters(WidgetTester tester) {
    final span =
        tester.widget<Text>(find.text(AppCopy.signInTagline)).textSpan!
            as TextSpan;
    return (span.text ?? '').length;
  }

  testWidgets('it types, rather than appearing', (tester) async {
    await pumpKit(tester, pumped());

    expect(visibleCharacters(tester), 0, reason: 'nothing typed yet');
    await tester.pump(const Duration(milliseconds: 300));
    final midway = visibleCharacters(tester);
    expect(midway, greaterThan(0));
    expect(
      midway,
      lessThan(AppCopy.signInTagline.length),
      reason: 'partway through, part of the line is still to come',
    );

    await tester.pumpAndSettle();
    expect(visibleCharacters(tester), AppCopy.signInTagline.length);
  });

  /// The caret, or null once there is nothing left to type.
  Object? caretOf(WidgetTester tester) => tester
      .widget<CustomPaint>(
        find
            .descendant(
              of: find.byType(NestTypewriterText),
              matching: find.byType(CustomPaint),
            )
            .first,
      )
      .foregroundPainter;

  testWidgets('the caret is there while typing and gone when it is done', (
    tester,
  ) async {
    await pumpKit(tester, pumped());
    await tester.pump(const Duration(milliseconds: 300));
    expect(caretOf(tester), isNotNull);

    await tester.pumpAndSettle();
    expect(caretOf(tester), isNull);
  });

  testWidgets('with reduce-motion the line is whole on the first frame', (
    tester,
  ) async {
    await pumpKit(tester, pumped(), reduceMotion: true);

    expect(visibleCharacters(tester), AppCopy.signInTagline.length);
    expect(
      caretOf(tester),
      isNull,
      reason: 'and there is no caret left sitting there to watch',
    );
  });

  testWidgets('it holds at 200% text without clipping', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpKit(
      tester,
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: pumped(),
      ),
      brightness: Brightness.dark,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
