import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/home_care_route.dart';
import 'package:nestprep/features/home_care/model/job_status.dart';
import 'package:nestprep/features/home_care/model/language/helper_language.dart';
import 'package:nestprep/features/home_care/model/language/helper_profile.dart';
import 'package:nestprep/features/home_care/model/stock_level.dart';
import 'package:nestprep/shared/copy/app_copy.dart';

import '../../../support/home_care_fixtures.dart';
import '../../../support/home_care_routine_fixtures.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_home_care.dart';

/// Home care's V2 screens in dark, at 200% text, on a 360-wide phone — the
/// floor `FE-13` and `FE-14` set — each with the data that makes it longest:
/// translated lines with their English beside them, a product running low,
/// a room with two routines.
void main() {
  const household = Fixtures.householdId;

  Future<HomeCareHarness> openAt200(
    WidgetTester tester,
    String location, {
    bool asHelper = false,
  }) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final harness = HomeCareHarness();
    addTearDown(harness.close);
    harness.photos.stored['oven/before'] = HomeCareFixtures.photoBytes;
    await harness.pump(
      tester,
      location: location,
      view: asHelper ? HomeCareFixtures.helperView() : null,
      brightness: Brightness.dark,
      textScale: 2,
    );
    return harness;
  }

  Future<void> feedEverything(
    HomeCareHarness harness,
    WidgetTester tester,
  ) async {
    await harness.feedShell(
      tester,
      jobList: [
        HomeCareFixtures.job(
          status: JobStatus.inProgress,
          productIds: const ['jik', 'windolene'],
        ),
      ],
      products: [
        HomeCareFixtures.bleach.copyWith(
          stock: StockLevel.low,
          stockChangedBy: Fixtures.thandiMemberId,
        ),
        HomeCareFixtures.glassCleaner,
      ],
    );
    // Every read answers before anything settles: each screen waits on a
    // different one, and a skeleton still waiting never settles.
    harness.routines
      ..emitRoutines([
        RoutineFixtures.everyDay(),
        RoutineFixtures.everyDay(
          id: 'kitchen-deep',
          name: 'Kitchen deep clean',
        ),
      ])
      ..emitTicks(const []);
    harness.profiles.emitProfiles([
      const HelperProfile(
        id: Fixtures.thandiMemberId,
        language: HelperLanguage.isiZulu,
        updatedBy: Fixtures.thandiMemberId,
      ),
    ]);
    harness.jobs.emitEvents(const []);
    await tester.pumpAndSettle();
  }

  final screens = <String, (String, bool)>{
    'the room routines': (HomeCareRoute.routinesPathFor(household), false),
    'today’s rooms, in her language': (
      HomeCareRoute.todayPathFor(household),
      true,
    ),
    'the stock': (HomeCareRoute.stockPathFor(household), true),
    'everybody’s languages': (HomeCareRoute.languagesPathFor(household), false),
    'her language': (HomeCareRoute.languagesPathFor(household), true),
    'the step-through, in her language': (
      HomeCareRoute.stepsPathFor(household, 'oven'),
      true,
    ),
    'the front door with its ways in': (HomeCareRoute.pathFor(household), true),
  };

  for (final MapEntry(key: name, value: (location, asHelper))
      in screens.entries) {
    testWidgets('$name holds in dark at 200% text, 360 wide', (tester) async {
      final harness = await openAt200(tester, location, asHelper: asHelper);
      await feedEverything(harness, tester);
      final showEnglish = find.text(HomeCareLanguageCopy.showEnglish);
      if (showEnglish.evaluate().isNotEmpty) {
        await tester.tap(showEnglish.first);
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the routine sheet holds in dark at 200% text, 360 wide', (
    tester,
  ) async {
    final harness = await openAt200(
      tester,
      HomeCareRoute.routinesPathFor(household),
    );
    await feedEverything(harness, tester);
    await tester.tap(find.text(HomeCareRoutineCopy.newRoutine));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(AppCopy.householdSave));
    await tester.tap(find.text(AppCopy.householdSave));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
