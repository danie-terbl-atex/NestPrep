import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/home_care/model/job_step.dart';
import 'package:nestprep/features/home_care/model/language/helper_language.dart';
import 'package:nestprep/features/home_care/model/routine/routine_cadence.dart';
import 'package:nestprep/features/home_care/model/stock_level.dart';
import 'package:nestprep/features/home_care/state/home_care_controller.dart';
import 'package:nestprep/features/home_care/state/routines_controller.dart';
import 'package:nestprep/features/home_care/ui/languages_screen.dart';
import 'package:nestprep/features/home_care/ui/routines_screen.dart';
import 'package:nestprep/features/home_care/ui/stock_screen.dart';
import 'package:nestprep/features/home_care/ui/today_rooms_screen.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/fake_home_care.dart';
import '../test/support/fake_home_care_v2.dart';
import '../test/support/home_care_fixtures.dart';
import '../test/support/home_care_routine_fixtures.dart';
import '../test/support/household_fixtures.dart';
import 'home_care_v2_press.dart';
import 'review_press.dart';

/// Home care's V2 screens in the design-review press (home-care ADR-0004 to
/// ADR-0006): the parent's routines, the helper's rooms today in isiZulu,
/// the stock, and everybody's languages, in both themes.
///
///     flutter test tool/home_care_v2_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  final bathroomDaily = RoutineFixtures.everyDay(
    id: 'bath',
    name: 'Bathroom, every day',
    roomId: 'bathroom',
    items: const [
      JobStep(id: 'i1', text: 'Clean the toilet'),
      JobStep(id: 'i2', text: 'Wipe the basin'),
    ],
  );
  final kitchenDeep = RoutineFixtures.everyDay(
    id: 'kitchen-deep',
    name: 'Kitchen deep clean',
  ).copyWith(cadence: RoutineCadence.deepClean);

  Future<void> press(
    WidgetTester tester,
    String name, {
    required Widget screen,
    required Brightness brightness,
    HouseholdView? view,
    HelperLanguage language = HelperLanguage.english,
  }) async {
    final jobs = FakeCleaningJobRepository();
    final library = FakeHomeCareLibraryRepository();
    final routines = FakeRoutineRepository();
    addTearDown(jobs.close);
    addTearDown(library.close);
    addTearDown(routines.close);
    final householdView = view ?? Fixtures.view();
    final home = HomeCareController(
      jobRepository: jobs,
      libraryRepository: library,
      householdId: Fixtures.householdId,
      household: householdView,
    );
    addTearDown(home.dispose);
    final today = HouseholdClock('Africa/Johannesburg').today;
    final routinesController = RoutinesController(
      routineRepository: routines,
      householdId: Fixtures.householdId,
      today: today,
      access: home.access,
    );
    addTearDown(routinesController.dispose);
    final v2 = HomeCareV2Press(home);
    addTearDown(v2.close);

    await captureScreen(
      tester,
      name,
      screen: screen,
      providers: [
        ChangeNotifierProvider<HomeCareController>.value(value: home),
        ChangeNotifierProvider<RoutinesController>.value(
          value: routinesController,
        ),
        ...v2.providers,
      ],
      brightness: brightness,
      view: householdView,
      emit: () async {
        jobs.emitJobs(const []);
        library.emitRooms([
          HomeCareFixtures.kitchen,
          HomeCareFixtures.bathroom,
        ]);
        library.emitProducts([
          HomeCareFixtures.bleach.copyWith(
            stock: StockLevel.low,
            stockChangedBy: Fixtures.thandiMemberId,
          ),
          HomeCareFixtures.glassCleaner.copyWith(stock: StockLevel.half),
          HomeCareFixtures.soap,
        ]);
        final kitchen = RoutineFixtures.everyDay();
        routines
          ..emitRoutines([kitchen, bathroomDaily, kitchenDeep])
          ..emitTicks([
            RoutineFixtures.tick(kitchen, today, ['i1', 'i2']),
            RoutineFixtures.tick(bathroomDaily, today, ['i1', 'i2']),
          ]);
        v2.speak(language);
        await tester.pump();
        routinesController.follow(home.access, home.board);
        v2.listen();
        await tester.pump();
      },
    );
  }

  for (final brightness in Brightness.values) {
    testWidgets('the room routines — ${brightness.name}', (tester) async {
      await press(
        tester,
        'home-care-routines-${brightness.name}',
        screen: const RoutinesScreen(),
        brightness: brightness,
      );
    });

    testWidgets('today’s rooms, in isiZulu — ${brightness.name}', (
      tester,
    ) async {
      await press(
        tester,
        'home-care-today-${brightness.name}',
        screen: const TodayRoomsScreen(),
        brightness: brightness,
        view: HomeCareFixtures.helperView(),
        language: HelperLanguage.isiZulu,
      );
    });

    testWidgets('the stock — ${brightness.name}', (tester) async {
      await press(
        tester,
        'home-care-stock-${brightness.name}',
        screen: const StockScreen(),
        brightness: brightness,
        view: HomeCareFixtures.helperView(),
      );
    });

    testWidgets('everybody’s languages — ${brightness.name}', (tester) async {
      await press(
        tester,
        'home-care-languages-${brightness.name}',
        screen: const LanguagesScreen(),
        brightness: brightness,
      );
    });
  }
}
