import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/nanny_hub_route.dart';
import 'package:nestprep/features/nanny_hub/model/handover_kind.dart';
import 'package:nestprep/features/nanny_hub/model/summary_moment.dart';
import 'package:nestprep/shared/copy/app_copy.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/nanny_fixtures.dart';
import '../../../support/pump_nanny_hub.dart';

void main() {
  late NannyFakes fakes;

  setUp(() => fakes = NannyFakes());
  tearDown(() => fakes.close());

  Future<void> open(
    WidgetTester tester, {
    String shiftId = 'shift-0',
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    await pumpNannyHub(
      tester,
      fakes,
      location: NannyHubRoute.summaryPathFor(Fixtures.householdId, shiftId),
      brightness: brightness,
      textScale: textScale,
    );
    fakes.answerAFullHub();
    await tester.pumpAndSettle();
  }

  testWidgets('says whose shift and when, on the household’s clock', (
    tester,
  ) async {
    await open(tester);
    expect(
      find.text(NannyShiftCopy.summaryHeadline('Nomsa Carer')),
      findsOneWidget,
    );
    // 28 Sep 12:05 to 18:05 UTC is 14:05 to 20:05 in Johannesburg.
    expect(find.textContaining('14:05 – 20:05'), findsOneWidget);
  });

  testWidgets('an incident is called out before anything else', (tester) async {
    await open(tester);
    expect(find.text(NannyShiftCopy.summaryIncident), findsOneWidget);
    expect(
      find.text(NannyShiftCopy.summaryCount(HandoverKind.incident, 1)),
      findsOneWidget,
    );
    expect(
      find.text(NannyShiftCopy.summaryCount(HandoverKind.meal, 2)),
      findsOneWidget,
    );
    expect(find.text(NannyShiftCopy.summaryPhotos(1)), findsOneWidget);
  });

  testWidgets('carries the carer’s last word, the checklist and the moments', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Asleep by eight.'), findsOneWidget);
    expect(find.text(NannyShiftCopy.ticked(1, 2)), findsOneWidget);
    await scrollTo(tester, find.textContaining('Bumped her knee'));
    expect(find.textContaining('Bumped her knee'), findsOneWidget);
    await scrollTo(tester, find.textContaining(NannyShiftCopy.withPhoto));
    expect(find.textContaining(NannyShiftCopy.withPhoto), findsOneWidget);
  });

  testWidgets('a trimmed summary says the counts include every moment', (
    tester,
  ) async {
    await pumpNannyHub(
      tester,
      fakes,
      location: NannyHubRoute.summaryPathFor(Fixtures.householdId, 'shift-0'),
    );
    fakes.answerEverything(
      summaries: [
        NannyFixtures.summary.copyWith(
          isTrimmed: true,
          moments: [
            SummaryMoment(
              kind: HandoverKind.note,
              at: NannyFixtures.startedAt,
              note: 'Quiet evening',
            ),
          ],
        ),
      ],
    );
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text(NannyShiftCopy.summaryTrimmed(1)));
    expect(find.text(NannyShiftCopy.summaryTrimmed(1)), findsOneWidget);
  });

  testWidgets('one not written yet is said, not blank', (tester) async {
    await open(tester, shiftId: 'shift-still-ending');
    expect(find.text(NannyShiftCopy.summaryGoneTitle), findsOneWidget);
  });

  testWidgets('holds at 360 wide, in dark, at 200% text', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await open(tester, brightness: Brightness.dark, textScale: 2);
    await scrollTo(tester, find.textContaining(NannyShiftCopy.withPhoto));
    expect(tester.takeException(), isNull);
  });
}
