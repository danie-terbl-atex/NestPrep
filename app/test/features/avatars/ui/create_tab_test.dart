import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/avatars/data/avatar_photo_picker.dart';
import 'package:nestprep/features/avatars/model/avatar_base.dart';
import 'package:nestprep/features/avatars/model/avatar_catalogue.g.dart';
import 'package:nestprep/features/avatars/model/avatar_creation.dart';
import 'package:nestprep/features/avatars/model/avatar_keepsake.dart';
import 'package:nestprep/features/avatars/ui/avatar_studio_tab.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';

import '../../../support/avatar_studio_rig.dart';
import '../../../support/household_fixtures.dart';

void main() {
  const hash = '0123456789abcdef0123456789abcdef';
  final premium = Entitlement(premiumUntil: DateTime.utc(2100));
  const kept = AvatarKeepsake(
    id: 'k-buddy',
    memberId: Fixtures.kidMemberId,
    recipe: CreationRecipe.buddy,
    imageHash: '0123456789abcdef0123456789abcdef',
  );

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(400 * 3, 2400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Finder card(CreationRecipe recipe) =>
      find.byKey(ValueKey('create-${recipe.name}'));

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapIn(WidgetTester tester, Finder finder) async {
    await scrollTo(tester, finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> overflowFree(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pump();
    }
    expect(tester.takeException(), isNull);
  }

  StudioRig kidRig({Entitlement entitlement = Entitlement.free}) => StudioRig(
    member: Fixtures.kid,
    viewerMemberId: Fixtures.kidMemberId,
    entitlement: entitlement,
    photo: aPhoto(),
  );

  Future<void> buildADragon(WidgetTester tester) async {
    for (final (kind, id) in [
      (AvatarBuddyKind.creature, 'dragon'),
      (AvatarBuddyKind.colour, 'purple'),
      (AvatarBuddyKind.loves, 'pancakes'),
      (AvatarBuddyKind.wears, 'cape'),
      (AvatarBuddyKind.power, 'flying'),
    ]) {
      await tapIn(tester, find.byKey(ValueKey('buddy-${kind.name}-$id')));
    }
  }

  group('the menu', () {
    testWidgets('a grown-up of a free household sees three ways in, the '
        'free try, and the portrait behind premium', (tester) async {
      tall(tester);
      final rig = StudioRig(member: Fixtures.sam);
      addTearDown(rig.close);
      await rig.pump(tester, tab: AvatarStudioTab.create);
      for (final recipe in CreationRecipe.values) {
        expect(card(recipe), findsOneWidget, reason: recipe.name);
      }
      expect(find.text(AvatarCreationCopy.tryOnceFree), findsOneWidget);
      expect(find.text(SubscriptionCopy.premium), findsOneWidget);
    });

    testWidgets('a child gets the three, never the portrait', (tester) async {
      tall(tester);
      final rig = kidRig();
      addTearDown(rig.close);
      await rig.pump(tester, tab: AvatarStudioTab.create, asFamily: false);
      expect(card(CreationRecipe.buddy), findsOneWidget);
      expect(card(CreationRecipe.portrait), findsNothing);
    });

    testWidgets('a parent opening a child’s studio has no portrait there '
        'either: it is their own', (tester) async {
      tall(tester);
      final rig = StudioRig(member: Fixtures.kid);
      addTearDown(rig.close);
      await rig.pump(tester, tab: AvatarStudioTab.create);
      expect(card(CreationRecipe.portrait), findsNothing);
    });

    testWidgets('premium says how many are left this month', (tester) async {
      tall(tester);
      final rig = StudioRig(member: Fixtures.sam, entitlement: premium);
      addTearDown(rig.close);
      await rig.pump(tester, tab: AvatarStudioTab.create);
      rig.avatars.emitRecent([
        AvatarCreation(
          id: 'c1',
          memberId: Fixtures.kidMemberId,
          recipe: CreationRecipe.pet,
          status: CreationStatus.ready,
          left: 8,
          requestedAt: DateTime.now(),
        ),
      ]);
      await tester.pumpAndSettle();
      expect(find.text(AvatarCreationCopy.picturesLeft(8)), findsOneWidget);
      expect(find.text(AvatarCreationCopy.tryOnceFree), findsNothing);
      expect(find.text(SubscriptionCopy.premium), findsNothing);
    });

    testWidgets('a free household that used its try is offered premium '
        'before it picks anything', (tester) async {
      tall(tester);
      final rig = StudioRig(member: Fixtures.sam);
      addTearDown(rig.close);
      await rig.pump(tester, tab: AvatarStudioTab.create);
      rig.avatars.emitRecent([
        AvatarCreation(
          id: 'c1',
          memberId: Fixtures.samMemberId,
          recipe: CreationRecipe.buddy,
          status: CreationStatus.ready,
          left: 0,
          requestedAt: DateTime(2026, 3),
        ),
      ]);
      await tester.pumpAndSettle();
      expect(find.text(AvatarCreationCopy.freeTryUsed), findsOneWidget);
      await tester.tap(card(CreationRecipe.buddy));
      await tester.pumpAndSettle();
      expect(
        find.text(SubscriptionCopy.headline(PremiumFeature.avatarCreate)),
        findsOneWidget,
      );
      expect(
        rig.subscriptions.paywallOpens.opened.map((open) => open.trigger),
        [PremiumFeature.avatarCreate],
      );
    });

    testWidgets('with creations switched off, family sees why and the switch', (
      tester,
    ) async {
      tall(tester);
      final rig = StudioRig(member: Fixtures.sam);
      addTearDown(rig.close);
      await rig.pump(tester, tab: AvatarStudioTab.create, creationsOn: false);
      expect(find.text(AvatarCreationCopy.offTitle), findsOneWidget);
      expect(card(CreationRecipe.buddy), findsNothing);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(rig.avatars.creationsSwitched, [true]);
    });

    testWidgets('with creations switched off, a child has no Create tab but '
        'keeps the shelf', (tester) async {
      final rig = kidRig();
      addTearDown(rig.close);
      await rig.pump(
        tester,
        tab: AvatarStudioTab.create,
        creationsOn: false,
        asFamily: false,
      );
      expect(find.text(AvatarCreationCopy.createTab), findsNothing);
      expect(find.text(AvatarCreationCopy.keepsakesTab), findsNothing);
      rig.avatars.emitKeepsakes(Fixtures.kidMemberId, [kept]);
      await tester.pumpAndSettle();
      expect(find.text(AvatarCreationCopy.createTab), findsNothing);
      expect(find.text(AvatarCreationCopy.keepsakesTab), findsOneWidget);
      expect(find.text(AvatarCreationCopy.offTitle), findsNothing);
    });

    testWidgets('with the flag off, a shelf that already holds something can '
        'still be opened and emptied', (tester) async {
      final rig = StudioRig(
        member: Fixtures.kid,
        viewerMemberId: Fixtures.kidMemberId,
        creations: false,
      );
      addTearDown(rig.close);
      await rig.pump(tester, tab: AvatarStudioTab.keepsakes, asFamily: false);
      rig.avatars.emitKeepsakes(Fixtures.kidMemberId, [kept]);
      await tester.pumpAndSettle();
      expect(find.text(AvatarCreationCopy.createTab), findsNothing);
      expect(find.text(AvatarCreationCopy.yourShelf), findsOneWidget);
      expect(find.text(AvatarCreationCopy.delete), findsOneWidget);
      expect(find.text(AvatarCreationCopy.emptyAction), findsNothing);
    });

    testWidgets('five tabs sit on one row that scrolls, at 200% text too', (
      tester,
    ) async {
      final rig = StudioRig(member: Fixtures.sam);
      addTearDown(rig.close);
      await rig.pump(
        tester,
        tab: AvatarStudioTab.keepsakes,
        brightness: Brightness.dark,
        textScale: 2,
      );
      final tops = {
        for (final tab in AvatarStudioTab.values)
          tester.getTopLeft(find.widgetWithText(NestChip, tab.label)).dy,
      };
      expect(tops, hasLength(1));
      final chosen = tester.getRect(
        find.widgetWithText(NestChip, AvatarCreationCopy.keepsakesTab),
      );
      expect(chosen.left, greaterThanOrEqualTo(0));
      expect(
        chosen.right,
        lessThanOrEqualTo(
          tester.view.physicalSize.width / tester.view.devicePixelRatio,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('with the flag off there is no Create and no Keepsakes', (
      tester,
    ) async {
      final rig = StudioRig(member: Fixtures.sam, creations: false);
      addTearDown(rig.close);
      await rig.pump(tester, tab: AvatarStudioTab.create);
      expect(find.text(AvatarCreationCopy.createTab), findsNothing);
      expect(find.text(AvatarCreationCopy.keepsakesTab), findsNothing);
      expect(
        find.byType(NestSegmentedControl<AvatarStudioTab>),
        findsOneWidget,
      );
    });
  });

  testWidgets('a child builds a buddy by tapping, watches it hatch, and '
      'wears it', (tester) async {
    tall(tester);
    final rig = kidRig();
    addTearDown(rig.close);
    await rig.pump(tester, tab: AvatarStudioTab.create, asFamily: false);
    await tester.tap(card(CreationRecipe.buddy));
    await tester.pumpAndSettle();
    expect(find.text(AvatarCreationCopy.buddyStart), findsOneWidget);
    final hatch = find.widgetWithText(
      NestButton,
      AvatarCreationCopy.hatchBuddy,
    );
    await scrollTo(tester, hatch);
    expect(tester.widget<NestButton>(hatch).onPressed, isNull);

    await buildADragon(tester);
    expect(
      find.text('A purple dragon who loves pancakes, wears a cape and can fly'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'has spotty socks');
    await tapIn(tester, hatch);

    final request = rig.avatars.requested.single;
    expect(request.recipe, CreationRecipe.buddy);
    expect(request.memberId, Fixtures.kidMemberId);
    expect(request.by, Fixtures.kidMemberId);
    expect(request.extra, 'has spotty socks');
    expect(
      find.text(AvatarCreationCopy.hatching(CreationRecipe.buddy)),
      findsOneWidget,
    );
    expect(find.byType(NestTwig), findsOneWidget);
    expect(find.byType(NestEggWobble), findsOneWidget);

    rig.avatars.settleCreation(
      AvatarCreation(
        id: request.id,
        memberId: Fixtures.kidMemberId,
        recipe: CreationRecipe.buddy,
        status: CreationStatus.drawing,
      ),
    );
    await tester.pump();
    expect(find.text(AvatarCreationCopy.stepDrawing), findsOneWidget);

    rig.avatars.settleCreation(
      AvatarCreation(
        id: request.id,
        memberId: Fixtures.kidMemberId,
        recipe: CreationRecipe.buddy,
        status: CreationStatus.ready,
        imageHash: hash,
        left: 0,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(AvatarCreationCopy.readyTitle(CreationRecipe.buddy)),
      findsOneWidget,
    );
    expect(find.byType(NestHatchReveal), findsOneWidget);
    await tapIn(tester, find.text(AvatarCreationCopy.useIt));
    expect(rig.avatars.chosen.last.choice.base, const ImageBase(hash));
    expect(card(CreationRecipe.buddy), findsOneWidget);
  });

  testWidgets('a drawing is pictured with the back camera in its style, and '
      'goes up before it is asked for', (tester) async {
    tall(tester);
    final rig = kidRig();
    addTearDown(rig.close);
    await rig.pump(tester, tab: AvatarStudioTab.create, asFamily: false);
    await tester.tap(card(CreationRecipe.drawing));
    await tester.pumpAndSettle();
    expect(find.text(AvatarCreationCopy.pictureDisclosure), findsOneWidget);
    await tapIn(tester, find.byKey(const ValueKey('style-clay')));
    await tapIn(tester, find.text(AvatarCopy.choosePhoto));
    expect(rig.picker.asked.single, AvatarPhotoSource.library);
    expect(rig.picker.facing.single, isFalse);
    await tapIn(tester, find.text(AvatarCreationCopy.makeIt));

    final request = rig.avatars.requested.single;
    expect(request.style, CreationStyle.clay);
    expect(request.inboxId, request.id);
    expect(rig.photos.references.single.inboxId, request.id);
    await tester.pump(const Duration(minutes: 3));
  });

  testWidgets('a refused photo says why, kindly, and lets them try again', (
    tester,
  ) async {
    tall(tester);
    final rig = kidRig();
    addTearDown(rig.close);
    await rig.pump(tester, tab: AvatarStudioTab.create, asFamily: false);
    await tester.tap(card(CreationRecipe.drawing));
    await tester.pumpAndSettle();
    await tapIn(tester, find.text(AvatarCopy.takePhoto));
    await tapIn(tester, find.text(AvatarCreationCopy.makeIt));
    rig.avatars.settleCreation(
      AvatarCreation(
        id: rig.avatars.requested.single.id,
        memberId: Fixtures.kidMemberId,
        recipe: CreationRecipe.drawing,
        status: CreationStatus.refused,
        reason: CreationRefusal.notAllowed,
        left: 1,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'We can only use drawings, toys and pets — not photos of people.',
      ),
      findsOneWidget,
    );
    expect(find.byType(NestTwig), findsNothing);
    await tapIn(tester, find.text(AppCopy.retry));
    expect(
      find.text(AvatarCreationCopy.photoTitle(CreationRecipe.drawing)),
      findsOneWidget,
    );
  });

  testWidgets('a free household’s second try opens the paywall on '
      'creations', (tester) async {
    tall(tester);
    final rig = StudioRig(member: Fixtures.sam);
    addTearDown(rig.close);
    await rig.pump(tester, tab: AvatarStudioTab.create);
    await tester.tap(card(CreationRecipe.buddy));
    await tester.pumpAndSettle();
    await buildADragon(tester);
    await tapIn(tester, find.text(AvatarCreationCopy.hatchBuddy));
    rig.avatars.settleCreation(
      AvatarCreation(
        id: rig.avatars.requested.single.id,
        memberId: Fixtures.samMemberId,
        recipe: CreationRecipe.buddy,
        status: CreationStatus.refused,
        reason: CreationRefusal.premiumRequired,
        left: 0,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(SubscriptionCopy.headline(PremiumFeature.avatarCreate)),
      findsOneWidget,
    );
  });

  testWidgets('a month’s twelve used says when more come', (tester) async {
    tall(tester);
    final rig = StudioRig(member: Fixtures.sam, entitlement: premium);
    addTearDown(rig.close);
    await rig.pump(tester, tab: AvatarStudioTab.create);
    await tester.tap(card(CreationRecipe.buddy));
    await tester.pumpAndSettle();
    await buildADragon(tester);
    await tapIn(tester, find.text(AvatarCreationCopy.hatchBuddy));
    rig.avatars.settleCreation(
      AvatarCreation(
        id: rig.avatars.requested.single.id,
        memberId: Fixtures.samMemberId,
        recipe: CreationRecipe.buddy,
        status: CreationStatus.refused,
        reason: CreationRefusal.limitReached,
        left: 0,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('No more pictures this month'), findsOneWidget);
    expect(find.textContaining('12'), findsNothing);
  });

  testWidgets('family in a premium household make the Nest portrait, and '
      'are told it is on the frame', (tester) async {
    tall(tester);
    final rig = StudioRig(member: Fixtures.sam, entitlement: premium);
    addTearDown(rig.close);
    await rig.pump(tester, tab: AvatarStudioTab.create);
    await tapIn(tester, card(CreationRecipe.portrait));
    final request = rig.avatars.requested.single;
    expect(request.recipe, CreationRecipe.portrait);
    expect(request.memberId, Fixtures.samMemberId);
    expect(
      find.text(AvatarCreationCopy.hatching(CreationRecipe.portrait)),
      findsOneWidget,
    );
    rig.avatars.settleCreation(
      AvatarCreation(
        id: request.id,
        memberId: Fixtures.samMemberId,
        recipe: CreationRecipe.portrait,
        status: CreationStatus.ready,
        imageHash: hash,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(AvatarCreationCopy.portraitOnFrame), findsOneWidget);
    expect(find.text(AvatarCreationCopy.useIt), findsNothing);
    await tapIn(tester, find.text(AvatarCreationCopy.done));
    expect(rig.avatars.chosen, isEmpty);
  });

  testWidgets('a free household’s portrait opens the paywall on the '
      'portrait', (tester) async {
    tall(tester);
    final rig = StudioRig(member: Fixtures.sam);
    addTearDown(rig.close);
    await rig.pump(tester, tab: AvatarStudioTab.create);
    await tapIn(tester, card(CreationRecipe.portrait));
    expect(
      find.text(SubscriptionCopy.headline(PremiumFeature.avatarPortrait)),
      findsOneWidget,
    );
    expect(rig.avatars.requested, isEmpty);
  });

  testWidgets('a hatch that takes too long says it will land on the shelf', (
    tester,
  ) async {
    tall(tester);
    final rig = StudioRig(
      member: Fixtures.kid,
      viewerMemberId: Fixtures.kidMemberId,
      creationWait: const Duration(seconds: 2),
    );
    addTearDown(rig.close);
    await rig.pump(tester, tab: AvatarStudioTab.create, asFamily: false);
    await tester.tap(card(CreationRecipe.buddy));
    await tester.pumpAndSettle();
    await buildADragon(tester);
    await tapIn(tester, find.text(AvatarCreationCopy.hatchBuddy));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text(AvatarCreationCopy.tooSlowBody), findsOneWidget);
    await tapIn(tester, find.text(AvatarCreationCopy.seeShelf));
    expect(find.text(AvatarCreationCopy.emptyTitle), findsOneWidget);
  });

  group('in dark at 200% text on a 360-wide phone', () {
    Future<StudioRig> open(WidgetTester tester) async {
      phone(tester);
      final rig = kidRig(entitlement: premium);
      addTearDown(rig.close);
      await rig.pump(
        tester,
        tab: AvatarStudioTab.create,
        asFamily: false,
        brightness: Brightness.dark,
        textScale: 2,
      );
      return rig;
    }

    testWidgets('the buddy builder holds', (tester) async {
      final rig = await open(tester);
      await tapIn(tester, card(CreationRecipe.buddy));
      await buildADragon(tester);
      await overflowFree(tester);
      expect(rig.avatars.requested, isEmpty);
    });

    testWidgets('the drawing picker holds, photo chosen', (tester) async {
      await open(tester);
      await tapIn(tester, card(CreationRecipe.drawing));
      await tapIn(tester, find.text(AvatarCopy.choosePhoto));
      await overflowFree(tester);
    });

    for (final (name, status) in [
      ('hatching', CreationStatus.drawing),
      ('ready', CreationStatus.ready),
      ('refused', CreationStatus.refused),
    ]) {
      testWidgets('the $name step holds', (tester) async {
        final rig = await open(tester);
        await tapIn(tester, card(CreationRecipe.buddy));
        await buildADragon(tester);
        await tapIn(tester, find.text(AvatarCreationCopy.hatchBuddy));
        rig.avatars.settleCreation(
          AvatarCreation(
            id: rig.avatars.requested.single.id,
            memberId: Fixtures.kidMemberId,
            recipe: CreationRecipe.buddy,
            status: status,
            reason: status == CreationStatus.refused
                ? CreationRefusal.declined
                : null,
            imageHash: status == CreationStatus.ready ? hash : null,
          ),
        );
        await tester.pumpAndSettle();
        await overflowFree(tester);
        await tester.pump(const Duration(minutes: 3));
      });
    }
  });
}
