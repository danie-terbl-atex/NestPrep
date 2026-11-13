import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/avatar_routes.dart';
import 'package:nestprep/app/kid_routes.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/avatars/data/avatar_seen_stage_store.dart';
import 'package:nestprep/features/avatars/model/avatar_base.dart';
import 'package:nestprep/features/avatars/model/member_look.dart';
import 'package:nestprep/features/chore_points/state/kid_points_controller.dart';
import 'package:nestprep/features/kid_accounts/state/kid_home_controller.dart';
import 'package:nestprep/features/kid_accounts/ui/kid_home_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/flags/feature_flags_controller.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_avatars.dart';
import '../../../support/fake_feature_flag_source.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/kid_home_fixture.dart';
import '../../../support/pump_screen.dart';

void main() {
  setUpAll(tz_data.initializeTimeZones);

  late KidHomeFixture fixture;
  late FakeAvatarSeenStageStore seen;

  setUp(() {
    fixture = KidHomeFixture();
    seen = FakeAvatarSeenStageStore();
  });
  tearDown(() => fixture.close());

  Future<void> pump(WidgetTester tester, {bool avatarsOn = true}) => pumpRouter(
    tester,
    router: GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const KidHomeScreen()),
        GoRoute(
          path: AvatarRoute.kidPath,
          builder: (context, state) =>
              Text('studio ${state.uri.queryParameters['tab'] ?? ''}'),
        ),
      ],
    ),
    providers: [
      ChangeNotifierProvider<KidHomeController>.value(
        value: fixture.controller,
      ),
      ChangeNotifierProvider<KidPointsController>.value(value: fixture.stars),
      Provider<AvatarSeenStageStore>.value(value: seen),
      if (!avatarsOn)
        ChangeNotifierProvider<FeatureFlagsController>(
          create: (_) => FeatureFlagsController(
            source: FakeFeatureFlagSource(),
            defaultOn: false,
          ),
        ),
    ],
  );

  Future<void> arrive(
    WidgetTester tester, {
    MemberLook? look,
    bool settle = true,
  }) async {
    await tester.runAsync(() async {
      await fixture.arrive();
      if (look != null) {
        fixture.households.emitMember(Fixtures.kid.copyWith(look: look));
        await pumpEventQueue();
      }
      await fixture.starsArrive(stars: 6);
    });
    await tester.pump();
    await tester.pump();
    if (settle) await tester.pumpAndSettle();
  }

  test('a kid device may open its own picture, and nothing else new', () {
    expect(redirectForKid(AvatarRoute.kidPath), isNull);
    expect(redirectForKid('/kid/avatar/other'), KidHomeScreen.path);
    expect(
      redirectForKid('/households/h1/household/avatar/m-kid'),
      KidHomeScreen.path,
    );
  });

  testWidgets('the hero picture has a sparkle to tap, and opens the studio', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    await arrive(tester);
    final pip = find.bySemanticsLabel(AvatarCopy.changePicture);
    expect(find.byType(NestEditablePicture), findsOneWidget);
    expect(pip, findsOneWidget);
    await tester.tap(find.byType(NestEditablePicture));
    await tester.pumpAndSettle();
    expect(find.text('studio '), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the wardrobe shelf opens straight onto the wardrobe', (
    tester,
  ) async {
    await pump(tester);
    await arrive(tester);
    await tester.scrollUntilVisible(
      find.text(AvatarCopy.kidShelfAction),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text(AvatarCopy.kidShelfAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AvatarCopy.kidShelfAction));
    await tester.pumpAndSettle();
    expect(find.text('studio wardrobe'), findsOneWidget);
  });

  testWidgets('with avatars switched off the kid home is as it was', (
    tester,
  ) async {
    await pump(tester, avatarsOn: false);
    await arrive(tester);
    expect(find.byType(NestEditablePicture), findsNothing);
    expect(find.text(AvatarCopy.kidShelfTitle), findsNothing);
  });

  testWidgets('an egg that hatched while nobody was looking is celebrated '
      'once', (tester) async {
    await pump(tester);
    await arrive(
      tester,
      look: const MemberLook(base: PresetBase('pip'), stage: 1),
      settle: false,
    );
    await tester.runAsync(pumpEventQueue);
    await tester.pump();
    expect(find.text(AvatarCopy.hatchedTitle), findsOneWidget);
    expect(seen.stages[Fixtures.kidMemberId], 1);
    await tester.pumpAndSettle();
    expect(find.text(AvatarCopy.hatchedTitle), findsNothing);
  });

  testWidgets('a stage already seen is not celebrated again', (tester) async {
    seen.stages[Fixtures.kidMemberId] = 2;
    await pump(tester);
    await arrive(
      tester,
      look: const MemberLook(base: PresetBase('pip'), stage: 2),
    );
    await tester.runAsync(pumpEventQueue);
    await tester.pump();
    expect(find.text(AvatarCopy.grewTitle), findsNothing);
    expect(find.text(AvatarCopy.hatchedTitle), findsNothing);
  });

  testWidgets('growing from hatchling to fledgling says wings', (tester) async {
    seen.stages[Fixtures.kidMemberId] = 1;
    await pump(tester);
    await arrive(
      tester,
      look: const MemberLook(base: PresetBase('pip'), stage: 2),
      settle: false,
    );
    await tester.runAsync(pumpEventQueue);
    await tester.pump();
    expect(find.text(AvatarCopy.grewTitle), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
