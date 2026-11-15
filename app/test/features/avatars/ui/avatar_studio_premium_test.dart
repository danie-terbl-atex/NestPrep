import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/avatars/model/avatar_base.dart';
import 'package:nestprep/features/avatars/model/avatar_catalogue.g.dart';
import 'package:nestprep/features/avatars/model/avatar_choice.dart';
import 'package:nestprep/features/avatars/model/avatar_creation.dart';
import 'package:nestprep/features/avatars/model/avatar_keepsake.dart';
import 'package:nestprep/features/avatars/model/member_avatar_record.dart';
import 'package:nestprep/features/avatars/model/member_look.dart';
import 'package:nestprep/features/avatars/ui/avatar_studio_tab.dart';
import 'package:nestprep/features/avatars/ui/member_avatar.dart';
import 'package:nestprep/features/avatars/ui/studio_locked_tab.dart';
import 'package:nestprep/features/avatars/ui/studio_preview.dart';
import 'package:nestprep/features/chore_points/model/point_balance.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/subscription_copy.dart';

import '../../../support/avatar_studio_rig.dart';
import '../../../support/household_fixtures.dart';

void main() {
  const crowned = AvatarChoice(
    base: PresetBase('pip'),
    wear: {AvatarSlot.top: 'acc-crown'},
  );
  const locked = {
    AvatarStudioTab.wardrobe: PremiumFeature.avatarWardrobe,
    AvatarStudioTab.create: PremiumFeature.avatarCreate,
    AvatarStudioTab.keepsakes: PremiumFeature.avatarKeepsakes,
  };

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  StudioRig freeRig(Member member, {bool crown = false}) {
    final rig = StudioRig(
      member: crown
          ? member.copyWith(
              look: MemberLook(
                base: crowned.base,
                stage: 2,
                wear: crowned.wear,
              ),
            )
          : member,
      viewerMemberId: member.id,
      record: crown
          ? const MemberAvatarRecord(
              choice: crowned,
              ownedAccessories: {'acc-crown'},
            )
          : MemberAvatarRecord.none,
      entitlement: Entitlement.free,
    );
    addTearDown(rig.close);
    return rig;
  }

  group('a household without Premium', () {
    testWidgets('keeps all five tabs, three of them under a lock', (
      tester,
    ) async {
      final rig = freeRig(Fixtures.sam);
      await rig.pump(tester);
      for (final tab in AvatarStudioTab.values) {
        expect(
          find.widgetWithText(NestChip, tab.label),
          findsOneWidget,
          reason: tab.name,
        );
        expect(
          find.descendant(
            of: find.widgetWithText(NestChip, tab.label),
            matching: find.byIcon(LucideIcons.lock),
          ),
          locked.containsKey(tab) ? findsOneWidget : findsNothing,
          reason: tab.name,
        );
      }
      expect(find.byKey(const ValueKey('nestling-olive')), findsOneWidget);
    });

    testWidgets('keeps the wardrobe tab, locked, with the flag for creations '
        'off', (tester) async {
      final rig = StudioRig(
        member: Fixtures.sam,
        creations: false,
        entitlement: Entitlement.free,
      );
      addTearDown(rig.close);
      await rig.pump(tester, tab: AvatarStudioTab.wardrobe);
      expect(find.text(AvatarCopy.wardrobe), findsOneWidget);
      expect(find.byIcon(LucideIcons.lock), findsNWidgets(2));
      expect(
        find.text(SubscriptionCopy.headline(PremiumFeature.avatarWardrobe)),
        findsOneWidget,
      );
    });

    for (final MapEntry(key: tab, value: feature) in locked.entries) {
      testWidgets('finds ${tab.name} locked, and the way to Premium on it', (
        tester,
      ) async {
        final rig = freeRig(Fixtures.kid, crown: true);
        rig.avatars.emitKeepsakes(Fixtures.kidMemberId, const [
          AvatarKeepsake(
            id: 'k-buddy',
            memberId: Fixtures.kidMemberId,
            recipe: CreationRecipe.buddy,
            imageHash: '0123456789abcdef0123456789abcdef',
          ),
        ]);
        await rig.pump(
          tester,
          tab: tab,
          balance: const PointBalance(
            id: Fixtures.kidMemberId,
            balance: 40,
            earned: 40,
          ),
        );
        expect(find.text(SubscriptionCopy.headline(feature)), findsOneWidget);
        expect(find.text(SubscriptionCopy.pitch(feature)), findsOneWidget);
        expect(find.byKey(const ValueKey('wear-acc-crown')), findsNothing);
        expect(find.text(AvatarCopy.shopTitle), findsNothing);
        expect(find.byKey(const ValueKey('create-buddy')), findsNothing);
        expect(find.byKey(const ValueKey('keepsake-k-buddy')), findsNothing);

        await tester.ensureVisible(find.text(SubscriptionCopy.seePremium));
        await tester.pumpAndSettle();
        await tester.tap(find.text(SubscriptionCopy.seePremium));
        await tester.pumpAndSettle();
        expect(
          rig.subscriptions.paywallOpens.opened.map((open) => open.trigger),
          [feature],
        );
        expect(rig.avatars.chosen, isEmpty);
        expect(rig.avatars.requested, isEmpty);
      });
    }

    testWidgets('still wears what it had on, and keeps it on through a new '
        'Nestling', (tester) async {
      final rig = freeRig(Fixtures.sam, crown: true);
      await rig.pump(tester);
      expect(
        tester
            .widget<MemberAvatar>(
              find.descendant(
                of: find.byType(StudioPreview),
                matching: find.byType(MemberAvatar),
              ),
            )
            .look
            ?.wear,
        crowned.wear,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('nestling-olive')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nestling-olive')));
      await tester.pumpAndSettle();
      final choice = rig.avatars.chosen.single.choice;
      expect(choice.base, const PresetBase('olive'));
      expect(choice.wear, crowned.wear);

      await tester.drag(find.byType(ListView).first, const Offset(0, 800));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AvatarCopy.useMyInitial));
      await tester.pumpAndSettle();
      expect(rig.avatars.chosen.last.choice.base, const InitialBase());
      expect(rig.avatars.chosen.last.choice.wear, crowned.wear);
    });

    testWidgets('picks a Nestling', (tester) async {
      final rig = freeRig(Fixtures.sam);
      await rig.pump(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('nestling-olive')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nestling-olive')));
      await tester.pumpAndSettle();

      final chosen = rig.avatars.chosen.single;
      expect(chosen.memberId, Fixtures.samMemberId);
      expect(chosen.choice.base, const PresetBase('olive'));
      expect(chosen.choice.wear, isEmpty);
      expect(rig.subscriptions.paywallOpens.opened, isEmpty);
    });

    testWidgets('picks a photo, which is uploaded and offered', (tester) async {
      final rig = StudioRig(
        member: Fixtures.sam,
        photo: aPhoto(),
        entitlement: Entitlement.free,
      );
      addTearDown(rig.close);
      await rig.pump(tester, tab: AvatarStudioTab.photo);
      expect(find.byType(StudioLockedTab), findsNothing);
      await tester.runAsync(() async {
        await tester.tap(find.text(AvatarCopy.choosePhoto));
        await Future<void>.delayed(const Duration(seconds: 1));
      });
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(AvatarCopy.usePhoto));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text(AvatarCopy.usePhoto));
        for (var i = 0; i < 50 && rig.photos.uploaded.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      });
      await tester.pumpAndSettle();

      expect(rig.photos.uploaded, hasLength(1));
      final offered = rig.avatars.offered.single;
      expect(offered.memberId, Fixtures.samMemberId);
      expect(offered.hash, rig.photos.uploaded.single.hash);
      expect(rig.subscriptions.paywallOpens.opened, isEmpty);
    });

    testWidgets('goes back to the initial from a Nestling in glasses, which '
        'come off while the crown stays', (tester) async {
      const dressed = AvatarChoice(
        base: PresetBase('pip'),
        wear: {
          AvatarSlot.top: 'acc-crown',
          AvatarSlot.face: 'acc-round-glasses',
        },
      );
      final rig = StudioRig(
        member: Fixtures.sam.copyWith(
          look: MemberLook(base: dressed.base, stage: 2, wear: dressed.wear),
        ),
        record: const MemberAvatarRecord(choice: dressed),
        entitlement: Entitlement.free,
      );
      addTearDown(rig.close);
      await rig.pump(tester);
      await tester.drag(find.byType(ListView).first, const Offset(0, 800));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AvatarCopy.useMyInitial));
      await tester.pumpAndSettle();

      final choice = rig.avatars.chosen.single.choice;
      expect(choice.base, const InitialBase());
      expect(choice.wear, {AvatarSlot.top: 'acc-crown'});
    });

    for (final MapEntry(key: tab, value: feature) in locked.entries) {
      testWidgets('on a child’s own device, is told ${tab.name} is for a '
          'parent to ask about, and is offered nothing to buy', (tester) async {
        final rig = freeRig(Fixtures.kid, crown: true);
        await rig.pump(tester, tab: tab, asFamily: false, onKidDevice: true);
        expect(find.text(SubscriptionCopy.headline(feature)), findsOneWidget);
        expect(find.text(AvatarCopy.premiumAskParent), findsOneWidget);
        expect(find.text(SubscriptionCopy.seePremium), findsNothing);
        expect(
          find.descendant(
            of: find.byType(StudioLockedTab),
            matching: find.byType(NestButton),
          ),
          findsNothing,
        );
        expect(rig.subscriptions.paywallOpens.opened, isEmpty);
      });
    }

    for (final tab in locked.keys) {
      for (final onKidDevice in [false, true]) {
        testWidgets('the locked ${tab.name} tab holds in dark at 200% text on '
            'a 360-wide phone${onKidDevice ? ', on a kid device' : ''}', (
          tester,
        ) async {
          phone(tester);
          final rig = freeRig(Fixtures.kid, crown: true);
          await rig.pump(
            tester,
            tab: tab,
            asFamily: false,
            onKidDevice: onKidDevice,
            brightness: Brightness.dark,
            textScale: 2,
          );
          expect(
            find.text(SubscriptionCopy.headline(locked[tab]!)),
            findsOneWidget,
          );
          for (var i = 0; i < 6; i++) {
            await tester.drag(
              find.byType(ListView).first,
              const Offset(0, -600),
            );
            await tester.pump();
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  testWidgets('a household with Premium has no lock on any tab', (
    tester,
  ) async {
    final rig = StudioRig(member: Fixtures.sam);
    addTearDown(rig.close);
    await rig.pump(tester, tab: AvatarStudioTab.wardrobe);
    expect(find.byIcon(LucideIcons.lock), findsNothing);
    expect(find.byKey(const ValueKey('wear-acc-crown')), findsOneWidget);
  });
}
