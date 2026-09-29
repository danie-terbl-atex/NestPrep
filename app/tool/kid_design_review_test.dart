import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/chore_points/model/point_claim.dart';
import 'package:nestprep/features/chore_points/model/reward.dart';
import 'package:nestprep/features/chore_points/state/kid_points_controller.dart';
import 'package:nestprep/features/kid_accounts/model/kid_device.dart';
import 'package:nestprep/features/kid_accounts/state/kid_code_controller.dart';
import 'package:nestprep/features/kid_accounts/state/kid_home_controller.dart';
import 'package:nestprep/features/kid_accounts/state/kid_sign_in_controller.dart';
import 'package:nestprep/features/kid_accounts/ui/kid_code_screen.dart';
import 'package:nestprep/features/kid_accounts/ui/kid_home_screen.dart';
import 'package:nestprep/features/kid_accounts/ui/kid_sign_in_screen.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/meal_planning/model/week_plan.dart';
import 'package:nestprep/shared/copy/kid_copy.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/fake_auth.dart';
import '../test/support/fake_chore_points.dart';
import '../test/support/fake_kid_sign_in.dart';
import '../test/support/household_fixtures.dart';
import '../test/support/kid_home_fixture.dart';
import 'review_press.dart';

/// Not a test — the kids' half of the screenshot press (accounts ADR-0003):
/// the child's way in, the child's home, and the parent's screen with a code
/// on it, in light and dark. Regenerate with
///
///     flutter test tool/kid_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  Future<void> kidCode(WidgetTester tester, Brightness brightness) async {
    final auth = FakeAuthGateway();
    addTearDown(auth.close);
    final controller = KidCodeController(
      kidSignInDirectory: FakeKidSignInDirectory(),
      authGateway: auth,
    );
    addTearDown(controller.dispose);
    await captureScreen(
      tester,
      'kid-code-${brightness.name}',
      screen: const KidCodeScreen(),
      providers: [
        ChangeNotifierProvider<KidCodeController>.value(value: controller),
      ],
      brightness: brightness,
      emit: () async => controller.setCode('K7M'),
    );
  }

  Future<void> kidHome(WidgetTester tester, Brightness brightness) async {
    // Made outside the test's fake clock, so its listeners hear what the
    // `runAsync` below emits — the stars open a moment after the day does.
    final fixture = (await tester.runAsync(() async => KidHomeFixture()))!;
    addTearDown(fixture.close);
    await captureScreen(
      tester,
      'kid-home-${brightness.name}',
      screen: const KidHomeScreen(),
      providers: [
        ChangeNotifierProvider<KidHomeController>.value(
          value: fixture.controller,
        ),
        ChangeNotifierProvider<KidPointsController>.value(value: fixture.stars),
      ],
      brightness: brightness,
      emit: () => tester.runAsync(() async {
        await fixture.arrive(
          tasks: [
            KidHomeFixture.chore('bed', 'Make your bed', points: 2),
            KidHomeFixture.chore('cat', 'Feed Biscuit the cat', points: 3),
            KidHomeFixture.chore(
              'room',
              'Tidy your room',
              points: 10,
              needsApproval: true,
            ),
            KidHomeFixture.chore('bag', 'Pack your school bag'),
          ],
          completions: [
            KidHomeFixture.done('bed'),
            KidHomeFixture.done('room'),
          ],
          slots: {
            WeekPlan.slotKey(KidHomeFixture.today.weekday, MealSlot.lunch):
                'pasta',
          },
          // Their own box today (lunch-box ADR-0004).
          lunchSlots: const {
            '2_main': LunchPick(itemId: 'wrap', name: 'Chicken mayo wrap'),
            '2_fruit': LunchPick(itemId: 'naartjie', name: 'Naartjie'),
            '2_veg': LunchPick(itemId: 'carrots', name: 'Carrot sticks'),
            '2_treat': LunchPick(itemId: 'rusk', name: 'Rusk'),
          },
        );
        // Stars and treats (todos ADR-0003).
        await fixture.starsArrive(
          claims: [
            PointsFixtures.claim(
              'bed',
              KidHomeFixture.today,
              memberId: Fixtures.kidMemberId,
              status: ClaimStatus.awarded,
              points: 2,
            ),
            PointsFixtures.claim(
              'room',
              KidHomeFixture.today,
              memberId: Fixtures.kidMemberId,
              points: 10,
            ),
          ],
          rewards: [
            PointsFixtures.reward('ice-cream', 'Ice cream', 15),
            PointsFixtures.reward(
              'movie',
              'Movie night',
              40,
              icon: RewardIcon.movie,
            ),
          ],
        );
        fixture.points.emitBalance(
          PointsFixtures.balance(
            Fixtures.kidMemberId,
            18,
            streak: 4,
            lastDay: KidHomeFixture.today,
          ),
        );
        await pumpEventQueue();
      }),
    );
  }

  Future<void> kidsSignIn(
    WidgetTester tester,
    Brightness brightness, {
    bool withCode = false,
  }) async {
    final devices = FakeKidDeviceRepository();
    addTearDown(devices.close);
    final controller = KidSignInController(
      kidSignInDirectory: FakeKidSignInDirectory(),
      kidDeviceRepository: devices,
      householdId: Fixtures.householdId,
      members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
    );
    addTearDown(controller.dispose);
    await captureScreen(
      tester,
      withCode
          ? 'kids-pairing-${brightness.name}'
          : 'kids-sign-in-${brightness.name}',
      screen: const KidSignInScreen(),
      providers: [
        ChangeNotifierProvider<KidSignInController>.value(value: controller),
      ],
      brightness: brightness,
      emit: () async {
        devices.emit([
          KidDevice(
            id: 'kid_tablet',
            memberId: Fixtures.kidMemberId,
            label: 'Kitchen tablet',
            pairedBy: Fixtures.samUid,
            pairedAt: KidHomeFixture.nowUtc,
          ),
        ]);
        await tester.pumpAndSettle();
        if (!withCode) return;
        await tester.tap(find.text(KidCopy.manageAddDevice));
        await tester.pumpAndSettle();
        await tester.tap(find.text(KidCopy.pairMakeCode));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
      },
    );
    await controller.closePairing();
  }

  for (final brightness in Brightness.values) {
    testWidgets('a kid’s way in — ${brightness.name}', (tester) async {
      await kidCode(tester, brightness);
    });

    testWidgets('a kid’s home — ${brightness.name}', (tester) async {
      await kidHome(tester, brightness);
    });

    testWidgets('kids’ sign-in — ${brightness.name}', (tester) async {
      await kidsSignIn(tester, brightness);
    });

    testWidgets('a code for a new device — ${brightness.name}', (tester) async {
      await kidsSignIn(tester, brightness, withCode: true);
    });
  }
}
