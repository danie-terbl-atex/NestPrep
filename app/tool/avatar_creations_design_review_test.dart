import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nestprep/features/avatars/model/avatar_base.dart';
import 'package:nestprep/features/avatars/model/avatar_buddy.dart';
import 'package:nestprep/features/avatars/model/avatar_catalogue.g.dart';
import 'package:nestprep/features/avatars/model/avatar_choice.dart';
import 'package:nestprep/features/avatars/model/avatar_creation.dart';
import 'package:nestprep/features/avatars/model/avatar_keepsake.dart';
import 'package:nestprep/features/avatars/model/member_avatar_record.dart';
import 'package:nestprep/features/avatars/model/member_look.dart';
import 'package:nestprep/features/avatars/ui/avatar_studio_screen.dart';
import 'package:nestprep/features/avatars/ui/avatar_studio_tab.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/avatar_studio_rig.dart';
import '../test/support/household_fixtures.dart';
import 'review_press.dart';

void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  const made = '0123456789abcdef0123456789abcdef';
  const second = 'fedcba9876543210fedcba9876543210';
  const portrait = 'aaaaaaaaaaaaaaaabbbbbbbbbbbbbbbb';
  final premium = Entitlement(premiumUntil: DateTime.utc(2100));
  final madeBytes = File('../functions/assets/emulator_avatar.jpg')
      .readAsBytesSync();
  final portraitBytes = File('../functions/assets/emulator_portrait.jpg')
      .readAsBytesSync();

  Uint8List aDrawing() {
    final page = img.Image(width: 320, height: 240)
      ..clear(img.ColorRgb8(250, 248, 240));
    img.fillCircle(
      page,
      x: 160,
      y: 120,
      radius: 70,
      color: img.ColorRgb8(150, 90, 200),
    );
    img.fillCircle(
      page,
      x: 135,
      y: 105,
      radius: 10,
      color: img.ColorRgb8(0, 0, 0),
    );
    img.fillCircle(
      page,
      x: 185,
      y: 105,
      radius: 10,
      color: img.ColorRgb8(0, 0, 0),
    );
    img.drawLine(
      page,
      x1: 130,
      y1: 150,
      x2: 190,
      y2: 150,
      color: img.ColorRgb8(240, 80, 80),
      thickness: 6,
    );
    for (final x in [100, 220]) {
      img.drawLine(
        page,
        x1: x,
        y1: 70,
        x2: x - 20 + (x == 220 ? 40 : 0),
        y2: 30,
        color: img.ColorRgb8(240, 170, 40),
        thickness: 8,
      );
    }
    return Uint8List.fromList(img.encodeJpg(page));
  }

  final drawing = aDrawing();

  final mia = Fixtures.kid.copyWith(
    displayName: 'Mia',
    look: const MemberLook(base: PresetBase('pip'), stage: 2),
  );
  final sam = Fixtures.sam.copyWith(
    look: const MemberLook(base: PresetBase('olive'), stage: 3),
  );

  StudioRig rigFor(
    Member member, {
    String? viewer,
    Entitlement entitlement = Entitlement.free,
    MemberAvatarRecord record = const MemberAvatarRecord(
      choice: AvatarChoice(base: PresetBase('pip')),
    ),
  }) {
    final rig = StudioRig(
      member: member,
      viewerMemberId: viewer ?? member.id,
      entitlement: entitlement,
      record: record,
      photo: drawing,
    );
    rig.photos.stored[made] = madeBytes;
    rig.photos.stored[second] = madeBytes;
    rig.photos.stored[portrait] = portraitBytes;
    addTearDown(rig.close);
    return rig;
  }

  Future<void> shoot(
    WidgetTester tester,
    String name,
    StudioRig rig, {
    AvatarStudioTab tab = AvatarStudioTab.create,
    bool asFamily = true,
    bool creationsOn = true,
    Brightness brightness = Brightness.light,
    double textScale = 1,
    Future<void> Function()? act,
  }) async {
    await captureScreen(
      tester,
      name,
      screen: AvatarStudioScreen(initialTab: tab),
      providers: rig.providers,
      view: rig.viewFor(asFamily: asFamily, creationsOn: creationsOn),
      brightness: brightness,
      textScale: textScale,
      emit: () async {
        rig.households
          ..emitMember(rig.member)
          ..emitHousehold(
            Fixtures.household().copyWith(avatarCreationsOn: creationsOn),
          );
        await tester.pump();
      },
      act: act,
    );
    await tester.pump(const Duration(minutes: 3));
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 200, scrollable: screenList());
    await tester.pumpAndSettle();
  }

  Future<void> tapIn(WidgetTester tester, Finder finder) async {
    await scrollTo(tester, finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Finder card(CreationRecipe recipe) =>
      find.byKey(ValueKey('create-${recipe.name}'));

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

  Future<void> hatch(
    WidgetTester tester,
    StudioRig rig, {
    required CreationStatus status,
    CreationRefusal? reason,
  }) async {
    await tapIn(tester, card(CreationRecipe.buddy));
    await buildADragon(tester);
    await tapIn(tester, find.text(AvatarCreationCopy.hatchBuddy));
    rig.avatars.settleCreation(
      AvatarCreation(
        id: rig.avatars.requested.single.id,
        memberId: rig.member.id,
        recipe: CreationRecipe.buddy,
        status: status,
        reason: reason,
        imageHash: status == CreationStatus.ready ? made : null,
        left: 3,
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(screenList(), const Offset(0, 2000));
    await tester.pumpAndSettle();
    await tester.drag(screenList(), const Offset(0, -260));
  }

  for (final brightness in Brightness.values) {
    testWidgets('the menu, ${brightness.name}', (tester) async {
      final rig = rigFor(sam);
      await shoot(
        tester,
        'avatar-create-menu-${brightness.name}',
        rig,
        brightness: brightness,
        act: () => tester.drag(screenList(), const Offset(0, -260)),
      );
    });

    testWidgets('hatching, ${brightness.name}', (tester) async {
      final rig = rigFor(mia, entitlement: premium);
      await shoot(
        tester,
        'avatar-create-hatching-${brightness.name}',
        rig,
        asFamily: false,
        brightness: brightness,
        act: () => hatch(tester, rig, status: CreationStatus.drawing),
      );
    });

    testWidgets('ready, ${brightness.name}', (tester) async {
      final rig = rigFor(mia, entitlement: premium);
      await shoot(
        tester,
        'avatar-create-ready-${brightness.name}',
        rig,
        asFamily: false,
        brightness: brightness,
        act: () => hatch(tester, rig, status: CreationStatus.ready),
      );
    });

    testWidgets('the keepsakes shelf, ${brightness.name}', (tester) async {
      final rig = rigFor(
        mia,
        record: const MemberAvatarRecord(
          choice: AvatarChoice(base: ImageBase(made)),
          ownedImages: [made, second],
        ),
      );
      const original = 'households/h1/avatars/m-kid/keepsakes/k1.jpg';
      rig.photos.atPath[original] = drawing;
      await shoot(
        tester,
        'avatar-keepsakes-${brightness.name}',
        rig,
        tab: AvatarStudioTab.keepsakes,
        asFamily: false,
        brightness: brightness,
        act: () async {
          rig.avatars.emitKeepsakes(mia.id, [
            AvatarKeepsake(
              id: 'k2',
              memberId: mia.id,
              recipe: CreationRecipe.buddy,
              style: CreationStyle.plush,
              imageHash: second,
              buddy: const AvatarBuddy({
                AvatarBuddyKind.creature: 'dragon',
                AvatarBuddyKind.colour: 'purple',
                AvatarBuddyKind.loves: 'pancakes',
                AvatarBuddyKind.wears: 'cape',
                AvatarBuddyKind.power: 'flying',
              }),
              createdAt: DateTime(2026, 11, 12),
            ),
            AvatarKeepsake(
              id: 'k1',
              memberId: mia.id,
              recipe: CreationRecipe.drawing,
              style: CreationStyle.clay,
              imageHash: made,
              originalPath: original,
              createdAt: DateTime(2026, 11, 2),
            ),
          ]);
          await tester.pumpAndSettle();
          await tester.drag(screenList(), const Offset(0, -260));
        },
      );
    });
  }

  testWidgets('build a buddy', (tester) async {
    final rig = rigFor(mia, entitlement: premium);
    await shoot(
      tester,
      'avatar-create-buddy-light',
      rig,
      asFamily: false,
      act: () async {
        await tapIn(tester, card(CreationRecipe.buddy));
        await buildADragon(tester);
        await tester.drag(screenList(), const Offset(0, 2000));
        await tester.pumpAndSettle();
        await tester.drag(screenList(), const Offset(0, -320));
      },
    );
  });

  testWidgets('build a buddy, dark at 200% text', (tester) async {
    final rig = rigFor(mia, entitlement: premium);
    await shoot(
      tester,
      'avatar-create-buddy-dark-200-percent-text',
      rig,
      asFamily: false,
      brightness: Brightness.dark,
      textScale: 2,
      act: () async {
        await tapIn(tester, card(CreationRecipe.buddy));
        await buildADragon(tester);
      },
    );
  });

  testWidgets('a drawing to toy, photo chosen', (tester) async {
    final rig = rigFor(mia, entitlement: premium);
    await shoot(
      tester,
      'avatar-create-drawing-light',
      rig,
      asFamily: false,
      act: () async {
        await tapIn(tester, card(CreationRecipe.drawing));
        await tapIn(tester, find.byKey(const ValueKey('style-clay')));
        await tapIn(tester, find.text(AvatarCopy.choosePhoto));
        await scrollTo(tester, find.text(AvatarCreationCopy.makeIt));
      },
    );
  });

  testWidgets('a pet twin, before the photo', (tester) async {
    final rig = rigFor(sam);
    await shoot(
      tester,
      'avatar-create-pet-light',
      rig,
      act: () async {
        await tapIn(tester, card(CreationRecipe.pet));
        await scrollTo(tester, find.text(AvatarCopy.choosePhoto));
      },
    );
  });

  testWidgets('refused', (tester) async {
    final rig = rigFor(mia, entitlement: premium);
    await shoot(
      tester,
      'avatar-create-refused-light',
      rig,
      asFamily: false,
      act: () => hatch(
        tester,
        rig,
        status: CreationStatus.refused,
        reason: CreationRefusal.notAllowed,
      ),
    );
  });

  testWidgets('the Nest portrait, ready', (tester) async {
    final rig = rigFor(sam, entitlement: premium);
    await shoot(
      tester,
      'avatar-create-portrait-ready-light',
      rig,
      act: () async {
        await tapIn(tester, card(CreationRecipe.portrait));
        rig.avatars.settleCreation(
          AvatarCreation(
            id: rig.avatars.requested.single.id,
            memberId: sam.id,
            recipe: CreationRecipe.portrait,
            status: CreationStatus.ready,
            imageHash: portrait,
          ),
        );
        await tester.pumpAndSettle();
        await tester.drag(screenList(), const Offset(0, 2000));
        await tester.pumpAndSettle();
        await tester.drag(screenList(), const Offset(0, -260));
      },
    );
  });

  testWidgets('switched off, as family see it', (tester) async {
    final rig = rigFor(sam);
    await shoot(
      tester,
      'avatar-create-off-light',
      rig,
      creationsOn: false,
      act: () => tester.drag(screenList(), const Offset(0, -260)),
    );
  });

  testWidgets('the keepsakes shelf, dark at 200% text', (tester) async {
    final rig = rigFor(mia);
    const original = 'households/h1/avatars/m-kid/keepsakes/k1.jpg';
    rig.photos.atPath[original] = drawing;
    await shoot(
      tester,
      'avatar-keepsakes-dark-200-percent-text',
      rig,
      tab: AvatarStudioTab.keepsakes,
      asFamily: false,
      brightness: Brightness.dark,
      textScale: 2,
      act: () async {
        rig.avatars.emitKeepsakes(mia.id, [
          AvatarKeepsake(
            id: 'k1',
            memberId: mia.id,
            recipe: CreationRecipe.drawing,
            style: CreationStyle.clay,
            imageHash: made,
            originalPath: original,
          ),
        ]);
        await tester.pumpAndSettle();
        await tester.drag(screenList(), const Offset(0, -500));
      },
    );
  });
}
