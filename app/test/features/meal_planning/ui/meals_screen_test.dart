import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/meal_planning/model/meal.dart';
import 'package:nestprep/features/meal_planning/model/meals_view.dart';
import 'package:nestprep/features/meal_planning/model/week_plan.dart';
import 'package:nestprep/features/meal_planning/state/meal_plan_controller.dart';
import 'package:nestprep/features/meal_planning/ui/meals_screen.dart';
import 'package:nestprep/features/meal_planning/ui/planned_day_card.dart';
import 'package:nestprep/features/meal_planning/ui/slot_picker_sheet.dart';
import 'package:nestprep/features/recipes/model/recipe_link.dart';
import 'package:nestprep/features/recipes/ui/recipe_discovery_view.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/features/subscriptions/ui/paywall_page.dart';
import 'package:nestprep/features/subscriptions/ui/premium_area.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_recipe_photos.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';
import '../../../support/pump_subscriptions.dart';
import '../../../support/recipe_fixtures.dart';
import '../../../support/recipe_harness.dart';

/// The Meals tab (design-system ADR-0015): recipes or this week under one
/// header, the choice the route's; and on the week, a meal planned from a
/// recipe carries its photo and the way back into it (recipes ADR-0003 §6).
void main() {
  setUpAll(tz_data.initializeTimeZones);

  late RecipeHarness harness;
  late FakeRecipePhotoSource photos;
  late MealPlanController plan;
  late List<MealsView> views;
  late List<String> opened;
  late SubscriptionHarness subscriptions;

  setUp(() {
    photos = FakeRecipePhotoSource();
    harness = RecipeHarness(photos: photos);
    plan = MealPlanController(
      mealRepository: harness.meals,
      householdClock: harness.clock,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
    );
    views = [];
    opened = [];
  });

  tearDown(() async {
    plan.dispose();
    await harness.close();
  });

  Future<void> pump(
    WidgetTester tester,
    MealsView? view, {
    bool isPremium = true,
    Brightness brightness = Brightness.light,
    double scale = 1,
    RecipePicker? onPickRecipe,
  }) {
    subscriptions = SubscriptionHarness(
      entitlement: isPremium
          ? Entitlement(premiumUntil: DateTime.utc(2100))
          : Entitlement.free,
    );
    return pumpScreen(
      tester,
      MealsScreen(
        view: view,
        onSelectView: views.add,
        onSelectTab: (_) {},
        onPickRecipe: onPickRecipe ?? (_, _) async => null,
        onOpenRecipe: (id, {heroTag}) => opened.add(id),
      ),
      providers: [
        ...harness.providers,
        ...subscriptions.providers,
        ChangeNotifierProvider<MealPlanController>.value(value: plan),
      ],
      brightness: brightness,
      textScale: scale,
    );
  }

  final fromRecipe = Meal.named(
    id: Meal.idForRecipe('bobotie'),
    name: 'Bobotie',
    addedBy: Fixtures.samMemberId,
  ).copyWith(recipeId: 'bobotie');
  final typed = Meal.named(
    id: 'spag',
    name: 'Spaghetti',
    addedBy: Fixtures.samMemberId,
  );

  Future<void> planned(WidgetTester tester) async {
    harness.recipes.emitCatalogue(RecipeFixtures.catalogue);
    harness.meals
      ..emitMeals([fromRecipe, typed])
      ..emitWeek(
        WeekPlan(
          id: plan.weekStart.iso,
          slots: {'4_dinner': fromRecipe.id, '4_lunch': typed.id},
        ),
      );
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the recipes, and the switch asks for the week', (
    tester,
  ) async {
    await pump(tester, MealsView.recipes);
    harness.recipes.emitCatalogue(RecipeFixtures.catalogue);
    await tester.pumpAndSettle();

    expect(find.text(RecipeCopy.searchLabel), findsOneWidget);
    await tester.tap(find.text(MealsCopy.thisWeek));
    expect(views, [MealsView.week]);
  });

  testWidgets('the week shows the plan, and the switch asks for recipes', (
    tester,
  ) async {
    await pump(tester, MealsView.week);
    await planned(tester);

    expect(find.text(AppCopy.mealsCopyLastWeek), findsOneWidget);
    await tester.tap(find.text(MealsCopy.recipes));
    expect(views, [MealsView.recipes]);
  });

  testWidgets('a meal planned from a recipe shows its photo and how to make '
      'it; a typed one does not', (tester) async {
    await pump(tester, MealsView.week);
    await planned(tester);
    await tester.dragUntilVisible(
      find.text('Bobotie'),
      find.byType(Scrollable).last,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();

    expect(find.text(RecipeCopy.howToMakeShort), findsOneWidget);
    expect(photos.asked, contains(RecipeFixtures.bobotie.photo!.card));

    await tester.tap(find.text(RecipeCopy.howToMakeShort));
    expect(opened, ['bobotie']);
  });

  group('a household\'s own recipe on the week (recipes ADR-0007)', () {
    Future<void> plannedOwn(WidgetTester tester, Meal meal) async {
      harness.recipes.emitCatalogue(RecipeFixtures.catalogue);
      harness.meals.emitMeals([meal]);
      harness.meals.emitWeek(
        WeekPlan(
          id: harness.clock.today.weekStart.iso,
          slots: {
            WeekPlan.slotKey(harness.clock.today.weekday, MealSlot.dinner):
                meal.id,
          },
        ),
      );
      await tester.pumpAndSettle();
    }

    const ownId = RecipeFixtures.ownRecipeId;

    testWidgets('shows how to make it, through the household\'s link', (
      tester,
    ) async {
      await pump(tester, MealsView.week);
      await plannedOwn(
        tester,
        Meal.ofRecipe(
          link: const HouseholdRecipeLink(ownId),
          name: 'Gran\'s bobotie',
          ingredients: const [],
          addedBy: Fixtures.samMemberId,
        ),
      );
      await tester.dragUntilVisible(
        find.text(RecipeCopy.howToMakeShort),
        find.byType(Scrollable).last,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(RecipeCopy.howToMakeShort));
      expect(opened, [ownId]);
    });

    testWidgets('once its recipe has gone it is a plain meal, still on the '
        'week', (tester) async {
      await pump(tester, MealsView.week);
      await plannedOwn(
        tester,
        Meal.named(
          id: Meal.idForRecipe(ownId),
          name: 'Gran\'s bobotie',
          addedBy: Fixtures.samMemberId,
        ),
      );
      await tester.dragUntilVisible(
        find.text('Gran\'s bobotie'),
        find.byType(Scrollable).last,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      expect(find.text('Gran\'s bobotie'), findsOneWidget);
      expect(find.text(RecipeCopy.howToMakeShort), findsNothing);
    });
  });

  testWidgets('an empty slot picks a NestPrep recipe and plans it there', (
    tester,
  ) async {
    final asked = <(MealSlot, CalendarDate)>[];
    await pump(
      tester,
      MealsView.week,
      onPickRecipe: (slot, day) async {
        asked.add((slot, day));
        return RecipeFixtures.bobotie;
      },
    );
    harness.recipes.emitCatalogue(RecipeFixtures.catalogue);
    harness.meals
      ..emitMeals([])
      ..emitWeek(WeekPlan.empty(plan.weekStart));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppCopy.mealsNothingPlanned).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(MealsCopy.pickRecipe));
    await tester.pumpAndSettle();

    expect(asked, [(MealSlot.breakfast, plan.weekStart)]);
    expect(harness.meals.recipeMeals.single.recipeId, 'bobotie');
    expect(harness.meals.writtenSlots.single.slots, {
      WeekPlan.slotKey(plan.weekStart.weekday, MealSlot.breakfast):
          Meal.idForRecipe('bobotie'),
    });
  });

  testWidgets('backing out of the recipes writes nothing', (tester) async {
    await pump(tester, MealsView.week);
    harness.meals
      ..emitMeals([])
      ..emitWeek(WeekPlan.empty(plan.weekStart));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppCopy.mealsNothingPlanned).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(MealsCopy.pickRecipe));
    await tester.pumpAndSettle();

    expect(harness.meals.recipeMeals, isEmpty);
    expect(harness.meals.writtenSlots, isEmpty);
  });

  group('without Premium (subscriptions ADR-0008)', () {
    Future<void> emptyWeek(WidgetTester tester) async {
      harness.meals
        ..emitMeals([])
        ..emitWeek(WeekPlan.empty(plan.weekStart));
      await tester.pumpAndSettle();
    }

    testWidgets('opens on the week when the route names no view', (
      tester,
    ) async {
      await pump(tester, null, isPremium: false);
      await emptyWeek(tester);

      expect(find.text(AppCopy.mealsCopyLastWeek), findsOneWidget);
      expect(find.byType(PremiumLockedView), findsNothing);
    });

    testWidgets('with Premium it opens on the recipes instead', (tester) async {
      await pump(tester, null);
      harness.recipes.emitCatalogue(RecipeFixtures.catalogue);
      await tester.pumpAndSettle();

      expect(find.byType(RecipeDiscoveryView), findsOneWidget);
    });

    testWidgets('the recipes stay on the switch, locked, and the way in is '
        'the paywall', (tester) async {
      await pump(tester, MealsView.recipes, isPremium: false);
      await tester.pumpAndSettle();

      expect(find.text(MealsCopy.recipes), findsOneWidget);
      expect(find.byIcon(LucideIcons.lock), findsWidgets);
      expect(find.byType(RecipeDiscoveryView), findsNothing);
      expect(
        find.text(SubscriptionCopy.headline(PremiumFeature.recipes)),
        findsOneWidget,
      );

      await tester.tap(find.text(SubscriptionCopy.seePremium));
      await tester.pumpAndSettle();
      expect(find.byType(PaywallPage), findsOneWidget);
      expect(
        subscriptions.paywallOpens.opened.single.trigger,
        PremiumFeature.recipes,
      );
    });

    testWidgets('a typed meal is planned as ever', (tester) async {
      await pump(tester, MealsView.week, isPremium: false);
      await emptyWeek(tester);

      await tester.tap(find.text(AppCopy.mealsNothingPlanned).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Toast');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.byType(PaywallPage), findsNothing);
      expect(harness.meals.writtenSlots, isNotEmpty);
    });

    testWidgets('picking a recipe for a slot is shown, locked, and asks for '
        'Premium before any recipe is asked for', (tester) async {
      final asked = <MealSlot>[];
      await pump(
        tester,
        MealsView.week,
        isPremium: false,
        onPickRecipe: (slot, _) async {
          asked.add(slot);
          return RecipeFixtures.bobotie;
        },
      );
      await emptyWeek(tester);

      await tester.tap(find.text(AppCopy.mealsNothingPlanned).first);
      await tester.pumpAndSettle();
      expect(find.textContaining(SubscriptionCopy.lockedHint), findsOneWidget);
      await tester.tap(find.text(MealsCopy.pickRecipe));
      await tester.pumpAndSettle();

      expect(find.byType(PaywallPage), findsOneWidget);
      expect(
        subscriptions.paywallOpens.opened.single.trigger,
        PremiumFeature.recipes,
      );
      expect(asked, isEmpty);
      expect(harness.meals.recipeMeals, isEmpty);
      expect(harness.meals.writtenSlots, isEmpty);
    });

    testWidgets('a meal planned from a recipe before stays on the week by '
        'name, and how to make it still leads to its page', (tester) async {
      await pump(tester, MealsView.week, isPremium: false);
      await planned(tester);
      await tester.dragUntilVisible(
        find.text('Bobotie'),
        find.byType(Scrollable).last,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Bobotie'), findsOneWidget);
      expect(photos.asked, isEmpty);
      await tester.tap(find.text(RecipeCopy.howToMakeShort));
      expect(opened, ['bobotie']);
    });

    testWidgets('renders locked in dark and at 200% text on a 360-wide '
        'phone', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await pump(
        tester,
        MealsView.recipes,
        isPremium: false,
        brightness: Brightness.dark,
        scale: 2,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(PremiumLockedView), findsOneWidget);
    });

    testWidgets('renders the locked slot picker in dark and at 200% text on '
        'a 360-wide phone', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await pumpScreen(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showSlotPickerSheet(
                context: context,
                slot: MealSlot.dinner,
                date: harness.clock.today,
                today: harness.clock.today,
                library: [typed],
                isRecipeLocked: true,
              ),
              child: const Text('open'),
            ),
          ),
        ),
        providers: const [],
        brightness: Brightness.dark,
        textScale: 2,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.textContaining(SubscriptionCopy.lockedHint), findsOneWidget);
      expect(find.text(MealsCopy.pickRecipe), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('renders the week in dark and at 200% text on a 360-wide phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(tester, MealsView.week, brightness: Brightness.dark, scale: 2);
    await planned(tester);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -1500));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
