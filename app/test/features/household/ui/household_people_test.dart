import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/features/household/state/household_controller.dart';
import 'package:nestprep/features/household/ui/household_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_household.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

/// The household screen as the members-and-roles screen (household ADR-0003):
/// people grouped by what they are, what each helper can see said on their
/// row, the way to change it, and — for a helper — what they can use.
void main() {
  late FakeHouseholdRepository repository;
  late FakeHouseholdDirectory directory;
  late HouseholdController controller;

  final cleaningOnly = AccessGrant({HouseholdArea.homeCare: AccessLevel.own});

  setUp(() {
    repository = FakeHouseholdRepository();
    directory = FakeHouseholdDirectory();
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    String viewerUid = Fixtures.samUid,
    Household? household,
    List<Member>? members,
  }) async {
    controller = HouseholdController(
      householdRepository: repository,
      householdDirectory: directory,
      householdId: Fixtures.householdId,
      viewerUid: viewerUid,
    );
    await pumpRouter(
      tester,
      router: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HouseholdScreen(),
          ),
          GoRoute(
            path: '/households/:householdId/household/access/:memberId',
            builder: (context, state) =>
                Text('access for ${state.pathParameters['memberId']}'),
          ),
          GoRoute(
            path: '/households/:householdId/:place',
            builder: (context, state) =>
                Text('opened ${state.pathParameters['place']}'),
          ),
        ],
      ),
      providers: [
        ChangeNotifierProvider<HouseholdController>.value(value: controller),
      ],
    );
    repository.emitHousehold(household ?? Fixtures.household());
    repository.emitMembers(
      members ?? [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
    );
    await tester.pumpAndSettle();
  }

  Household withThandiCleaningOnly() =>
      Fixtures.household().copyWith(access: {Fixtures.thandiUid: cleaningOnly});

  testWidgets('groups people into family and the people who help', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text(AccessCopy.peopleFamily), findsOneWidget);
    await tester.scrollUntilVisible(find.text(AccessCopy.peopleHelpers), 120);
    expect(find.text(AccessCopy.peopleHelpers), findsOneWidget);
  });

  testWidgets('a helper nobody has chosen for yet is flagged on their row', (
    tester,
  ) async {
    await pump(tester);
    await tester.scrollUntilVisible(
      find.textContaining(AccessCopy.accessNotChosen),
      120,
    );
    expect(find.textContaining(AccessCopy.accessNotChosen), findsOneWidget);
  });

  testWidgets('a helper with a grant has it said on their row', (tester) async {
    await pump(tester, household: withThandiCleaningOnly());
    final summary = AccessCopy.accessSummary([HouseholdArea.homeCare]);
    await tester.scrollUntilVisible(find.textContaining(summary), 120);
    expect(find.textContaining(summary), findsOneWidget);
  });

  testWidgets('an admin opens a helper’s access from their row', (
    tester,
  ) async {
    await pump(tester);
    final access = find.bySemanticsLabel(AccessCopy.peopleAccess);
    await tester.scrollUntilVisible(access, 120);
    await tester.tap(access);
    await tester.pumpAndSettle();

    expect(find.text('access for ${Fixtures.thandiMemberId}'), findsOneWidget);
  });

  testWidgets('family rows offer no access to change', (tester) async {
    await pump(tester);
    // Thandi is the only restricted member of the three.
    expect(find.bySemanticsLabel(AccessCopy.peopleAccess), findsOneWidget);
  });

  testWidgets('an admin invites from a card that opens the invite step', (
    tester,
  ) async {
    await pump(tester);
    await tester.scrollUntilVisible(find.text(AccessCopy.peopleInvite), 120);
    await tester.tap(find.text(AccessCopy.peopleInvite));
    await tester.pumpAndSettle();

    expect(find.text('opened setup'), findsOneWidget);
  });

  group('a helper who may only clean', () {
    testWidgets('is told what they can use', (tester) async {
      await pump(
        tester,
        viewerUid: Fixtures.thandiUid,
        household: withThandiCleaningOnly(),
      );

      expect(find.text(AccessCopy.peopleYourAccessTitle), findsOneWidget);
      expect(
        find.text(AccessCopy.areaName(HouseholdArea.homeCare)),
        findsOneWidget,
      );
    });

    testWidgets('is not shown the documents, nor invited to invite', (
      tester,
    ) async {
      await pump(
        tester,
        viewerUid: Fixtures.thandiUid,
        household: withThandiCleaningOnly(),
      );
      await tester.scrollUntilVisible(find.text(AppCopy.locationTitle), 120);

      expect(find.text(AppCopy.documentsOpenLibrary), findsNothing);
      expect(find.text(AccessCopy.peopleInvite), findsNothing);
      expect(find.bySemanticsLabel(AccessCopy.peopleAccess), findsNothing);
    });
  });
}
