import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/home_care_route.dart';
import 'package:nestprep/app/home_care_routes.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/features/home_care/data/cleaning_job_repository.dart';
import 'package:nestprep/features/home_care/data/helper_profile_repository.dart';
import 'package:nestprep/features/home_care/data/home_care_library_repository.dart';
import 'package:nestprep/features/home_care/data/job_photo_store.dart';
import 'package:nestprep/features/home_care/data/read_aloud.dart';
import 'package:nestprep/features/home_care/data/routine_repository.dart';
import 'package:nestprep/features/home_care/data/translation_repository.dart';
import 'package:nestprep/features/home_care/model/cleaning_job.dart';
import 'package:nestprep/features/home_care/model/home_care_product.dart';
import 'package:nestprep/features/home_care/model/home_care_room.dart';
import 'package:nestprep/features/home_care/model/language/helper_language.dart';
import 'package:nestprep/features/home_care/model/language/helper_profile.dart';
import 'package:nestprep/features/home_care/model/routine/room_routine.dart';
import 'package:nestprep/features/home_care/model/routine/routine_tick.dart';
import 'package:nestprep/features/home_care/state/photo_intake.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/shared/flags/feature_flags_controller.dart';
import 'package:provider/provider.dart';

import 'fake_auth.dart';
import 'fake_feature_flag_source.dart';
import 'fake_home_care.dart';
import 'fake_home_care_v2.dart';
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
  final routines = FakeRoutineRepository();
  final profiles = FakeHelperProfileRepository();
  final translations = FakeTranslationRepository();
  final voice = FakeReadAloud();
  final flags = FakeFeatureFlagSource();

  /// What an absent switch reads as — on, as in a debug build, unless a test
  /// is about a release build (foundation ADR-0014).
  var flagsDefaultOn = true;
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
    await routines.close();
    await profiles.close();
    await flags.close();
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
        Provider<RoutineRepository>.value(value: routines),
        Provider<HelperProfileRepository>.value(value: profiles),
        Provider<TranslationRepository>.value(value: translations),
        Provider<ReadAloud>.value(value: voice),
        ChangeNotifierProvider<FeatureFlagsController>(
          create: (_) =>
              FeatureFlagsController(source: flags, defaultOn: flagsDefaultOn),
        ),
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

  /// The shell's three reads answering, without waiting to settle — for a
  /// screen whose own read is still loading, whose skeleton never settles.
  Future<void> feedShell(
    WidgetTester tester, {
    List<CleaningJob> jobList = const [],
    List<HomeCareRoom> rooms = const [
      HomeCareFixtures.kitchen,
      HomeCareFixtures.bathroom,
    ],
    List<HomeCareProduct> products = const [],
  }) async {
    jobs.emitJobs(jobList);
    library.emitRooms(rooms);
    library.emitProducts(products);
    await tester.pump();
  }

  /// The routines' two reads answering (home-care ADR-0004).
  Future<void> emitRoutines(
    WidgetTester tester, {
    required List<RoomRoutine> routineList,
    List<RoutineTick> ticks = const [],
  }) async {
    routines.emitRoutines(routineList);
    routines.emitTicks(ticks);
    await tester.pumpAndSettle();
  }

  /// Everybody's languages answering (home-care ADR-0006).
  Future<void> emitLanguages(
    WidgetTester tester,
    Map<String, HelperLanguage> languages,
  ) async {
    profiles.emitProfiles([
      for (final MapEntry(key: memberId, value: language) in languages.entries)
        HelperProfile(id: memberId, language: language, updatedBy: memberId),
    ]);
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
