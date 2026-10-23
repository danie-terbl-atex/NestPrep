import 'package:nestprep/features/add_to_checkers/data/checkers_place_resolver.dart';
import 'package:nestprep/features/plan_week/data/shop_week_groceries.dart';
import 'package:nestprep/features/plan_week/state/plan_week_controller.dart';
import 'package:nestprep/features/plan_week/state/shop_week_saver.dart';

import 'fake_checkers.dart';
import 'fake_live_location.dart';
import 'fake_plan_week.dart';
import 'household_fixtures.dart';
import 'lunch_fixtures.dart';
import 'lunch_planning_harness.dart';

/// *Plan my week* over fakes, following the lunch board — the setup the
/// Twig tests start from.
final class PlanWeekRig {
  PlanWeekRig() {
    controller = PlanWeekController(
      drafter: drafter,
      aisleSource: aisle,
      weekBuilder: builder,
      catalogues: planWeekCatalogues(shop),
      shopChoice: planWeekShopChoice(Fixtures.householdId),
      isPnpOn: () => false,
      placeResolver: CheckersPlaceResolver(
        locationSource: FakeLocationSource(),
        areaPreference: FakeCheckersAreaPreference(),
      ),
      saver: ShopWeekSaver(
        lunchRepository: harness.lunch.repository,
        budgetRepository: harness.budgetRepository,
        recipeSaver: recipeSaver,
        householdId: Fixtures.householdId,
        memberId: Fixtures.samMemberId,
      ),
      groceries: ShopWeekGroceries(
        groceryRepository: harness.groceries,
        householdId: Fixtures.householdId,
        memberId: Fixtures.samMemberId,
      ),
      packingStore: FakePackingChoiceStore(),
      householdId: Fixtures.householdId,
      week: LunchFixtures.week,
    );
    harness.board.addListener(_follow);
  }

  final harness = LunchPlanningHarness();
  final drafter = FakeLunchIdeaDrafter();
  final recipeSaver = FakeLunchRecipeSaver();
  final aisle = FakeLunchAisleSource();
  final builder = FakeLunchWeekBuilder();
  final shop = FakeShopCatalogue();
  late final PlanWeekController controller;

  void _follow() => controller.followBoard(harness.board.board);

  Future<void> close() async {
    harness.board.removeListener(_follow);
    controller.dispose();
    await harness.close();
  }
}
