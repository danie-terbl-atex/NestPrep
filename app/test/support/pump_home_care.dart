import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/home_care_route.dart';
import 'package:nestprep/app/home_care_routes.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/features/home_care/data/cleaning_job_repository.dart';
import 'package:nestprep/features/home_care/data/home_care_library_repository.dart';
import 'package:nestprep/features/home_care/data/job_photo_store.dart';
import 'package:nestprep/features/home_care/model/cleaning_job.dart';
import 'package:nestprep/features/home_care/model/home_care_product.dart';
import 'package:nestprep/features/home_care/model/home_care_room.dart';
import 'package:nestprep/features/home_care/state/photo_intake.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:provider/provider.dart';

import 'fake_auth.dart';
import 'fake_home_care.dart';
import 'home_care_fixtures.dart';
import 'household_fixtures.dart';
import 'pump_screen.dart';

/// Home care as the running app wires it: the real route table under a
/// household, with fakes behind every repository — so a test drives the
/// routes, the controllers they create and the screens together (`FE-20`),
/// and asserts on what a tap asked the backend for.
final class HomeCareHarness {
  HomeCareHarness() {
    camera.next = HomeCareFixtures.photoBytes;
  }

  final jobs = FakeCleaningJobRepository();
  final library = FakeHomeCareLibraryRepository();
  final photos = FakeJobPhotoStore();
  final camera = FakePhotoSource();
  final _auth = FakeAuthGateway();
  final _accounts = FakeAccountRepository();
  late final _session = SessionController(
    authGateway: _auth,
    accountRepository: _accounts,
  );

  late GoRouter router;

  Future<void> close() async {
    _session.dispose();
    await _auth.close();
    await _accounts.close();
    await jobs.close();
    await library.close();
  }

  /// Opens the app at [location] — a home-care path in the fixture
  /// household — with a route to the household screen behind it, so back
  /// has somewhere to go.
  Future<void> pump(
    WidgetTester tester, {
    String? location,
    HouseholdView? view,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) {
    router = GoRouter(
      initialLocation: '/households/${Fixtures.householdId}/household',
      routes: [
        GoRoute(
          path: '/households/:householdId/household',
          builder: (context, state) => const Placeholder(),
        ),
        homeCareRoutes(_session),
      ],
    );
    final opened = pumpRouter(
      tester,
      router: router,
      providers: [
        Provider<CleaningJobRepository>.value(value: jobs),
        Provider<HomeCareLibraryRepository>.value(value: library),
        Provider<JobPhotoStore>.value(value: photos),
        Provider<PhotoIntake>.value(value: fakePhotoIntake(camera)),
      ],
      view: view,
      brightness: brightness,
      textScale: textScale,
    );
    return opened.then((_) async {
      unawaited(
        router.push(location ?? HomeCareRoute.pathFor(Fixtures.householdId)),
      );
      await tester.pump();
    });
  }

  /// The three reads answering.
  Future<void> emit(
    WidgetTester tester, {
    List<CleaningJob>? jobList,
    List<HomeCareRoom>? rooms,
    List<HomeCareProduct>? products,
  }) async {
    jobs.emitJobs(jobList ?? [HomeCareFixtures.job()]);
    library.emitRooms(
      rooms ?? [HomeCareFixtures.kitchen, HomeCareFixtures.bathroom],
    );
    library.emitProducts(
      products ??
          const [
            HomeCareFixtures.bleach,
            HomeCareFixtures.glassCleaner,
            HomeCareFixtures.soap,
          ],
    );
    // An open job's history, so its skeleton comes to rest.
    jobs.emitEvents(const []);
    await tester.pumpAndSettle();
  }

  /// A phone-width screen tall enough to hold a whole job, so a test asserts
  /// what is on it rather than scrolling for each line.
  static void makeRoom(WidgetTester tester) {
    tester.view.physicalSize = const Size(420, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  static String jobPath([String jobId = 'oven']) =>
      HomeCareRoute.jobPathFor(Fixtures.householdId, jobId);
}
