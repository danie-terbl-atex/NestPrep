import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/avatars/data/avatar_photo_picker.dart';
import 'package:nestprep/features/avatars/data/avatar_photo_store.dart';
import 'package:nestprep/features/avatars/data/avatar_seen_stage_store.dart';
import 'package:nestprep/features/avatars/model/avatar_base.dart';
import 'package:nestprep/features/avatars/model/avatar_catalogue.g.dart';
import 'package:nestprep/features/avatars/model/avatar_choice.dart';
import 'package:nestprep/features/avatars/model/avatar_place.dart';
import 'package:nestprep/features/avatars/model/member_avatar_record.dart';
import 'package:nestprep/features/avatars/model/member_look.dart';
import 'package:nestprep/features/avatars/state/avatar_studio_controller.dart';
import 'package:nestprep/features/avatars/ui/avatar_studio_screen.dart';
import 'package:nestprep/features/avatars/ui/avatar_studio_tab.dart';
import 'package:nestprep/features/chore_points/model/point_balance.dart';
import 'package:nestprep/features/chore_points/state/kid_points_controller.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/features/kid_accounts/state/kid_home_controller.dart';
import 'package:nestprep/features/kid_accounts/ui/kid_home_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/fake_avatars.dart';
import '../test/support/fake_chore_points.dart';
import '../test/support/fake_household.dart';
import '../test/support/household_fixtures.dart';
import '../test/support/kid_home_fixture.dart';
import 'review_press.dart';

void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  final place = AvatarPlace(
    householdId: Fixtures.householdId,
    today: CalendarDate(2026, 11, 12),
    hemisphere: AvatarHemisphere.south,
  );

  Future<void> studio(
    WidgetTester tester,
    String name, {
    required Member member,
    required String viewerMemberId,
    required AvatarStudioTab tab,
    MemberAvatarRecord record = MemberAvatarRecord.none,
    PointBalance? balance,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    final households = FakeHouseholdRepository();
    final avatars = FakeAvatarRepository(record);
    final points = FakePointsRepository();
    final controller = AvatarStudioController(
      householdRepository: households,
      avatarRepository: avatars,
      pointsRepository: points,
      photoStore: FakeAvatarPhotoStore(),
      householdId: Fixtures.householdId,
      memberId: member.id,
      viewerMemberId: viewerMemberId,
      viewerUid: Fixtures.samUid,
    );
    addTearDown(() async {
      controller.dispose();
      await households.close();
      await avatars.close();
    });
    await captureScreen(
      tester,
      name,
      screen: AvatarStudioScreen(initialTab: tab),
      providers: [
        ChangeNotifierProvider<AvatarStudioController>.value(value: controller),
        Provider<AvatarPhotoPicker>.value(value: FakeAvatarPhotoPicker()),
        Provider<AvatarPhotoStore>.value(value: FakeAvatarPhotoStore()),
        Provider<AvatarPlace?>.value(value: place),
      ],
      brightness: brightness,
      textScale: textScale,
      emit: () async {
        households
          ..emitMember(member)
          ..emitHousehold(Fixtures.household());
        await tester.pump();
        if (balance != null) points.emitBalance(balance);
        await tester.pump();
      },
    );
  }

  final mia = Fixtures.kid.copyWith(
    displayName: 'Mia',
    look: const MemberLook(
      base: PresetBase('pip'),
      stage: 1,
      wear: {AvatarSlot.top: 'acc-party-hat'},
    ),
  );
  const miaRecord = MemberAvatarRecord(
    choice: AvatarChoice(
      base: PresetBase('pip'),
      wear: {AvatarSlot.top: 'acc-party-hat'},
    ),
    ownedAccessories: {'acc-heart'},
  );
  const miaStars = PointBalance(
    id: Fixtures.kidMemberId,
    balance: 22,
    earned: 30,
    bestStreak: 2,
  );
  final sam = Fixtures.sam.copyWith(
    look: const MemberLook(
      base: PresetBase('olive'),
      stage: 3,
      wear: {
        AvatarSlot.badge: 'acc-book',
        AvatarSlot.face: 'acc-round-glasses',
      },
    ),
  );
  const samRecord = MemberAvatarRecord(
    choice: AvatarChoice(
      base: PresetBase('olive'),
      stage: 3,
      wear: {
        AvatarSlot.badge: 'acc-book',
        AvatarSlot.face: 'acc-round-glasses',
      },
    ),
  );

  for (final brightness in Brightness.values) {
    testWidgets('a child\'s Nestlings, ${brightness.name}', (tester) async {
      await studio(
        tester,
        'avatar-studio-kid-nestlings-${brightness.name}',
        member: mia,
        viewerMemberId: Fixtures.kidMemberId,
        tab: AvatarStudioTab.nestlings,
        record: miaRecord,
        balance: miaStars,
        brightness: brightness,
      );
    });

    testWidgets('a child\'s wardrobe and star shop, ${brightness.name}', (
      tester,
    ) async {
      await studio(
        tester,
        'avatar-studio-kid-wardrobe-${brightness.name}',
        member: mia,
        viewerMemberId: Fixtures.kidMemberId,
        tab: AvatarStudioTab.wardrobe,
        record: miaRecord,
        balance: miaStars,
        brightness: brightness,
      );
    });

    testWidgets('a grown-up\'s Nestlings, ${brightness.name}', (tester) async {
      await studio(
        tester,
        'avatar-studio-nestlings-${brightness.name}',
        member: sam,
        viewerMemberId: Fixtures.samMemberId,
        tab: AvatarStudioTab.nestlings,
        record: samRecord,
        brightness: brightness,
      );
    });

    testWidgets('the photo tab, ${brightness.name}', (tester) async {
      await studio(
        tester,
        'avatar-studio-photo-${brightness.name}',
        member: sam,
        viewerMemberId: Fixtures.samMemberId,
        tab: AvatarStudioTab.photo,
        record: samRecord,
        brightness: brightness,
      );
    });
  }

  testWidgets('a child with no stars yet, an egg', (tester) async {
    await studio(
      tester,
      'avatar-studio-kid-egg-light',
      member: mia.copyWith(look: const MemberLook(base: PresetBase('pip'))),
      viewerMemberId: Fixtures.kidMemberId,
      tab: AvatarStudioTab.nestlings,
      record: const MemberAvatarRecord(
        choice: AvatarChoice(base: PresetBase('pip')),
      ),
      balance: const PointBalance(id: Fixtures.kidMemberId),
    );
  });

  testWidgets('a child\'s wardrobe, dark at 200% text', (tester) async {
    await studio(
      tester,
      'avatar-studio-kid-wardrobe-dark-200-percent-text',
      member: mia,
      viewerMemberId: Fixtures.kidMemberId,
      tab: AvatarStudioTab.wardrobe,
      record: miaRecord,
      balance: miaStars,
      brightness: Brightness.dark,
      textScale: 2,
    );
  });

  for (final (name, scrolled) in [
    ('kid-home-nestling-light', false),
    ('kid-home-wardrobe-shelf-light', true),
  ]) {
    testWidgets('the kid home with a Nestling, $name', (tester) async {
      final fixture = (await tester.runAsync(() async => KidHomeFixture()))!;
      addTearDown(fixture.close);
      await captureScreen(
        tester,
        name,
        screen: const KidHomeScreen(),
        providers: [
          ChangeNotifierProvider<KidHomeController>.value(
            value: fixture.controller,
          ),
          ChangeNotifierProvider<KidPointsController>.value(
            value: fixture.stars,
          ),
          Provider<AvatarSeenStageStore>.value(
            value: FakeAvatarSeenStageStore({Fixtures.kidMemberId: 2}),
          ),
          Provider<AvatarPlace?>.value(value: place),
        ],
        emit: () => tester.runAsync(() async {
          await fixture.arrive(
            tasks: [
              KidHomeFixture.chore('bed', 'Make your bed', points: 2),
              KidHomeFixture.chore('cat', 'Feed Biscuit the cat', points: 3),
            ],
            completions: [KidHomeFixture.done('bed')],
          );
          fixture.households.emitMember(
            Fixtures.kid.copyWith(
              look: const MemberLook(
                base: PresetBase('pip'),
                stage: 2,
                wear: {
                  AvatarSlot.top: 'acc-crown',
                  AvatarSlot.badge: 'acc-football',
                },
              ),
            ),
          );
          await fixture.starsArrive(stars: 14);
        }),
        act: scrolled
            ? () async {
                await tester.scrollUntilVisible(
                  find.text(AvatarCopy.kidShelfAction),
                  300,
                  scrollable: screenList(),
                );
              }
            : null,
      );
    });
  }
}
