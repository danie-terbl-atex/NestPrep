import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/recipes/model/recipe_draft.dart';
import 'package:nestprep/features/recipes/model/recipe_draft_reading.dart';
import 'package:nestprep/features/recipes/model/recipe_import_way.dart';
import 'package:nestprep/features/recipes/model/recipe_origin.dart';
import 'package:nestprep/features/recipes/state/recipe_import_controller.dart';
import 'package:nestprep/features/recipes/ui/recipe_import_screen.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/features/subscriptions/state/household_entitlement.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_list_scan.dart';
import '../../../support/fake_recipe_import.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';
import '../../../support/pump_subscriptions.dart';

void main() {
  const field = ValueKey('recipe-import-link');
  const paste = ValueKey('recipe-import-paste');
  const readButton = ValueKey('recipe-import-read');
  const privacy = ValueKey('recipe-import-privacy');
  const stopped = ValueKey('recipe-import-stopped');
  const retry = ValueKey('recipe-import-retry');
  const screenshot = ValueKey('recipe-import-screenshot');
  const type = ValueKey('recipe-import-type');

  late FakeRecipePageReader reader;
  late FakeRecipeDrafter drafter;
  late FakeListPhotoPicker picker;
  late List<RecipeDraft> opened;

  setUp(() {
    reader = FakeRecipePageReader();
    drafter = FakeRecipeDrafter();
    picker = FakeListPhotoPicker();
    opened = [];
  });

  Future<void> pump(
    WidgetTester tester, {
    RecipeImportWay way = RecipeImportWay.link,
    String? sharedLink,
    bool isPremium = true,
    Brightness brightness = Brightness.light,
    double scale = 1,
    bool settle = true,
  }) async {
    tester.view.physicalSize = Size((scale > 1 ? 360 : 390) * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpScreen(
      tester,
      _OnceEntitlementKnown(
        child: ChangeNotifierProvider(
          create: (_) => RecipeImportController(
            pageReader: reader,
            drafter: drafter,
            photoPicker: picker,
            householdId: Fixtures.householdId,
            way: way,
          ),
          child: RecipeImportScreen(
            sharedLink: sharedLink,
            onOpenBuilder: opened.add,
          ),
        ),
      ),
      providers: SubscriptionHarness(
        entitlement: isPremium
            ? Entitlement(premiumUntil: DateTime.utc(2100))
            : Entitlement.free,
      ).providers,
      brightness: brightness,
      textScale: scale,
    );
    await tester.pump();
    if (settle) await tester.pumpAndSettle();
  }

  /// The working panel shimmers for ever, and a test has no route to replace
  /// it, so it never settles once a draft has opened.
  Future<void> frames(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> tapRead(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(readButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(readButton));
  }

  group('a link', () {
    testWidgets('says what leaves the phone, and sends nothing until asked', (
      tester,
    ) async {
      await pump(tester);

      expect(find.byKey(privacy), findsOneWidget);
      expect(find.text(RecipeImportCopy.privacyTitle), findsOneWidget);
      expect(find.text(RecipeImportCopy.linkPrivacyBody), findsOneWidget);
      expect(reader.asked, isEmpty);
      expect(drafter.pages, isEmpty);
    });

    testWidgets('a paste button fills the field, with only the link', (
      tester,
    ) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => call.method == 'Clipboard.getData'
            ? {'text': 'try this one: $aBobotieLink !'}
            : null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pump(tester);
      await tester.tap(find.byKey(paste));
      await tester.pumpAndSettle();
      expect(find.text(aBobotieLink), findsOneWidget);
    });

    testWidgets('one that is not public goes nowhere and says why', (
      tester,
    ) async {
      await pump(tester);
      for (final bad in ['not a link', 'http://192.168.1.1/', 'nas.local']) {
        await tester.enterText(find.byKey(field), bad);
        await tapRead(tester);
        await tester.pumpAndSettle();
        expect(find.text(RecipeImportCopy.notAPublicLink), findsOneWidget);
        expect(reader.asked, isEmpty);
      }

      await tester.enterText(find.byKey(field), aBobotieLink);
      await tester.pump();
      expect(find.text(RecipeImportCopy.notAPublicLink), findsNothing);
    });

    testWidgets('shows its progress, then opens the builder with the draft', (
      tester,
    ) async {
      reader.gate = Completer<void>();
      drafter.gate = Completer<void>();
      await pump(tester);
      await tester.enterText(find.byKey(field), aBobotieLink);
      await tapRead(tester);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(RecipeImportCopy.readingPageTitle), findsOneWidget);

      reader.gate!.complete();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(RecipeImportCopy.askingTitle), findsOneWidget);
      expect(opened, isEmpty);

      drafter.gate!.complete();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(opened.single.name, 'Bobotie');
      expect(reader.asked, [aBobotieLink]);
    });

    testWidgets('a free household meets the paywall before any fetch', (
      tester,
    ) async {
      await pump(tester, isPremium: false);
      await tester.enterText(find.byKey(field), aBobotieLink);
      await tapRead(tester);
      await tester.pumpAndSettle();

      expect(
        find.text(SubscriptionCopy.headline(PremiumFeature.ownRecipes)),
        findsOneWidget,
      );
      expect(reader.asked, isEmpty);
      expect(drafter.pages, isEmpty);
    });
  });

  group('a shared link', () {
    testWidgets('runs at once, the sheet having said what leaves', (
      tester,
    ) async {
      await pump(tester, sharedLink: aBobotieLink, settle: false);
      await frames(tester);
      expect(reader.asked, [aBobotieLink]);
      expect(opened, hasLength(1));
    });

    testWidgets(
      'a free household meets the paywall first, and keeps the link',
      (tester) async {
        await pump(tester, sharedLink: aBobotieLink, isPremium: false);

        expect(
          find.text(SubscriptionCopy.headline(PremiumFeature.ownRecipes)),
          findsOneWidget,
        );
        expect(reader.asked, isEmpty);
      },
    );
  });

  group('stopped', () {
    Future<void> stopWith(WidgetTester tester, AppFailure failure) async {
      reader.failWith = failure;
      await pump(tester, sharedLink: 'https://www.allrecipes.com/recipe/1/');
      expect(find.byKey(stopped), findsOneWidget);
    }

    testWidgets('a refusing site is said plainly, with two ways out and no '
        'retry', (tester) async {
      await stopWith(
        tester,
        const RecipeImportFailure(RecipeImportProblem.pageRefused),
      );
      expect(
        find.text(RecipeImportCopy.title(RecipeImportProblem.pageRefused)),
        findsOneWidget,
      );
      expect(
        find.text(RecipeImportCopy.problem(RecipeImportProblem.pageRefused)),
        findsOneWidget,
      );
      expect(find.text(RecipeImportCopy.snapScreenshot), findsOneWidget);
      expect(find.text(RecipeImportCopy.typeIt), findsOneWidget);
      expect(find.byKey(retry), findsNothing);
    });

    testWidgets('Type it opens the builder with the link', (tester) async {
      await stopWith(
        tester,
        const RecipeImportFailure(RecipeImportProblem.pageRefused),
      );
      await tester.tap(find.byKey(type));
      await tester.pumpAndSettle();
      expect(opened.single.sourceUrl, 'https://www.allrecipes.com/recipe/1/');
      expect(opened.single.sourceName, 'allrecipes.com');
    });

    testWidgets('Snap a screenshot moves to the photo way, and says so', (
      tester,
    ) async {
      drafter.reading = RecipeDraftReading(
        draft: aBobotieDraft(
          origin: RecipeOrigin.photo,
          sourceUrl: null,
          sourceName: null,
        ),
        callsLeft: 90,
      );
      await stopWith(
        tester,
        const RecipeImportFailure(RecipeImportProblem.pageRefused),
      );
      await tester.tap(find.byKey(screenshot));
      await tester.pumpAndSettle();

      expect(find.text(RecipeImportCopy.snapScreenTitle), findsOneWidget);
      expect(find.text(RecipeImportCopy.photoPrivacyBody), findsOneWidget);
      expect(drafter.photos, isEmpty);

      await tester.tap(find.byKey(const ValueKey('recipe-import-photos')));
      await frames(tester);
      expect(drafter.photos, hasLength(1));
      expect(opened.single.sourceUrl, 'https://www.allrecipes.com/recipe/1/');
    });

    testWidgets('a page the model says is no recipe says that', (tester) async {
      drafter.reading = const RecipeDraftReading(draft: null, callsLeft: 1);
      await pump(tester, sharedLink: aBobotieLink);
      expect(
        find.text(RecipeImportCopy.title(RecipeImportProblem.noRecipe)),
        findsOneWidget,
      );
      expect(find.byKey(screenshot), findsOneWidget);
      expect(find.byKey(type), findsOneWidget);
      expect(find.byKey(retry), findsNothing);
    });

    testWidgets('a model that did not answer gets Retry, which works', (
      tester,
    ) async {
      drafter.failWith = const AiFailure(AiProblem.aiUnavailable);
      await pump(tester, sharedLink: aBobotieLink);
      expect(
        find.text(AiCopy.problem(AiProblem.aiUnavailable)),
        findsOneWidget,
      );

      drafter.failWith = null;
      await tester.tap(find.byKey(retry));
      await frames(tester);
      expect(opened, hasLength(1));
      expect(reader.asked, hasLength(1));
    });

    testWidgets('a spent month uses the AI words, and offers only typing', (
      tester,
    ) async {
      drafter.failWith = const AiFailure(AiProblem.aiLimitReached);
      await pump(tester, sharedLink: aBobotieLink);
      expect(
        find.text(AiCopy.problem(AiProblem.aiLimitReached)),
        findsOneWidget,
      );
      expect(find.byKey(retry), findsNothing);
      expect(find.byKey(screenshot), findsNothing);
      expect(find.byKey(type), findsOneWidget);
    });
  });

  group('a photo', () {
    testWidgets('says only the photo leaves, and sends nothing until picked', (
      tester,
    ) async {
      await pump(tester, way: RecipeImportWay.snap);
      expect(find.text(RecipeImportCopy.photoPrivacyBody), findsOneWidget);
      expect(drafter.photos, isEmpty);

      await tester.tap(find.byKey(const ValueKey('recipe-import-camera')));
      await frames(tester);
      expect(drafter.photos.single, aListPhoto);
      expect(opened, hasLength(1));
    });

    testWidgets('a free household meets the paywall before the picker', (
      tester,
    ) async {
      await pump(tester, way: RecipeImportWay.snap, isPremium: false);
      await tester.tap(find.byKey(const ValueKey('recipe-import-camera')));
      await tester.pumpAndSettle();
      expect(picker.asked, isEmpty);
      expect(drafter.photos, isEmpty);
    });

    testWidgets('no recipe in it asks for another photo', (tester) async {
      drafter.reading = const RecipeDraftReading(draft: null, callsLeft: 1);
      await pump(tester, way: RecipeImportWay.snap);
      await tester.tap(find.byKey(const ValueKey('recipe-import-camera')));
      await tester.pumpAndSettle();
      expect(find.text(RecipeImportCopy.notARecipePhotoTitle), findsOneWidget);
      expect(find.text(RecipeImportCopy.tryAnotherPhoto), findsOneWidget);
    });
  });

  group('fits at 200% text, 360 wide, in the dark', () {
    testWidgets('a link', (tester) async {
      await pump(tester, brightness: Brightness.dark, scale: 2);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.byKey(field),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(find.byKey(field), 'nope');
      await tapRead(tester);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('a photo', (tester) async {
      await pump(
        tester,
        way: RecipeImportWay.snap,
        brightness: Brightness.dark,
        scale: 2,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('working', (tester) async {
      reader.gate = Completer<void>();
      await pump(
        tester,
        sharedLink: aBobotieLink,
        brightness: Brightness.dark,
        scale: 2,
        settle: false,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(RecipeImportCopy.readingPageTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
      reader.gate!.complete();
      await frames(tester);
      expect(tester.takeException(), isNull);
    });

    for (final failure in [
      const RecipeImportFailure(RecipeImportProblem.pageRefused),
      const RecipeImportFailure(RecipeImportProblem.pageUnreachable),
      const AiFailure(AiProblem.aiLimitReached),
    ]) {
      testWidgets('stopped: ${AppCopy.failure(failure)}', (tester) async {
        reader.failWith = failure;
        await pump(
          tester,
          sharedLink: aBobotieLink,
          brightness: Brightness.dark,
          scale: 2,
        );
        expect(find.byKey(stopped), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}

class _OnceEntitlementKnown extends StatelessWidget {
  const _OnceEntitlementKnown({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      context.watch<HouseholdEntitlement>().isKnown
      ? child
      : const SizedBox.shrink();
}
