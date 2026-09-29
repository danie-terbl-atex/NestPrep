import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/family_route.dart';
import 'package:nestprep/features/family_profiles/model/family_profile.dart';
import 'package:nestprep/features/family_profiles/state/family_controller.dart';
import 'package:nestprep/features/family_profiles/ui/family_screen.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_family_profiles.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

void main() {
  late FakeFamilyProfileRepository repository;
  late FamilyController controller;

  void build(HouseholdView view) {
    controller = FamilyController(
      familyProfileRepository: repository,
      childProfileDirectory: repository,
      householdId: Fixtures.householdId,
      household: view,
    );
  }

  setUp(() {
    repository = FakeFamilyProfileRepository();
    build(Fixtures.view());
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  /// The family screen with a profile route under it, so a tap on a card has
  /// somewhere to land.
  Future<void> pump(
    WidgetTester tester, {
    HouseholdView? view,
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) => pumpRouter(
    tester,
    router: GoRouter(
      initialLocation: FamilyRoute.pathFor(Fixtures.householdId),
      routes: [
        GoRoute(
          path: FamilyRoute.path,
          builder: (context, state) => const FamilyScreen(),
        ),
        GoRoute(
          path: FamilyRoute.memberPath,
          builder: (context, state) =>
              Text('profile of ${FamilyRoute.memberIdFrom(state)}'),
        ),
      ],
    ),
    providers: [
      ChangeNotifierProvider<FamilyController>.value(value: controller),
    ],
    view: view,
    brightness: brightness,
    textScale: scale,
  );

  Future<void> loaded(
    WidgetTester tester, {
    List<FamilyProfile>? profiles,
  }) async {
    repository.emitProfiles(profiles ?? [FamilyFixtures.kid]);
    repository.emitSchools([FamilyFixtures.oakwood]);
    await tester.pumpAndSettle();
  }

  testWidgets('holds the layout while it loads', (tester) async {
    await pump(tester);
    await tester.pump();
    expect(find.text(FamilyCopy.title), findsOneWidget);
    expect(find.text(FamilyCopy.children), findsNothing);
  });

  testWidgets('children first, with their allergies before anything else', (
    tester,
  ) async {
    await pump(tester);
    await loaded(tester);

    expect(find.text(FamilyCopy.children), findsOneWidget);
    expect(find.text(FamilyCopy.everyoneElse), findsOneWidget);
    expect(find.text('Kid Parker'), findsOneWidget);
    expect(find.text('Oakwood Primary · Grade 3'), findsOneWidget);
    expect(find.text('Peanuts'), findsOneWidget);
    expect(find.text('Kiwi'), findsOneWidget);
    // The school's rule reaches the child's card.
    expect(find.text(FamilyCopy.nutFree), findsWidgets);
    expect(find.text('Sam Parent'), findsOneWidget);
    expect(find.text('Thandi Helper'), findsOneWidget);
  });

  testWidgets('with no child marked yet, says how to mark one', (tester) async {
    await pump(tester);
    await loaded(tester, profiles: const []);
    expect(find.text(FamilyCopy.noChildrenYet), findsOneWidget);
    expect(find.text(FamilyCopy.nothingRecorded), findsNWidgets(3));
  });

  testWidgets('says what went wrong in words, with a retry', (tester) async {
    await pump(tester);
    repository.failProfilesWith(const UnavailableFailure());
    await tester.pumpAndSettle();
    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
    await tester.tap(find.text(AppCopy.retry));
    // `onRetry` hands back a Future nobody awaits, and it cancels two
    // subscriptions before making two more — only real async can see that
    // (the household screen test found the same).
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await loaded(tester);
    expect(find.text('Kid Parker'), findsOneWidget);
  });

  testWidgets('a card opens that person"s profile', (tester) async {
    await pump(tester);
    await loaded(tester);
    await tester.tap(find.text('Kid Parker'));
    await tester.pumpAndSettle();
    expect(find.text('profile of ${Fixtures.kidMemberId}'), findsOneWidget);
  });

  group('schools', () {
    testWidgets('an admin adds one and marks it nut-free', (tester) async {
      await pump(tester);
      await loaded(tester);

      await tester.scrollUntilVisible(
        find.bySemanticsLabel(FamilyCopy.addSchool),
        200,
      );
      await tester.tap(find.bySemanticsLabel(FamilyCopy.addSchool));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'Greenfields');
      await tester.tap(find.text(FamilyCopy.schoolNutFree));
      await tester.pump();
      await tester.tap(find.text(FamilyCopy.save));
      await tester.pumpAndSettle();

      expect(repository.writes.single, isA<(String, Map<String, Object?>)>());
      final (method, arguments) = repository.writes.single;
      expect(method, 'addSchool');
      expect(arguments, {'name': 'Greenfields', 'nutFree': true});
    });

    testWidgets('deleting one asks first, and says who it leaves without', (
      tester,
    ) async {
      await pump(tester);
      await loaded(tester);

      await tester.scrollUntilVisible(find.text('Oakwood Primary').last, 200);
      await tester.tap(find.text('Oakwood Primary').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(FamilyCopy.deleteSchool));
      await tester.pumpAndSettle();
      expect(find.text(FamilyCopy.deleteSchoolBody(1)), findsOneWidget);
      await tester.tap(find.text(FamilyCopy.deleteSchool).last);
      await tester.pumpAndSettle();

      expect(repository.writes.single.$1, 'deleteSchool');
    });

    testWidgets('an admin renames a school and lifts its rule', (tester) async {
      await pump(tester);
      await loaded(tester);

      await tester.scrollUntilVisible(find.text('Oakwood Primary').last, 200);
      await tester.tap(find.text('Oakwood Primary').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'Oakwood Prep');
      await tester.tap(find.text(FamilyCopy.schoolNutFree));
      await tester.pump();
      await tester.tap(find.text(FamilyCopy.save));
      await tester.pumpAndSettle();

      final (method, arguments) = repository.writes.single;
      expect(method, 'updateSchool');
      expect(arguments, {
        'schoolId': 'oakwood',
        'name': 'Oakwood Prep',
        'nutFree': false,
      });
    });

    testWidgets('a refused change is said in words, and can be put away', (
      tester,
    ) async {
      await pump(tester);
      await loaded(tester);
      repository.failWritesWith = const PermissionDeniedFailure();

      await tester.scrollUntilVisible(
        find.bySemanticsLabel(FamilyCopy.addSchool),
        200,
      );
      await tester.tap(find.bySemanticsLabel(FamilyCopy.addSchool));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'Greenfields');
      await tester.pump();
      await tester.tap(find.text(FamilyCopy.save));
      await tester.pumpAndSettle();

      final refusal = AppCopy.failure(const PermissionDeniedFailure());
      expect(find.text(refusal), findsOneWidget);
      await tester.tap(find.text(AppCopy.back));
      await tester.pumpAndSettle();
      expect(find.text(refusal), findsNothing);
    });

    testWidgets('a helper sees the schools but cannot change them', (
      tester,
    ) async {
      controller.dispose();
      final helperView = Fixtures.view(viewerUid: Fixtures.thandiUid);
      build(helperView);
      await pump(tester, view: helperView);
      await loaded(tester);

      await tester.scrollUntilVisible(find.text(FamilyCopy.schoolsTitle), 200);
      expect(find.bySemanticsLabel(FamilyCopy.addSchool), findsNothing);
      await tester.tap(find.text('Oakwood Primary').last);
      await tester.pumpAndSettle();
      expect(find.text(FamilyCopy.editSchool), findsNothing);
    });
  });

  testWidgets('renders in dark and at 200% text without overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(tester, brightness: Brightness.dark, scale: 2);
    await loaded(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Kid Parker'), findsOneWidget);
  });
}
