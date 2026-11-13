import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/meals_route.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/accounts/model/account.dart';
import 'package:nestprep/features/accounts/model/auth_user.dart';
import 'package:nestprep/features/accounts/model/kid_identity.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/photo_frames/data/photo_frame_directory.dart';
import 'package:nestprep/features/photo_frames/data/photo_frame_repository.dart';
import 'package:nestprep/features/photo_frames/model/frame_panels.dart';
import 'package:nestprep/features/photo_frames/model/frame_share_item.dart';
import 'package:nestprep/features/photo_frames/model/photo_frame.dart';
import 'package:nestprep/features/photo_frames/model/shared_pdf.dart';
import 'package:nestprep/features/photo_frames/state/pending_share.dart';
import 'package:nestprep/features/photo_frames/ui/share_to_frame_host.dart';
import 'package:nestprep/features/photo_frames/ui/share_to_frame_sheet.dart';
import 'package:nestprep/features/recipes/data/recipe_photo_source.dart';
import 'package:nestprep/features/recipes/model/recipe_import_way.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/features/subscriptions/state/household_entitlement.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/cook_along_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_auth.dart';
import '../../../support/fake_feature_flag_source.dart';
import '../../../support/fake_photo_frames.dart';
import '../../../support/fake_recipe_photos.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';
import '../../../support/pump_subscriptions.dart';

void main() {
  const recipe = 'https://www.example.com/recipes/lemon-tart';
  final shareLink = Uri.parse(
    'nestprep://share?url=${Uri.encodeQueryComponent(recipe)}'
    '&title=${Uri.encodeQueryComponent('Lemon tart')}',
  );

  late StreamController<Uri> links;
  late PendingShare pending;
  late FakePhotoFrameRepository repository;
  late FakePhotoFrameDirectory directory;

  final kitchen = FrameFixtures.frame(panels: const FramePanels(share: true));
  final hall = FrameFixtures.frame(
    id: 'frame-hall',
    name: 'Hall frame',
    panels: const FramePanels(share: true),
  );
  final study = FrameFixtures.frame(id: 'frame-study', name: 'Study frame');
  final porch = FrameFixtures.frame(
    id: 'frame-porch',
    name: 'Porch frame',
    panels: const FramePanels(share: true),
    accepts: PhotoFrame.pageOnly,
  );

  setUp(() {
    links = StreamController<Uri>.broadcast();
    pending = PendingShare(links: links.stream);
    repository = FakePhotoFrameRepository();
    directory = FakePhotoFrameDirectory();
  });

  tearDown(() async {
    pending.dispose();
    await links.close();
    await repository.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    HouseholdView? view,
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) => pumpScreen(
    tester,
    const ShareToFrameHost(child: Scaffold(body: SizedBox.expand())),
    providers: [
      featureFlagsProvider(defaultOn: false),
      ChangeNotifierProvider<PendingShare>.value(value: pending),
      Provider<PhotoFrameRepository>.value(value: repository),
      Provider<PhotoFrameDirectory>.value(value: directory),
    ],
    view: view,
    brightness: brightness,
    textScale: scale,
  );

  Future<void> settleSheet(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> share(WidgetTester tester, [Uri? link]) async {
    links.add(link ?? shareLink);
    await settleSheet(tester);
  }

  Future<void> frames(WidgetTester tester, List<PhotoFrame> frames) async {
    repository.emit(frames);
    await tester.pumpAndSettle();
  }

  testWidgets('a shared page opens the sheet once, naming the page', (
    tester,
  ) async {
    await pump(tester);
    await share(tester);

    expect(find.text(PhotoFrameCopy.sharedPage), findsOneWidget);
    expect(find.text(PhotoFrameCopy.showOnFrame), findsOneWidget);
    expect(find.text('Lemon tart'), findsOneWidget);
    expect(find.text('www.example.com'), findsOneWidget);
    expect(pending.page, isNull);
  });

  testWidgets('one frame with sharing on is one tap', (tester) async {
    await pump(tester);
    await share(tester);
    await frames(tester, [kitchen, study]);

    expect(find.text(PhotoFrameCopy.chooseFrame), findsNothing);
    expect(find.text(study.name), findsNothing);
    await tester.tap(find.text(PhotoFrameCopy.showOn(kitchen.name)));
    await tester.pumpAndSettle();

    expect(directory.shared.single, (
      frameId: kitchen.id,
      url: recipe,
      title: 'Lemon tart',
    ));
    expect(find.text(PhotoFrameCopy.openingOn(kitchen.name)), findsOneWidget);

    await tester.tap(find.text(PhotoFrameCopy.done));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('several frames are a choice, and only those sharing', (
    tester,
  ) async {
    await pump(tester);
    await share(tester);
    await frames(tester, [hall, kitchen, study]);

    expect(find.text(PhotoFrameCopy.chooseFrame), findsOneWidget);
    expect(find.text(hall.name), findsOneWidget);
    expect(find.text(kitchen.name), findsOneWidget);
    expect(find.text(study.name), findsNothing);

    await tester.tap(find.text(hall.name));
    await tester.pumpAndSettle();
    expect(directory.shared.single.frameId, hall.id);
    expect(find.text(PhotoFrameCopy.openingOn(hall.name)), findsOneWidget);
  });

  testWidgets('a page still goes to a frame that cannot cook along', (
    tester,
  ) async {
    await pump(tester);
    await share(tester);
    await frames(tester, [porch]);

    expect(find.text(CookAlongCopy.updateToCookAlong), findsNothing);
    await tester.tap(find.text(PhotoFrameCopy.showOn(porch.name)));
    await tester.pumpAndSettle();
    expect(directory.shared.single.frameId, porch.id);
  });

  testWidgets('one tap at a time while it sends', (tester) async {
    directory.holdCalls = Completer<void>();
    await pump(tester);
    await share(tester);
    await frames(tester, [hall, kitchen]);

    await tester.tap(find.text(hall.name));
    await tester.pump();
    await tester.tap(find.text(kitchen.name));
    await tester.pump();
    directory.holdCalls!.complete();
    await tester.pumpAndSettle();

    expect(directory.shared.single.frameId, hall.id);
  });

  testWidgets('no frame with sharing on says where to switch it on', (
    tester,
  ) async {
    await pump(tester);
    await share(tester);
    await frames(tester, [study]);

    expect(find.text(PhotoFrameCopy.noSharingFrames), findsOneWidget);
    expect(find.text(PhotoFrameCopy.noSharingFramesBody), findsOneWidget);
    expect(find.text(study.name), findsNothing);
  });

  testWidgets('somebody who is not family is told only family can', (
    tester,
  ) async {
    await pump(tester, view: Fixtures.view(viewerUid: Fixtures.thandiUid));
    await share(tester);

    expect(find.text(PhotoFrameCopy.shareOnlyFamily), findsOneWidget);
    expect(find.byType(NestLoadingView), findsNothing);
    repository.emit([kitchen]);
    await tester.pumpAndSettle();
    expect(find.text(PhotoFrameCopy.showOn(kitchen.name)), findsNothing);
  });

  testWidgets('a share with no web link in it says so', (tester) async {
    await pump(tester);
    await share(tester, Uri.parse('nestprep://share?url=just%20some%20words'));

    expect(find.text(PhotoFrameCopy.noLinkShared), findsOneWidget);
  });

  testWidgets('an unreadable frame list offers a retry', (tester) async {
    await pump(tester);
    await share(tester);
    repository.failWith(const UnavailableFailure());
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.retry), findsOneWidget);
    await tester.tap(find.text(AppCopy.retry));
    await tester.pump();
    expect(find.byType(NestLoadingView), findsOneWidget);
    await frames(tester, [kitchen]);
    expect(find.text(PhotoFrameCopy.showOn(kitchen.name)), findsOneWidget);
  });

  group(
    'a refusal is said in its own words, and another frame can be tried',
    () {
      for (final problem in [
        PhotoFrameProblem.frameNotFound,
        PhotoFrameProblem.sharingOff,
        PhotoFrameProblem.badLink,
        PhotoFrameProblem.framesOff,
        PhotoFrameProblem.tooManyAttempts,
      ]) {
        testWidgets(problem.name, (tester) async {
          directory.failWith = PhotoFrameFailure(problem);
          await pump(tester);
          await share(tester);
          await frames(tester, [hall, kitchen]);

          await tester.tap(find.text(hall.name));
          await tester.pumpAndSettle();
          expect(find.text(PhotoFrameCopy.problem(problem)), findsOneWidget);
          expect(find.text(PhotoFrameCopy.openingOn(hall.name)), findsNothing);

          directory.failWith = null;
          await tester.tap(find.text(kitchen.name));
          await tester.pumpAndSettle();
          expect(
            find.text(PhotoFrameCopy.openingOn(kitchen.name)),
            findsOneWidget,
          );
        });
      }

      testWidgets('notFamily, as only family can', (tester) async {
        directory.failWith = const PhotoFrameFailure(
          PhotoFrameProblem.notFamily,
        );
        await pump(tester);
        await share(tester);
        await frames(tester, [kitchen]);

        await tester.tap(find.text(PhotoFrameCopy.showOn(kitchen.name)));
        await tester.pumpAndSettle();
        expect(find.text(PhotoFrameCopy.shareOnlyFamily), findsOneWidget);
      });
    },
  );

  testWidgets('a page shared while the sheet is open waits for it to close', (
    tester,
  ) async {
    await pump(tester);
    await share(tester);
    await frames(tester, [kitchen]);
    await share(
      tester,
      Uri.parse('nestprep://share?url=https%3A%2F%2Fsecond.example.com'),
    );
    expect(find.byType(BottomSheet), findsOneWidget);

    await tester.tap(find.text(PhotoFrameCopy.showOn(kitchen.name)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(PhotoFrameCopy.done));
    await settleSheet(tester);

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('second.example.com'), findsOneWidget);
    expect(pending.page, isNull);
  });

  testWidgets('survives dark at 200% text on a 360-wide phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 780 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pump(tester, brightness: Brightness.dark, scale: 2);
    await share(tester);
    await frames(tester, [hall, kitchen]);

    expect(tester.takeException(), isNull);
    await tester.tap(find.text(hall.name));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  group('saving a shared page as a recipe', () {
    const saveAction = ValueKey('share-save-as-recipe');
    const privacy = ValueKey('share-recipe-privacy');
    const quiet = ValueKey('share-no-frames-quiet');
    final helperWithMeals = Fixtures.helperView(
      AccessGrant({HouseholdArea.meals: AccessLevel.edit}),
    );
    final helperLookingOnly = Fixtures.helperView(
      AccessGrant({HouseholdArea.meals: AccessLevel.view}),
    );
    final importPath = MealsRoute.importRecipePathFor(
      Fixtures.householdId,
      RecipeImportWay.link,
    );
    late List<Object?> imports;
    late SubscriptionHarness subscriptions;

    Future<void> open(
      WidgetTester tester, {
      HouseholdView? view,
      bool flagOn = true,
      bool isPremium = true,
      Uri? link,
      Brightness brightness = Brightness.light,
      double scale = 1,
      SessionController? session,
    }) async {
      imports = [];
      subscriptions = SubscriptionHarness(
        entitlement: isPremium
            ? Entitlement(premiumUntil: DateTime.utc(2100))
            : Entitlement.free,
      );
      await pumpRouter(
        tester,
        router: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const _OnceEntitlementKnown(
                child: ShareToFrameHost(
                  child: Scaffold(body: SizedBox.expand()),
                ),
              ),
            ),
            GoRoute(
              path: MealsRoute.importRecipePath,
              builder: (context, state) {
                imports.add(state.extra);
                return const Scaffold(body: Text('import'));
              },
            ),
            GoRoute(
              path: MealsRoute.importPdfPath,
              builder: (context, state) {
                imports.add(state.extra);
                return const Scaffold(body: Text('import pdf'));
              },
            ),
          ],
        ),
        providers: [
          featureFlagsProvider(defaultOn: flagOn),
          ...subscriptions.providers,
          if (session != null)
            ChangeNotifierProvider<SessionController>.value(value: session),
          ChangeNotifierProvider<PendingShare>.value(value: pending),
          Provider<PhotoFrameRepository>.value(value: repository),
          Provider<PhotoFrameDirectory>.value(value: directory),
        ],
        view: view,
        brightness: brightness,
        textScale: scale,
      );
      await tester.pump();
      await tester.pump();
      await share(tester, link);
    }

    testWidgets('a parent sees both, under the new title, and is told what '
        'leaves the phone', (tester) async {
      await open(tester);
      await frames(tester, [kitchen]);

      expect(find.text(PhotoFrameCopy.sharedPage), findsOneWidget);
      expect(find.byKey(saveAction), findsOneWidget);
      expect(find.byKey(privacy), findsOneWidget);
      expect(find.text(RecipeImportCopy.linkPrivacyBody), findsOneWidget);
      expect(find.text(PhotoFrameCopy.showOnFrame), findsOneWidget);
      expect(find.text(PhotoFrameCopy.showOn(kitchen.name)), findsOneWidget);
    });

    testWidgets('tapping it closes the sheet, then runs the import for that '
        'link', (tester) async {
      await open(tester);
      await frames(tester, [kitchen]);

      await tester.tap(find.byKey(saveAction));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(imports, [recipe]);
      expect(find.text('import'), findsOneWidget);
      expect(importPath, contains('way=link'));
    });

    testWidgets('a shared PDF skips the frame sheet and opens the PDF import, '
        'naming only its token', (tester) async {
      await open(
        tester,
        link: Uri.parse('nestprep://share?pdf=4F1C2D3E-AAAA-BBBB-CCCC-0123'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(imports, [const SharedPdf('4F1C2D3E-AAAA-BBBB-CCCC-0123')]);
      expect(find.text('import pdf'), findsOneWidget);
      expect(pending.pdf, isNull);
    });

    testWidgets('a shared PDF in a free household meets the paywall', (
      tester,
    ) async {
      await open(
        tester,
        isPremium: false,
        link: Uri.parse('nestprep://share?pdf=4F1C2D3E-AAAA-BBBB-CCCC-0123'),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(SubscriptionCopy.headline(PremiumFeature.ownRecipes)),
        findsOneWidget,
      );
      expect(imports, isEmpty);
    });

    testWidgets(
      'a free household meets the paywall first, and no import runs',
      (tester) async {
        await open(tester, isPremium: false);
        await frames(tester, [kitchen]);

        await tester.tap(find.byKey(saveAction));
        await tester.pumpAndSettle();

        expect(
          find.text(SubscriptionCopy.headline(PremiumFeature.ownRecipes)),
          findsOneWidget,
        );
        expect(imports, isEmpty);
      },
    );

    testWidgets('sending to a frame still works, and hides the recipe action', (
      tester,
    ) async {
      await open(tester);
      await frames(tester, [kitchen]);

      await tester.tap(find.text(PhotoFrameCopy.showOn(kitchen.name)));
      await tester.pumpAndSettle();

      expect(directory.shared.single.frameId, kitchen.id);
      expect(find.byKey(saveAction), findsNothing);
      expect(find.text(PhotoFrameCopy.openingOn(kitchen.name)), findsOneWidget);
    });

    testWidgets(
      'a helper with meals edit sees the recipe action, and no lock',
      (tester) async {
        await open(tester, view: helperWithMeals);
        await tester.pumpAndSettle();

        expect(find.byKey(saveAction), findsOneWidget);
        expect(find.text(PhotoFrameCopy.shareOnlyFamily), findsNothing);
        expect(find.text(PhotoFrameCopy.showOnFrame), findsNothing);
        expect(repository.hasListener, isFalse);
      },
    );

    testWidgets('a helper without meals edit is told only family can', (
      tester,
    ) async {
      await open(tester, view: helperLookingOnly);
      await tester.pumpAndSettle();

      expect(find.byKey(saveAction), findsNothing);
      expect(find.text(PhotoFrameCopy.shareOnlyFamily), findsOneWidget);
    });

    testWidgets('no frames at all says nothing about frames', (tester) async {
      await open(tester);
      await frames(tester, []);

      expect(find.byKey(saveAction), findsOneWidget);
      expect(find.text(PhotoFrameCopy.noSharingFrames), findsNothing);
      expect(find.text(PhotoFrameCopy.showOnFrame), findsNothing);
      expect(find.byKey(quiet), findsNothing);
    });

    testWidgets('frames with sharing off get a quiet line, not a dead end', (
      tester,
    ) async {
      await open(tester);
      await frames(tester, [study]);

      expect(find.byKey(saveAction), findsOneWidget);
      expect(find.byKey(quiet), findsOneWidget);
      expect(find.text(PhotoFrameCopy.noSharingFrames), findsNothing);
      expect(find.text(study.name), findsNothing);
    });

    testWidgets('no link in the share is today\'s notice, and no action', (
      tester,
    ) async {
      await open(
        tester,
        link: Uri.parse('nestprep://share?url=just%20some%20words'),
      );
      expect(find.text(PhotoFrameCopy.noLinkShared), findsOneWidget);
      expect(find.byKey(saveAction), findsNothing);
    });

    testWidgets('no link for a helper with meals edit says so, not the lock', (
      tester,
    ) async {
      await open(
        tester,
        view: helperWithMeals,
        link: Uri.parse('nestprep://share?url=just%20some%20words'),
      );
      expect(find.text(PhotoFrameCopy.noLinkShared), findsOneWidget);
      expect(find.text(PhotoFrameCopy.shareOnlyFamily), findsNothing);
      expect(find.byKey(saveAction), findsNothing);
    });

    testWidgets(
      'the flag off hides the action and leaves frames as they were',
      (tester) async {
        await open(tester, flagOn: false);
        await frames(tester, [study]);

        expect(find.byKey(saveAction), findsNothing);
        expect(find.text(PhotoFrameCopy.noSharingFrames), findsOneWidget);
        expect(find.text(PhotoFrameCopy.noSharingFramesBody), findsOneWidget);
      },
    );

    testWidgets('the flag off for a helper is the lock', (tester) async {
      await open(tester, flagOn: false, view: helperWithMeals);
      expect(find.byKey(saveAction), findsNothing);
      expect(find.text(PhotoFrameCopy.shareOnlyFamily), findsOneWidget);
    });

    testWidgets('a kid device gets no recipe action', (tester) async {
      final auth = FakeAuthGateway();
      final accounts = FakeAccountRepository();
      final kid = SessionController(
        authGateway: auth,
        accountRepository: accounts,
      );
      addTearDown(() async {
        kid.dispose();
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
      await open(tester, session: kid);
      expect(find.byKey(saveAction), findsNothing);
    });

    testWidgets('survives dark at 200% text on a 360-wide phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360 * 3, 780 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await open(tester, brightness: Brightness.dark, scale: 2);
      await frames(tester, [hall, kitchen]);
      expect(tester.takeException(), isNull);
      expect(find.byKey(saveAction), findsOneWidget);
    });

    testWidgets('and with sharing off, likewise', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 780 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await open(tester, brightness: Brightness.dark, scale: 2);
      await frames(tester, [study]);
      expect(tester.takeException(), isNull);
    });
  });

  group('a recipe', () {
    const bobotie = FrameShareRecipe(
      recipeId: 'bobotie',
      name: 'Bobotie',
      people: 4,
      amounts: ['670 g', '1', null],
      cardPhotoPath: 'recipes/bobotie/card-abc123.jpg',
    );
    late FakeRecipePhotoSource photos;

    setUp(() => photos = FakeRecipePhotoSource());

    Future<void> open(
      WidgetTester tester, {
      HouseholdView? view,
      Brightness brightness = Brightness.light,
      double scale = 1,
    }) async {
      await pumpScreen(
        tester,
        const Scaffold(body: _OpenRecipe(recipe: bobotie)),
        providers: [
          Provider<PhotoFrameRepository>.value(value: repository),
          Provider<PhotoFrameDirectory>.value(value: directory),
          Provider<RecipePhotoSource>.value(value: photos),
        ],
        view: view,
        brightness: brightness,
        textScale: scale,
      );
      await tester.tap(find.byType(_OpenRecipe));
      await settleSheet(tester);
    }

    testWidgets('names the recipe, its people and shows its card photo', (
      tester,
    ) async {
      await open(tester);

      expect(find.text(PhotoFrameCopy.showOnFrame), findsOneWidget);
      expect(find.text(PhotoFrameCopy.sharedPage), findsNothing);
      expect(find.byKey(const ValueKey('share-save-as-recipe')), findsNothing);
      expect(find.text('Bobotie'), findsOneWidget);
      expect(find.text(RecipeCopy.forPeople(4)), findsOneWidget);
      expect(photos.asked, contains(bobotie.cardPhotoPath));
    });

    testWidgets('one tap sends the recipe, never a link', (tester) async {
      await open(tester);
      await frames(tester, [kitchen, study]);

      await tester.tap(find.text(PhotoFrameCopy.showOn(kitchen.name)));
      await tester.pumpAndSettle();

      expect(directory.shared, isEmpty);
      expect(directory.payloads.single, {
        'householdId': Fixtures.householdId,
        'frameId': kitchen.id,
        'recipe': {
          'id': 'bobotie',
          'people': 4,
          'amounts': ['670 g', '1', null],
        },
      });
      expect(find.text(PhotoFrameCopy.openingOn(kitchen.name)), findsOneWidget);
      expect(find.text(CookAlongCopy.sentBody), findsOneWidget);
    });

    testWidgets('a frame that cannot cook along is listed, but not to tap', (
      tester,
    ) async {
      await open(tester);
      await frames(tester, [kitchen, porch]);

      expect(find.text(porch.name), findsOneWidget);
      expect(find.text(CookAlongCopy.updateToCookAlong), findsOneWidget);
      await tester.tap(find.text(porch.name));
      await tester.pumpAndSettle();
      expect(directory.payloads, isEmpty);

      await tester.tap(find.text(kitchen.name));
      await tester.pumpAndSettle();
      expect(directory.sharedRecipes.single.frameId, kitchen.id);
    });

    testWidgets('the only frame cannot cook along: the one tap is off', (
      tester,
    ) async {
      await open(tester);
      await frames(tester, [porch]);

      expect(find.text(CookAlongCopy.updateToCookAlong), findsOneWidget);
      final button = tester.widget<NestButton>(
        find.widgetWithText(NestButton, PhotoFrameCopy.showOn(porch.name)),
      );
      expect(button.onPressed, isNull);
      await tester.tap(find.text(PhotoFrameCopy.showOn(porch.name)));
      await tester.pumpAndSettle();
      expect(directory.payloads, isEmpty);
    });

    testWidgets('a choice of frames lists only those sharing', (tester) async {
      await open(tester);
      await frames(tester, [hall, kitchen, study]);

      expect(find.text(study.name), findsNothing);
      await tester.tap(find.text(hall.name));
      await tester.pumpAndSettle();
      expect(directory.sharedRecipes.single.frameId, hall.id);
    });

    group('a refusal is said, and another frame can be tried', () {
      for (final problem in [
        PhotoFrameProblem.sharingOff,
        PhotoFrameProblem.frameCantOpen,
        PhotoFrameProblem.recipeNotFound,
        PhotoFrameProblem.badRecipe,
      ]) {
        testWidgets(problem.name, (tester) async {
          directory.failWith = PhotoFrameFailure(problem);
          await open(tester);
          await frames(tester, [hall, kitchen]);

          await tester.tap(find.text(hall.name));
          await tester.pumpAndSettle();
          expect(find.text(PhotoFrameCopy.problem(problem)), findsOneWidget);
          expect(find.text(PhotoFrameCopy.openingOn(hall.name)), findsNothing);

          directory.failWith = null;
          await tester.tap(find.text(kitchen.name));
          await tester.pumpAndSettle();
          expect(
            find.text(PhotoFrameCopy.openingOn(kitchen.name)),
            findsOneWidget,
          );
        });
      }
    });

    testWidgets('somebody who is not family is told only family can', (
      tester,
    ) async {
      await open(tester, view: Fixtures.view(viewerUid: Fixtures.thandiUid));

      expect(find.text(PhotoFrameCopy.shareOnlyFamily), findsOneWidget);
      expect(repository.hasListener, isFalse);
    });

    testWidgets('survives dark at 200% text on a 360-wide phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360 * 3, 780 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await open(tester, brightness: Brightness.dark, scale: 2);
      await frames(tester, [hall, kitchen, porch]);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text(hall.name));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

class _OpenRecipe extends StatelessWidget {
  const _OpenRecipe({required this.recipe});

  final FrameShareRecipe recipe;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => showShareToFrameSheet(context: context, item: recipe),
    child: const Text('Open'),
  );
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
