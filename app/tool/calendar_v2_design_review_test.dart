import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/mental_load/state/mental_load_controller.dart';
import 'package:nestprep/features/mental_load/ui/mental_load_screen.dart';
import 'package:nestprep/features/school_letter/data/letter_picker.dart';
import 'package:nestprep/features/school_letter/model/letter_reading.dart';
import 'package:nestprep/features/school_letter/state/school_letter_controller.dart';
import 'package:nestprep/features/school_letter/ui/school_letter_screen.dart';
import 'package:provider/provider.dart';

import '../test/support/fake_calendar_repository.dart';
import '../test/support/fake_calendar_v2.dart';
import '../test/support/household_fixtures.dart';
import '../test/support/mental_load_fixtures.dart';
import '../test/support/mental_load_harness.dart';
import 'review_press.dart';

/// Calendar V2's pictures (calendar ADR-0005, ADR-0006), through the shared
/// shutter: snapping a letter — the way in and the review — and the shared
/// week. `flutter test tool/calendar_v2_design_review_test.dart
/// --update-goldens` retakes them.
void main() {
  setUpAll(loadEveryFont);

  for (final brightness in Brightness.values) {
    final theme = brightness == Brightness.dark ? 'dark' : 'light';

    testWidgets('school letter, the way in — $theme', (tester) async {
      final calendar = FakeCalendarRepository();
      addTearDown(calendar.close);
      await captureScreen(
        tester,
        'school-letter-$theme',
        brightness: brightness,
        screen: const SchoolLetterScreen(),
        providers: [
          ChangeNotifierProvider(
            create: (_) => SchoolLetterController(
              schoolLetterReader: FakeSchoolLetterReader(),
              letterPicker: FakeLetterPicker(),
              calendarRepository: calendar,
              householdId: Fixtures.householdId,
              memberId: Fixtures.samMemberId,
            ),
          ),
        ],
        emit: () async {},
      );
    });

    testWidgets('school letter, the review — $theme', (tester) async {
      final calendar = FakeCalendarRepository();
      addTearDown(calendar.close);
      final controller = SchoolLetterController(
        schoolLetterReader: FakeSchoolLetterReader()
          ..reading = LetterReading(proposals: twoProposals(), callsLeft: 7),
        letterPicker: FakeLetterPicker(),
        calendarRepository: calendar,
        householdId: Fixtures.householdId,
        memberId: Fixtures.samMemberId,
      );
      addTearDown(controller.dispose);
      await captureScreen(
        tester,
        'school-letter-review-$theme',
        brightness: brightness,
        screen: const SchoolLetterScreen(),
        providers: [
          ChangeNotifierProvider<SchoolLetterController>.value(
            value: controller,
          ),
        ],
        emit: () => controller.pick(LetterSource.camera),
      );
    });

    testWidgets('the shared week — $theme', (tester) async {
      final harness = MentalLoadHarness();
      addTearDown(harness.close);
      await captureScreen(
        tester,
        'shared-week-$theme',
        brightness: brightness,
        view: Fixtures.view(members: LoadFixtures.members),
        screen: const MentalLoadScreen(),
        providers: [
          ChangeNotifierProvider<MentalLoadController>.value(
            value: harness.controller,
          ),
        ],
        emit: () async => harness.answerABusyWeek(),
      );
    });
  }

  testWidgets('the shared week — dark at 200% text', (tester) async {
    final harness = MentalLoadHarness();
    addTearDown(harness.close);
    await captureScreen(
      tester,
      'shared-week-dark-200-percent-text',
      brightness: Brightness.dark,
      textScale: 2,
      view: Fixtures.view(members: LoadFixtures.members),
      screen: const MentalLoadScreen(),
      providers: [
        ChangeNotifierProvider<MentalLoadController>.value(
          value: harness.controller,
        ),
      ],
      emit: () async => harness.answerABusyWeek(),
    );
  });
}
