import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/accounts/model/account.dart';
import 'package:nestprep/features/accounts/model/auth_user.dart';
import 'package:nestprep/features/accounts/model/kid_identity.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/recipes/model/recipe.dart';
import 'package:nestprep/features/recipes/model/recipe_photo.dart';
import 'package:nestprep/features/recipes/state/recipe_catalogue_controller.dart';
import 'package:nestprep/features/recipes/state/recipe_page_controller.dart';
import 'package:nestprep/features/recipes/ui/recipe_allergens.dart';
import 'package:nestprep/features/recipes/ui/recipe_gallery.dart';
import 'package:nestprep/features/recipes/ui/recipe_photo_credit.dart';
import 'package:nestprep/features/recipes/ui/recipe_screen.dart';
import 'package:nestprep/features/recipes/ui/recipe_sheet.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/features/subscriptions/state/household_entitlement.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_auth.dart';
import '../../../support/fake_feature_flag_source.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/own_recipe_page.dart';
import '../../../support/pump_screen.dart';
import '../../../support/pump_subscriptions.dart';
import '../../../support/recipe_fixtures.dart';
import '../../../support/recipe_harness.dart';

void main() {
  setUpAll(tz_data.initializeTimeZones);

  late RecipeHarness harness;
  late OwnRecipePage page;

  setUp(() {
    harness = RecipeHarness();
    page = OwnRecipePage(harness);
  });

  tearDown(() => harness.close());

  Future<void> open(
    WidgetTester tester,
    Recipe recipe, {
    bool isPremium = true,
    bool flagOn = true,
    SubscriptionHarness? subscription,
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    final premium =
        subscription ??
        SubscriptionHarness(
          entitlement: isPremium
              ? Entitlement(premiumUntil: DateTime.utc(2100))
              : Entitlement.free,
        );
    await page.pump(
      tester,
      recipeId: recipe.id,
      providers: [
        ...premium.providers,
        featureFlagsProvider(defaultOn: flagOn),
        ChangeNotifierProvider<HouseholdEntitlement>(
          lazy: false,
          create: (_) => HouseholdEntitlement(
            entitlementRepository: premium.entitlements,
            householdId: Fixtures.householdId,
          ),
        ),
      ],
      brightness: brightness,
      scale: scale,
    );
    harness.recipes.emitCatalogue([...RecipeFixtures.catalogue, recipe]);
    await tester.pumpAndSettle();
  }

  Finder listOf() => find.byType(Scrollable).first;

  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.dragUntilVisible(target, listOf(), const Offset(0, -250));
    await tester.pumpAndSettle();
  }

  group('allergens: never an all-clear', () {
    Future<void> pumpAllergens(
      WidgetTester tester,
      Set<Allergen> allergens, {
      required bool isOwn,
    }) => pumpScreen(
      tester,
      Scaffold(
        body: RecipeAllergens(allergens: allergens, isOwn: isOwn),
      ),
      providers: const [],
    );

    testWidgets('an own recipe with nothing found has no shield and says to '
        'check', (tester) async {
      await pumpAllergens(tester, const {}, isOwn: true);
      expect(find.text(RecipeCopy.containsNone), findsNothing);
      expect(find.byIcon(LucideIcons.shieldCheck), findsNothing);
      expect(find.text(OwnRecipeCopy.allergensNoneFound), findsOneWidget);
    });

    testWidgets('an own recipe lists what was found, and still says to check', (
      tester,
    ) async {
      await pumpAllergens(tester, const {Allergen.egg}, isOwn: true);
      expect(find.text(FamilyCopy.allergenName(Allergen.egg)), findsOneWidget);
      expect(find.text(OwnRecipeCopy.allergensFound), findsOneWidget);
      expect(find.byIcon(LucideIcons.shieldCheck), findsNothing);
    });

    testWidgets('a catalogue recipe keeps its shield', (tester) async {
      await pumpAllergens(tester, const {}, isOwn: false);
      expect(find.text(RecipeCopy.containsNone), findsOneWidget);
      expect(find.byIcon(LucideIcons.shieldCheck), findsOneWidget);
      expect(find.text(OwnRecipeCopy.allergensNoneFound), findsNothing);
    });

    testWidgets(
      'an Afrikaans-only recipe, on its whole page, gets no all-clear',
      (tester) async {
        final afrikaans =
            RecipeFixtures.own(
              name: 'Ouma se melktert',
              allergens: const {},
            ).copyWith(
              summary: 'Met eiers en botter.',
              steps: const ['Klop die eiers.'],
            );
        await open(tester, afrikaans);
        await scrollTo(tester, find.text(OwnRecipeCopy.allergensNoneFound));
        expect(find.text(RecipeCopy.containsNone), findsNothing);
        expect(find.text(OwnRecipeCopy.allergensNoneFound), findsOneWidget);
      },
    );

    testWidgets('the sheet says the same as the page', (tester) async {
      await pumpScreen(
        tester,
        Scaffold(
          body: RecipeSheet(recipe: RecipeFixtures.own(allergens: const {})),
        ),
        providers: const [],
      );
      expect(find.text(RecipeCopy.containsNone), findsNothing);
      expect(find.text(OwnRecipeCopy.allergensNoneFound), findsOneWidget);
    });
  });

  group('the photo\'s caption', () {
    Future<void> caption(
      WidgetTester tester,
      RecipePhoto photo, {
      required bool isOwn,
    }) => pumpScreen(
      tester,
      Scaffold(
        body: RecipePhotoCredit(photo: photo, isOwn: isOwn),
      ),
      providers: const [],
    );

    testWidgets('a family\'s own photo is never called illustrative', (
      tester,
    ) async {
      await caption(tester, RecipeFixtures.ownPhoto('abcdefgh'), isOwn: true);
      expect(find.text(RecipeCopy.photoIllustrative), findsNothing);
    });

    testWidgets('a site\'s photo keeps its credit', (tester) async {
      await caption(
        tester,
        RecipeFixtures.ownPhoto('abcdefgh', credit: 'Drizzle and Dip'),
        isOwn: true,
      );
      expect(find.textContaining('Drizzle and Dip'), findsOneWidget);
    });

    testWidgets('a catalogue photo with no credit stays an illustration', (
      tester,
    ) async {
      await caption(
        tester,
        const RecipePhoto(card: 'c', hero: 'h'),
        isOwn: false,
      );
      expect(find.text(RecipeCopy.photoIllustrative), findsOneWidget);
    });
  });

  group('the page', () {
    testWidgets('shows tips, and the link it came from', (tester) async {
      await open(
        tester,
        RecipeFixtures.own(
          notes: 'Better the next day.',
          sourceUrl: 'https://www.drizzleanddip.com/bobotie',
        ),
      );
      expect(find.text('From drizzleanddip.com'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('own-recipe-source')));
      await tester.pump();
      expect(page.linkOpener.opened.single.host, 'www.drizzleanddip.com');

      await scrollTo(tester, find.text('Better the next day.'));
      expect(find.text(OwnRecipeCopy.tips), findsOneWidget);
    });

    testWidgets('names the site when it knows its name', (tester) async {
      await open(
        tester,
        RecipeFixtures.own(
          sourceUrl: 'https://drizzleanddip.com/bobotie',
          sourceName: 'Drizzle and Dip',
        ),
      );
      expect(find.text('From Drizzle and Dip'), findsOneWidget);
    });

    testWidgets('a link that is not a web page opens nothing', (tester) async {
      await open(tester, RecipeFixtures.own(sourceUrl: 'javascript:alert(1)'));
      expect(find.byKey(const ValueKey('own-recipe-source')), findsNothing);
    });

    testWidgets('swipes through its photos, cover first', (tester) async {
      await open(
        tester,
        RecipeFixtures.own(
          photo: RecipeFixtures.ownPhoto('abcdefgh'),
          gallery: [
            RecipeFixtures.ownPhoto('ijklmnop'),
            RecipeFixtures.ownPhoto('qrstuvwx'),
          ],
        ),
      );
      expect(find.byType(RecipeGallery), findsOneWidget);
      expect(find.text('1 / 3'), findsOneWidget);

      await tester.drag(
        find.byKey(const ValueKey('recipe-gallery')),
        const Offset(-400, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('2 / 3'), findsOneWidget);
    });

    testWidgets('the card\'s photo flies into a gallery and back', (
      tester,
    ) async {
      final own = RecipeFixtures.own(
        photo: RecipeFixtures.ownPhoto('abcdefgh'),
        gallery: [RecipeFixtures.ownPhoto('ijklmnop')],
      );
      const tag = 'recipe/ours/own';
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: Center(
                child: SizedBox.square(
                  dimension: 120,
                  child: GestureDetector(
                    onTap: () => context.push('/recipe'),
                    child: const NestPhotoFrame(
                      heroTag: tag,
                      child: ColoredBox(color: Colors.transparent),
                    ),
                  ),
                ),
              ),
            ),
            routes: [
              GoRoute(
                path: 'recipe',
                pageBuilder: (context, state) => NestPhotoPage<void>(
                  key: state.pageKey,
                  child:
                      ChangeNotifierProxyProvider<
                        RecipeCatalogueController,
                        RecipePageController
                      >(
                        create: (_) => RecipePageController(
                          mealRepository: harness.meals,
                          householdId: Fixtures.householdId,
                          memberId: Fixtures.samMemberId,
                          recipeId: own.id,
                          familySize: 4,
                        ),
                        update: (_, catalogue, page) =>
                            page!..followCatalogue(catalogue),
                        child: RecipeScreen(
                          heroTag: tag,
                          onBack: () => context.pop(),
                        ),
                      ),
                ),
              ),
            ],
          ),
        ],
      );
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await pumpRouter(tester, router: router, providers: harness.providers);
      harness.recipes.emitCatalogue([own]);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(NestPhotoFrame));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(find.byType(RecipeGallery), findsOneWidget);

      router.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(find.byType(RecipeGallery), findsNothing);
    });

    testWidgets('one photo is just a photo, with nothing to swipe', (
      tester,
    ) async {
      await open(
        tester,
        RecipeFixtures.own(photo: RecipeFixtures.ownPhoto('abcdefgh')),
      );
      expect(find.byType(RecipeGallery), findsNothing);
    });

    testWidgets('adding it to the week links the meal to the household\'s '
        'recipe, not the catalogue', (tester) async {
      await open(tester, RecipeFixtures.own());
      await tester.tap(find.text(RecipeCopy.addToWeek));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Add to ').last);
      await tester.pumpAndSettle();
      final added = harness.meals.recipeMeals.single;
      expect(added.link, RecipeFixtures.own().link);
      expect(
        harness.meals.writtenSlots.single.slots.values.single,
        contains(RecipeFixtures.ownRecipeId),
      );
    });

    testWidgets('fits at 200% text, 360 wide, in the dark', (tester) async {
      await open(
        tester,
        RecipeFixtures.own(
          photo: RecipeFixtures.ownPhoto('abcdefgh'),
          gallery: [
            RecipeFixtures.ownPhoto(
              'ijklmnop',
              credit: 'A very long site name',
            ),
          ],
          notes: 'Better the next day.',
          sourceUrl: 'https://drizzleanddip.com/bobotie',
          sourceName: 'A site with a name long enough to wrap on a small phone',
          allergens: const {},
        ),
        brightness: Brightness.dark,
        scale: 2,
      );
      expect(tester.takeException(), isNull);
      await scrollTo(tester, find.text(OwnRecipeCopy.allergensNoneFound));
      expect(tester.takeException(), isNull);
      await scrollTo(tester, find.text(OwnRecipeCopy.tips));
      expect(tester.takeException(), isNull);
    });
  });

  group('edit and delete', () {
    testWidgets('a premium household\'s editor gets both', (tester) async {
      await open(tester, RecipeFixtures.own());
      await tester.tap(find.byKey(const ValueKey('own-recipe-edit')));
      await tester.pumpAndSettle();
      expect(page.edits, 1);
    });

    testWidgets('a catalogue recipe has neither', (tester) async {
      await page.pump(
        tester,
        recipeId: 'bobotie',
        providers: SubscriptionHarness().providers,
      );
      harness.recipes.emitCatalogue(RecipeFixtures.catalogue);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('own-recipe-edit')), findsNothing);
      expect(find.byKey(const ValueKey('own-recipe-delete')), findsNothing);
    });

    testWidgets('deleting asks first, then goes, photos forgotten', (
      tester,
    ) async {
      final photos = RecipeFixtures.ownPhoto('abcdefgh');
      await open(tester, RecipeFixtures.own(photo: photos));

      await tester.tap(find.byKey(const ValueKey('own-recipe-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(OwnRecipeCopy.deleteCancel));
      await tester.pumpAndSettle();
      expect(page.ownRecipes.deleted, isEmpty);

      await tester.tap(find.byKey(const ValueKey('own-recipe-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(OwnRecipeCopy.deleteConfirm));
      await tester.pumpAndSettle();
      expect(page.ownRecipes.deleted, [RecipeFixtures.ownRecipeId]);
      expect(page.leftAfterDelete, 1);
    });

    testWidgets('a refused delete stays and says why', (tester) async {
      page.ownRecipes.failWith = const OwnRecipeFailure(
        OwnRecipeProblem.mealsNotShared,
      );
      await open(tester, RecipeFixtures.own());
      await tester.tap(find.byKey(const ValueKey('own-recipe-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(OwnRecipeCopy.deleteConfirm));
      await tester.pumpAndSettle();
      expect(page.leftAfterDelete, 0);
      expect(
        find.text(OwnRecipeCopy.problem(OwnRecipeProblem.mealsNotShared)),
        findsOneWidget,
      );
      expect(find.text(RecipeFixtures.own().name), findsOneWidget);
    });

    testWidgets('a lapsed household\'s Edit opens the paywall', (tester) async {
      await open(tester, RecipeFixtures.own(), isPremium: false);
      await tester.tap(find.byKey(const ValueKey('own-recipe-edit')));
      await tester.pumpAndSettle();
      expect(
        find.text(SubscriptionCopy.headline(PremiumFeature.ownRecipes)),
        findsOneWidget,
      );
      expect(page.edits, 0);
    });

    testWidgets('a lapsed household still reads, cooks and deletes', (
      tester,
    ) async {
      await open(tester, RecipeFixtures.own(), isPremium: false);
      expect(find.text(RecipeFixtures.own().name), findsOneWidget);
      expect(find.text(RecipeCopy.addToWeek), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('own-recipe-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(OwnRecipeCopy.deleteConfirm));
      await tester.pumpAndSettle();
      expect(page.ownRecipes.deleted, [RecipeFixtures.ownRecipeId]);
    });

    testWidgets('with the switch off, it can be deleted but not edited', (
      tester,
    ) async {
      await open(tester, RecipeFixtures.own(), flagOn: false);
      expect(find.byKey(const ValueKey('own-recipe-edit')), findsNothing);
      expect(find.byKey(const ValueKey('own-recipe-delete')), findsOneWidget);
    });

    testWidgets('somebody who may only look at meals gets neither', (
      tester,
    ) async {
      await page.pump(
        tester,
        recipeId: RecipeFixtures.ownRecipeId,
        view: Fixtures.helperView(
          AccessGrant({HouseholdArea.meals: AccessLevel.view}),
        ),
        providers: SubscriptionHarness().providers,
      );
      harness.recipes.emitCatalogue([RecipeFixtures.own()]);
      await tester.pumpAndSettle();
      expect(find.text(RecipeFixtures.own().name), findsOneWidget);
      expect(find.byKey(const ValueKey('own-recipe-edit')), findsNothing);
      expect(find.byKey(const ValueKey('own-recipe-delete')), findsNothing);
    });

    testWidgets('a kid device gets neither, whatever its grant says', (
      tester,
    ) async {
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
      expect(session.kidIdentity, isNotNull);

      await page.pump(
        tester,
        recipeId: RecipeFixtures.ownRecipeId,
        providers: [
          ...SubscriptionHarness(
            entitlement: Entitlement(premiumUntil: DateTime.utc(2100)),
          ).providers,
          ChangeNotifierProvider<SessionController>.value(value: session),
        ],
      );
      harness.recipes.emitCatalogue([RecipeFixtures.own()]);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('own-recipe-edit')), findsNothing);
      expect(find.byKey(const ValueKey('own-recipe-delete')), findsNothing);
    });
  });
}
