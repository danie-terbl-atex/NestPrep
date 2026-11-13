import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/accounts/model/account.dart';
import 'package:nestprep/features/accounts/model/auth_user.dart';
import 'package:nestprep/features/accounts/model/kid_identity.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/meal_planning/model/week_plan.dart';
import 'package:nestprep/features/recipes/model/recipe_draft.dart';
import 'package:nestprep/features/recipes/model/recipe_facet.dart';
import 'package:nestprep/features/recipes/model/recipe_import_way.dart';
import 'package:nestprep/features/recipes/model/recipe_shelf.dart';
import 'package:nestprep/features/recipes/ui/own_recipes_entry.dart';
import 'package:nestprep/features/recipes/ui/recipe_discovery_view.dart';
import 'package:nestprep/features/recipes/ui/recipe_picker_screen.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_auth.dart';
import '../../../support/fake_feature_flag_source.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';
import '../../../support/pump_subscriptions.dart';
import '../../../support/recipe_fixtures.dart';
import '../../../support/recipe_harness.dart';

void main() {
  setUpAll(tz_data.initializeTimeZones);

  late RecipeHarness harness;
  late List<RecipeDraft?> opened;
  late List<RecipeImportWay> imported;

  setUp(() {
    harness = RecipeHarness(ownRecipesOf: Fixtures.householdId);
    opened = [];
    imported = [];
  });

  tearDown(() => harness.close());

  const addButton = ValueKey('own-recipes-add');
  const card = ValueKey('own-recipes-card');

  Future<void> pump(
    WidgetTester tester, {
    bool isPremium = true,
    bool flagOn = true,
    HouseholdView? view,
    List<SingleChildWidget> also = const [],
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size((scale > 1 ? 360 : 390) * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpScreen(
      tester,
      Scaffold(
        body: RecipeDiscoveryView(
          onOpen: (_, _) {},
          addEntry: OwnRecipesEntry(
            onOpenBuilder: opened.add,
            onImport: imported.add,
            onImportPdf: () {},
          ),
        ),
      ),
      providers: [
        ...harness.providers,
        ...SubscriptionHarness(
          entitlement: isPremium
              ? Entitlement(premiumUntil: DateTime.utc(2100))
              : Entitlement.free,
        ).providers,
        featureFlagsProvider(defaultOn: flagOn),
        ...also,
      ],
      view: view,
      brightness: brightness,
      textScale: scale,
    );
  }

  Future<void> deliver(WidgetTester tester, {bool hasOwn = false}) async {
    harness.recipes.emitCatalogue(RecipeFixtures.catalogue);
    harness.recipes.emitOwn([if (hasOwn) RecipeFixtures.own()]);
    await tester.pumpAndSettle();
  }

  Future<void> shelfInView(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text(RecipeCopy.shelf(RecipeShelfKind.ours)),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a free household sees the upsell, and Add opens the paywall on '
      'this feature', (tester) async {
    await pump(tester, isPremium: false);
    await deliver(tester);
    expect(find.byKey(card), findsOneWidget);
    expect(find.text(OwnRecipeCopy.premiumTag), findsOneWidget);

    await tester.tap(find.byKey(addButton));
    await tester.pumpAndSettle();
    expect(
      find.text(SubscriptionCopy.headline(PremiumFeature.ownRecipes)),
      findsOneWidget,
    );
    expect(opened, isEmpty);
    expect(imported, isEmpty);
    expect(find.text(RecipeImportCopy.linkTitle), findsNothing);
  });

  group('a premium household is offered three ways', () {
    Future<void> openWays(WidgetTester tester) async {
      await pump(tester);
      await deliver(tester);
      expect(find.text(OwnRecipeCopy.premiumTag), findsNothing);
      await tester.tap(find.byKey(addButton));
      await tester.pumpAndSettle();
      expect(find.text(RecipeImportCopy.typeTitle), findsOneWidget);
      expect(find.text(RecipeImportCopy.linkTitle), findsOneWidget);
      expect(find.text(RecipeImportCopy.snapTitle), findsOneWidget);
    }

    testWidgets('Type opens an empty builder', (tester) async {
      await openWays(tester);
      await tester.tap(find.byKey(const ValueKey('recipe-add-type')));
      await tester.pumpAndSettle();
      expect(opened, [null]);
      expect(imported, isEmpty);
    });

    testWidgets('Link opens the import on its link', (tester) async {
      await openWays(tester);
      await tester.tap(find.byKey(const ValueKey('recipe-add-link')));
      await tester.pumpAndSettle();
      expect(imported, [RecipeImportWay.link]);
      expect(opened, isEmpty);
    });

    testWidgets('Snap opens the import on its photo', (tester) async {
      await openWays(tester);
      await tester.tap(find.byKey(const ValueKey('recipe-add-snap')));
      await tester.pumpAndSettle();
      expect(imported, [RecipeImportWay.snap]);
      expect(opened, isEmpty);
    });

    testWidgets('closing the sheet opens nothing', (tester) async {
      await openWays(tester);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(opened, isEmpty);
      expect(imported, isEmpty);
    });

    testWidgets('fits at 200% text, 360 wide, in the dark', (tester) async {
      await pump(tester, brightness: Brightness.dark, scale: 2);
      await deliver(tester);
      await tester.tap(find.byKey(addButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('a household that already has some gets a plain button and the '
      'shelf with one recipe on it', (tester) async {
    await pump(tester);
    await deliver(tester, hasOwn: true);
    expect(find.byKey(addButton), findsOneWidget);
    expect(find.byKey(card), findsNothing);
    expect(find.text(RecipeCopy.facet(RecipeFacet.ours)), findsOneWidget);
    await shelfInView(tester);
    expect(find.text(RecipeCopy.shelf(RecipeShelfKind.ours)), findsOneWidget);
  });

  testWidgets('a lapsed household still reads its recipes, and Add goes '
      'through the paywall', (tester) async {
    await pump(tester, isPremium: false);
    await deliver(tester, hasOwn: true);
    expect(find.byKey(card), findsOneWidget);

    await tester.tap(find.byKey(addButton));
    await tester.pumpAndSettle();
    expect(
      find.text(SubscriptionCopy.headline(PremiumFeature.ownRecipes)),
      findsOneWidget,
    );
    expect(opened, isEmpty);
  });

  testWidgets('a lapsed household still finds its recipes on the shelf', (
    tester,
  ) async {
    await pump(tester, isPremium: false);
    await deliver(tester, hasOwn: true);
    await shelfInView(tester);
    expect(find.text(RecipeFixtures.own().name), findsOneWidget);
  });

  testWidgets('with the switch off, Add goes and existing recipes stay', (
    tester,
  ) async {
    await pump(tester, flagOn: false);
    await deliver(tester, hasOwn: true);
    expect(find.byKey(addButton), findsNothing);
    await shelfInView(tester);
    expect(find.text(RecipeCopy.shelf(RecipeShelfKind.ours)), findsOneWidget);
  });

  testWidgets('a helper who may only look at meals sees no way to add', (
    tester,
  ) async {
    await pump(
      tester,
      view: Fixtures.helperView(
        AccessGrant({HouseholdArea.meals: AccessLevel.view}),
      ),
    );
    await deliver(tester, hasOwn: true);
    expect(find.byKey(addButton), findsNothing);
    await shelfInView(tester);
    expect(find.text(RecipeCopy.shelf(RecipeShelfKind.ours)), findsOneWidget);
  });

  testWidgets('a kid device sees no way to add', (tester) async {
    final auth = FakeAuthGateway();
    final accounts = FakeAccountRepository();
    final session = SessionController(
      authGateway: auth,
      accountRepository: accounts,
    );
    addTearDown(() async {
      session.dispose();
      await auth.close();
      await accounts.close();
    });
    auth.emit(
      const AuthUser(
        uid: 'uid-kid',
        email: '',
        kid: KidIdentity(
          householdId: Fixtures.householdId,
          memberId: Fixtures.kidMemberId,
        ),
      ),
    );
    accounts.emit(const Account(id: 'uid-kid', displayName: 'Kid'));
    await tester.pump();
    await pump(
      tester,
      also: [ChangeNotifierProvider<SessionController>.value(value: session)],
    );
    await deliver(tester);
    expect(find.byKey(addButton), findsNothing);
  });

  testWidgets('an own-recipes failure says so, keeps the catalogue, and '
      'retries', (tester) async {
    await pump(tester);
    harness.recipes.emitCatalogue(RecipeFixtures.catalogue);
    harness.recipes.failOwnWith(const UnavailableFailure());
    await tester.pumpAndSettle();
    expect(find.text(OwnRecipeCopy.unreadable), findsOneWidget);
    expect(find.text(RecipeCopy.tonightEyebrow.toUpperCase()), findsOneWidget);

    await tester.tap(find.text(AppCopy.retry));
    await tester.pumpAndSettle();
    harness.recipes.emitOwn([RecipeFixtures.own()]);
    await tester.pumpAndSettle();
    expect(find.text(OwnRecipeCopy.unreadable), findsNothing);
    await shelfInView(tester);
    expect(find.text(RecipeCopy.shelf(RecipeShelfKind.ours)), findsOneWidget);
  });

  testWidgets('the picker offers own recipes, and no way to add', (
    tester,
  ) async {
    final picked = <String>[];
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpScreen(
      tester,
      RecipePickerScreen(
        slot: MealSlot.dinner,
        day: CalendarDate(2026, 10, 22),
        today: CalendarDate(2026, 10, 22),
        onPick: (recipe) => picked.add(recipe.id),
        onBack: () {},
      ),
      providers: harness.providers,
    );
    await deliver(tester, hasOwn: true);
    expect(find.byKey(addButton), findsNothing);
    await tester.tap(find.text(RecipeCopy.facet(RecipeFacet.ours)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(RecipeFixtures.own().name));
    expect(picked, [RecipeFixtures.ownRecipeId]);
  });

  testWidgets('fits at 200% text, 360 wide, in the dark', (tester) async {
    await pump(tester, isPremium: false, brightness: Brightness.dark, scale: 2);
    await deliver(tester, hasOwn: true);
    expect(tester.takeException(), isNull);
  });
}
