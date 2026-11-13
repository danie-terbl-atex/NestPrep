import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/avatars/data/avatar_photo_picker.dart';
import 'package:nestprep/features/avatars/model/avatar_base.dart';
import 'package:nestprep/features/avatars/model/avatar_catalogue.g.dart';
import 'package:nestprep/features/avatars/model/avatar_choice.dart';
import 'package:nestprep/features/avatars/model/avatar_purchase.dart';
import 'package:nestprep/features/avatars/model/member_avatar_record.dart';
import 'package:nestprep/features/avatars/model/member_look.dart';
import 'package:nestprep/features/avatars/ui/avatar_studio_tab.dart';
import 'package:nestprep/features/chore_points/model/point_balance.dart';
import 'package:nestprep/shared/copy/app_copy.dart';

import '../../../support/avatar_studio_rig.dart';
import '../../../support/household_fixtures.dart';

void main() {
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  for (final tab in AvatarStudioTab.values) {
    for (final member in [Fixtures.sam, Fixtures.kid]) {
      testWidgets('the ${tab.name} tab for ${member.roleName} holds in dark '
          'at 200% text on a 360-wide phone', (tester) async {
        phone(tester);
        final rig = StudioRig(
          member: member.copyWith(
            look: const MemberLook(base: PresetBase('pip'), stage: 2),
          ),
          record: const MemberAvatarRecord(
            choice: AvatarChoice(base: PresetBase('pip')),
            ownedAccessories: {'acc-crown'},
          ),
        );
        addTearDown(rig.close);
        await rig.pump(
          tester,
          tab: tab,
          brightness: Brightness.dark,
          textScale: 2,
          balance: PointBalance(id: member.id, balance: 12, earned: 12),
        );
        for (var i = 0; i < 6; i++) {
          await tester.drag(find.byType(ListView).first, const Offset(0, -600));
          await tester.pump();
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('a grown-up picks a Nestling and how grown-up it is', (
    tester,
  ) async {
    final rig = StudioRig(member: Fixtures.sam);
    addTearDown(rig.close);
    await rig.pump(tester);
    expect(find.text(AvatarCopy.yourTitle), findsOneWidget);
    expect(find.text(AvatarCopy.howGrownUp), findsNothing);

    await tester.tap(find.byKey(const ValueKey('nestling-olive')));
    await tester.pumpAndSettle();
    expect(rig.avatars.chosen.single.choice.base, const PresetBase('olive'));
    expect(find.text(AvatarCopy.howGrownUp), findsOneWidget);
    expect(find.text(AvatarCopy.useMyInitial), findsOneWidget);

    await tester.ensureVisible(find.text(AvatarCopy.stageName(1)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AvatarCopy.stageName(1)));
    await tester.pumpAndSettle();
    expect(rig.avatars.chosen.last.choice.stage, 1);
  });

  testWidgets('a child with no stars yet is told how to hatch', (tester) async {
    final rig = StudioRig(
      member: Fixtures.kid,
      viewerMemberId: Fixtures.kidMemberId,
    );
    addTearDown(rig.close);
    await rig.pump(tester);
    expect(find.text(AvatarCopy.kidEggTitle), findsOneWidget);
    expect(find.text(AvatarCopy.kidPickTitle), findsOneWidget);
    expect(find.text(AvatarCopy.howGrownUp), findsNothing);
  });

  testWidgets('a child two days into a streak sees how far to wings', (
    tester,
  ) async {
    final rig = StudioRig(
      member: Fixtures.kid,
      viewerMemberId: Fixtures.kidMemberId,
    );
    addTearDown(rig.close);
    await rig.pump(
      tester,
      balance: const PointBalance(
        id: Fixtures.kidMemberId,
        earned: 5,
        bestStreak: 2,
      ),
    );
    expect(find.text(AvatarCopy.kidHatchlingTitle), findsOneWidget);
    expect(find.text(AvatarCopy.kidHatchlingBody(1)), findsOneWidget);
    expect(find.text(AvatarCopy.daysInARow(2, 3)), findsOneWidget);
  });

  testWidgets('a parent looking at a child reads how it grows, in their '
      'words', (tester) async {
    final rig = StudioRig(member: Fixtures.kid);
    addTearDown(rig.close);
    await rig.pump(tester);
    expect(
      find.text(AvatarCopy.title(Fixtures.kid.displayName)),
      findsOneWidget,
    );
    expect(
      find.text(AvatarCopy.parentStageBody(Fixtures.kid.displayName)),
      findsOneWidget,
    );
  });

  testWidgets('a child wears what is free and what they own', (tester) async {
    final rig = StudioRig(
      member: Fixtures.kid,
      viewerMemberId: Fixtures.kidMemberId,
      record: const MemberAvatarRecord(ownedAccessories: {'acc-crown'}),
    );
    addTearDown(rig.close);
    await rig.pump(tester, tab: AvatarStudioTab.wardrobe);
    expect(find.byKey(const ValueKey('wear-acc-party-hat')), findsOneWidget);
    expect(find.byKey(const ValueKey('wear-acc-crown')), findsOneWidget);
    expect(find.byKey(const ValueKey('wear-acc-wizard-hat')), findsNothing);
  });

  testWidgets('a grown-up wears every accessory with no stars and no shop, and '
      'takes it off again', (tester) async {
    final rig = StudioRig(member: Fixtures.sam);
    addTearDown(rig.close);
    await rig.pump(tester, tab: AvatarStudioTab.wardrobe);
    expect(find.byKey(const ValueKey('wear-acc-party-hat')), findsOneWidget);
    expect(find.byKey(const ValueKey('wear-acc-crown')), findsOneWidget);
    expect(find.byKey(const ValueKey('wear-acc-wizard-hat')), findsOneWidget);
    expect(find.text(AvatarCopy.shopTitle), findsNothing);
    expect(find.textContaining('stars'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('wear-acc-party-hat')));
    await tester.pumpAndSettle();
    expect(rig.avatars.chosen.last.choice.wear, {
      AvatarSlot.top: 'acc-party-hat',
    });
    await tester.tap(find.byKey(const ValueKey('wear-acc-party-hat')));
    await tester.pumpAndSettle();
    expect(rig.avatars.chosen.last.choice.wear, isEmpty);
  });

  testWidgets('glasses wait for a Nestling', (tester) async {
    final rig = StudioRig(member: Fixtures.sam);
    addTearDown(rig.close);
    await rig.pump(tester, tab: AvatarStudioTab.wardrobe);
    await tester.scrollUntilVisible(
      find.text(AvatarCopy.faceNeedsNestling),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(AvatarCopy.faceNeedsNestling), findsOneWidget);
  });

  testWidgets('a Nestling can wear glasses', (tester) async {
    final rig = StudioRig(
      member: Fixtures.sam.copyWith(
        look: const MemberLook(base: PresetBase('olive'), stage: 3),
      ),
      record: const MemberAvatarRecord(
        choice: AvatarChoice(base: PresetBase('olive'), stage: 3),
      ),
    );
    addTearDown(rig.close);
    await rig.pump(tester, tab: AvatarStudioTab.wardrobe);
    final glasses = find.byKey(const ValueKey('wear-acc-round-glasses'));
    await tester.scrollUntilVisible(
      glasses,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(AvatarCopy.faceNeedsNestling), findsNothing);
    await tester.ensureVisible(glasses);
    await tester.pumpAndSettle();
    await tester.tap(glasses);
    await tester.pumpAndSettle();
    expect(rig.avatars.chosen.last.choice.wear, {
      AvatarSlot.face: 'acc-round-glasses',
    });
  });

  testWidgets('a child buys a crown with stars, and wears it', (tester) async {
    final rig = StudioRig(
      member: Fixtures.kid,
      viewerMemberId: Fixtures.kidMemberId,
    );
    addTearDown(rig.close);
    await rig.pump(
      tester,
      tab: AvatarStudioTab.wardrobe,
      balance: const PointBalance(
        id: Fixtures.kidMemberId,
        balance: 25,
        earned: 25,
      ),
    );
    final crown = find.byKey(const ValueKey('shop-acc-crown'));
    await tester.scrollUntilVisible(
      crown,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(crown);
    await tester.pumpAndSettle();
    expect(find.text(AvatarCopy.shopBody(25)), findsOneWidget);
    expect(find.byKey(const ValueKey('shop-acc-party-hat')), findsNothing);
    await tester.tap(crown);
    await tester.pumpAndSettle();
    expect(find.text(AvatarCopy.buyConfirm('Crown', 20)), findsOneWidget);
    await tester.tap(find.text(AvatarCopy.buyYes));
    await tester.pump();
    expect(rig.avatars.bought.single.accessoryId, 'acc-crown');
    expect(rig.controller.isBuying('acc-crown'), isTrue);

    rig.avatars.settle(
      const AvatarPurchase(
        id: 'purchase-1',
        memberId: Fixtures.kidMemberId,
        accessoryId: 'acc-crown',
        status: PurchaseStatus.owned,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text(AvatarCopy.boughtTitle('Crown')), findsOneWidget);
    expect(rig.avatars.chosen.last.choice.wear, {AvatarSlot.top: 'acc-crown'});
    await tester.pumpAndSettle();
  });

  testWidgets('a refused purchase says why, kindly', (tester) async {
    final rig = StudioRig(
      member: Fixtures.kid,
      viewerMemberId: Fixtures.kidMemberId,
    );
    addTearDown(rig.close);
    await rig.pump(
      tester,
      tab: AvatarStudioTab.wardrobe,
      balance: const PointBalance(
        id: Fixtures.kidMemberId,
        balance: 25,
        earned: 25,
      ),
    );
    final crown = find.byKey(const ValueKey('shop-acc-crown'));
    await tester.scrollUntilVisible(
      crown,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(crown);
    await tester.pumpAndSettle();
    await tester.tap(crown);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AvatarCopy.buyYes));
    await tester.pump();
    rig.avatars.settle(
      const AvatarPurchase(
        id: 'purchase-1',
        memberId: Fixtures.kidMemberId,
        accessoryId: 'acc-crown',
        status: PurchaseStatus.refused,
        reason: PurchaseRefusal.notEnoughStars,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(AvatarCopy.refused(PurchaseRefusal.notEnoughStars)),
      findsOneWidget,
    );
    expect(rig.avatars.chosen, isEmpty);
    await tester.tap(find.text(AppCopy.back).last);
    await tester.pumpAndSettle();
    expect(
      find.text(AvatarCopy.refused(PurchaseRefusal.notEnoughStars)),
      findsNothing,
    );
  });

  testWidgets('what a child cannot afford yet is locked, not offered', (
    tester,
  ) async {
    final rig = StudioRig(
      member: Fixtures.kid,
      viewerMemberId: Fixtures.kidMemberId,
    );
    addTearDown(rig.close);
    await rig.pump(
      tester,
      tab: AvatarStudioTab.wardrobe,
      balance: const PointBalance(
        id: Fixtures.kidMemberId,
        balance: 3,
        earned: 3,
      ),
    );
    final crown = find.byKey(const ValueKey('shop-acc-crown'));
    await tester.scrollUntilVisible(
      crown,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(crown);
    await tester.pumpAndSettle();
    await tester.tap(crown);
    await tester.pumpAndSettle();
    expect(find.text(AvatarCopy.buyYes), findsNothing);
  });

  testWidgets('with the shop switched off a child is told, and keeps what '
      'is free', (tester) async {
    final rig = StudioRig(
      member: Fixtures.kid,
      viewerMemberId: Fixtures.kidMemberId,
    );
    addTearDown(rig.close);
    await rig.pump(tester, tab: AvatarStudioTab.wardrobe, shopIsOpen: false);
    expect(find.byKey(const ValueKey('wear-acc-party-hat')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(AvatarCopy.shopClosed),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(AvatarCopy.shopTitle), findsNothing);
  });

  testWidgets('a photo is chosen, fitted in the circle and saved', (
    tester,
  ) async {
    final rig = StudioRig(member: Fixtures.sam, photo: aPhoto());
    addTearDown(rig.close);
    await rig.pump(tester, tab: AvatarStudioTab.photo);
    await tester.runAsync(() async {
      await tester.tap(find.text(AvatarCopy.choosePhoto));
      await Future<void>.delayed(const Duration(seconds: 1));
    });
    await tester.pumpAndSettle();
    expect(rig.picker.asked.single, AvatarPhotoSource.library);
    expect(find.byType(NestCircleCropper), findsOneWidget);
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
    expect(rig.avatars.offered.single.hash, rig.photos.uploaded.single.hash);
    expect(find.byType(NestCircleCropper), findsNothing);
  });

  testWidgets('back to the initial', (tester) async {
    final rig = StudioRig(
      member: Fixtures.sam,
      record: const MemberAvatarRecord(
        choice: AvatarChoice(base: PresetBase('pip')),
      ),
    );
    addTearDown(rig.close);
    await rig.pump(tester);
    await tester.tap(find.text(AvatarCopy.useMyInitial));
    await tester.pumpAndSettle();
    expect(rig.avatars.chosen.single.choice.base, const InitialBase());
    expect(find.text(AvatarCopy.useMyInitial), findsNothing);
  });
}
