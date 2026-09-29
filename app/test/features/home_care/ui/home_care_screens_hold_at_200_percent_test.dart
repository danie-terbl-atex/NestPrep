import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/home_care_route.dart';
import 'package:nestprep/features/home_care/model/job_status.dart';
import 'package:nestprep/features/household/model/household_view.dart';

import '../../../support/home_care_fixtures.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_home_care.dart';

/// Every home-care screen in dark, at 200% text, on a 360-wide phone — the
/// floor `FE-13` and `FE-14` set. A screen that overflows fails here, not on
/// somebody's phone.
void main() {
  const household = Fixtures.householdId;
  final screens = <String, (String, HouseholdView?, JobStatus)>{
    'the job list': (
      HomeCareRoute.pathFor(household),
      null,
      JobStatus.assigned,
    ),
    'a new job': (
      HomeCareRoute.newJobPathFor(household),
      null,
      JobStatus.assigned,
    ),
    'the rooms': (
      HomeCareRoute.roomsPathFor(household),
      null,
      JobStatus.assigned,
    ),
    'the products': (
      HomeCareRoute.productsPathFor(household),
      null,
      JobStatus.assigned,
    ),
    'a job': (
      HomeCareRoute.jobPathFor(household, 'oven'),
      null,
      JobStatus.sentBack,
    ),
    'the helper’s step-through': (
      HomeCareRoute.stepsPathFor(household, 'oven'),
      HomeCareFixtures.helperView(),
      JobStatus.inProgress,
    ),
    'the review': (
      HomeCareRoute.reviewPathFor(household, 'oven'),
      null,
      JobStatus.submitted,
    ),
  };

  for (final MapEntry(key: name, value: (location, view, status))
      in screens.entries) {
    testWidgets('$name holds in dark at 200% text, 360 wide', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final harness = HomeCareHarness();
      addTearDown(harness.close);
      harness.photos.stored['oven/before'] = HomeCareFixtures.photoBytes;
      harness.photos.stored['oven/after-2'] = HomeCareFixtures.photoBytes;

      await harness.pump(
        tester,
        location: location,
        view: view,
        brightness: Brightness.dark,
        textScale: 2,
      );
      await harness.emit(
        tester,
        jobList: [
          status == JobStatus.submitted
              ? HomeCareFixtures.handedIn()
              : HomeCareFixtures.job(
                  status: status,
                  productIds: const ['jik', 'windolene'],
                  doneStepIds: const ['s1'],
                  reviewNote: status == JobStatus.sentBack
                      ? 'The corner by the hinge is still greasy'
                      : null,
                ),
        ],
      );

      expect(tester.takeException(), isNull);
    });
  }
}
