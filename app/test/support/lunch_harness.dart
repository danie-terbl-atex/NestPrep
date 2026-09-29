import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/family_roster.dart';
import 'package:nestprep/features/lunch_box/model/lunch_favourite.dart';
import 'package:nestprep/features/lunch_box/model/lunch_item.dart';
import 'package:nestprep/features/lunch_box/model/lunch_plan.dart';
import 'package:nestprep/features/lunch_box/model/lunch_prep.dart';
import 'package:nestprep/features/lunch_box/state/lunch_board_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import 'fake_lunch_repository.dart';
import 'household_fixtures.dart';
import 'lunch_fixtures.dart';

/// A lunch controller over a fake repository, on Tuesday 29 September 2026,
/// with the two children of `LunchFixtures` — the one setup every lunch
/// controller and screen test starts from.
final class LunchHarness {
  LunchHarness({bool canEdit = true}) {
    tz_data.initializeTimeZones();
    controller = LunchBoardController(
      lunchRepository: repository,
      householdClock: HouseholdClock(
        'Africa/Johannesburg',
        now: () => LunchFixtures.nowUtc,
      ),
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
      canEdit: canEdit,
    );
  }

  final repository = FakeLunchRepository();
  late final LunchBoardController controller;

  /// Every read answers, in the order a device usually sees them — and the
  /// events are let through, for a plain test.
  Future<void> arrive({
    FamilyRoster? roster,
    List<LunchItem>? items,
    List<LunchPlan> plans = const [],
    List<LunchFavourite> favourites = const [],
    LunchPrep? prep,
  }) async {
    emit(
      roster: roster,
      items: items,
      plans: plans,
      favourites: favourites,
      prep: prep,
    );
    await pumpEventQueue();
  }

  /// The same answers without waiting, for a widget test: its clock is fake,
  /// so `pumpEventQueue` never returns there — `tester.pumpAndSettle` is what
  /// lets the events through.
  void emit({
    FamilyRoster? roster,
    List<LunchItem>? items,
    List<LunchPlan> plans = const [],
    List<LunchFavourite> favourites = const [],
    LunchPrep? prep,
  }) {
    controller.followRoster(AsyncData(roster ?? LunchFixtures.roster()));
    repository
      ..emitItems(items ?? LunchFixtures.library)
      ..emitFavourites(favourites)
      ..emitPlans(plans)
      ..emitPrep(prep ?? LunchPrep.empty(controller.week.key));
  }

  Future<void> close() async {
    controller.dispose();
    await repository.close();
  }
}
