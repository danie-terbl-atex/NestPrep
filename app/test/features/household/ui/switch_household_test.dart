import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/accounts/model/account.dart';
import 'package:nestprep/features/accounts/model/auth_user.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/features/accounts/ui/account_menu_button.dart';
import 'package:nestprep/features/household/data/household_repository.dart';
import 'package:nestprep/features/household/model/household.dart';
import 'package:nestprep/features/product_analytics/data/beta_numbers_repository.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_auth.dart';
import '../../../support/fake_household.dart';
import '../../../support/fake_product_analytics.dart';
import '../../../support/household_fixtures.dart';

/// Moving between the households an account belongs to.
///
/// `SessionController.switchHousehold` and the account's `householdIds` have
/// been there since the beginning; nothing called it, so an account in two
/// households could only ever see one of them.
void main() {
  const otherHouseholdId = 'h2';

  late FakeAuthGateway auth;
  late FakeAccountRepository accounts;
  late FakeHouseholdRepository households;
  late SessionController session;

  setUp(() {
    auth = FakeAuthGateway();
    accounts = FakeAccountRepository();
    households = FakeHouseholdRepository();
    session = SessionController(authGateway: auth, accountRepository: accounts);
    households.storedHouseholds[Fixtures.householdId] = Fixtures.household();
    households.storedHouseholds[otherHouseholdId] = const Household(
      id: otherHouseholdId,
      name: 'The Dlaminis',
      timeZone: 'Africa/Johannesburg',
      members: {Fixtures.samUid: 'member'},
      createdBy: Fixtures.samUid,
    );
  });

  tearDown(() async {
    session.dispose();
    await auth.close();
    await accounts.close();
    await households.close();
  });

  /// The providers go *above* `MaterialApp`, as they do in the real app. A
  /// sheet is a route on the root navigator, so anything provided inside the
  /// app's own subtree is invisible to it — which is a property of the widget
  /// tree, not of this feature.
  Future<void> pump(WidgetTester tester) {
    final nest = NestTheme.light();
    return tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<HouseholdRepository>.value(value: households),
          // The account sheet asks whether to offer the Beta numbers.
          Provider<BetaNumbersRepository>.value(
            value: FakeBetaNumbersRepository(),
          ),
          ChangeNotifierProvider<SessionController>.value(value: session),
        ],
        child: MaterialApp(
          theme: nestThemeData(nest),
          home: const Scaffold(body: Center(child: AccountMenuButton())),
        ),
      ),
    );
  }

  Future<void> signIn(WidgetTester tester, List<String> belongsTo) async {
    auth.emit(const AuthUser(uid: Fixtures.samUid, email: 'sam@nestprep.test'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
    accounts.emit(
      Account(
        id: Fixtures.samUid,
        displayName: 'Sam Parent',
        householdIds: belongsTo,
        activeHouseholdId: belongsTo.first,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel(AppCopy.account));
    await tester.pumpAndSettle();
  }

  testWidgets('one household is not a choice, so nothing is offered', (
    tester,
  ) async {
    await pump(tester);
    await signIn(tester, const [Fixtures.householdId]);
    await openMenu(tester);

    expect(find.text(AppCopy.householdSwitch), findsNothing);
  });

  testWidgets('two households are, and both are named', (tester) async {
    await pump(tester);
    await signIn(tester, const [Fixtures.householdId, otherHouseholdId]);
    await openMenu(tester);

    expect(find.text(AppCopy.householdSwitch), findsOneWidget);
    await tester.tap(find.widgetWithText(NestButton, AppCopy.householdSwitch));
    await tester.pumpAndSettle();

    expect(find.text('The Parkers'), findsOneWidget);
    expect(find.text('The Dlaminis'), findsOneWidget);
  });

  testWidgets('choosing the other one switches to it', (tester) async {
    await pump(tester);
    await signIn(tester, const [Fixtures.householdId, otherHouseholdId]);
    await openMenu(tester);
    await tester.tap(find.widgetWithText(NestButton, AppCopy.householdSwitch));
    await tester.pumpAndSettle();

    await tester.tap(find.text('The Dlaminis'));
    await tester.pumpAndSettle();

    expect(accounts.activeHouseholds, [otherHouseholdId]);
  });

  testWidgets('the one already open is shown, and cannot be chosen again', (
    tester,
  ) async {
    await pump(tester);
    await signIn(tester, const [Fixtures.householdId, otherHouseholdId]);
    await openMenu(tester);
    await tester.tap(find.widgetWithText(NestButton, AppCopy.householdSwitch));
    await tester.pumpAndSettle();

    await tester.tap(find.text('The Parkers'));
    await tester.pumpAndSettle();

    expect(
      accounts.activeHouseholds,
      isEmpty,
      reason: 'switching to where you already are is a write for nothing',
    );
  });
}
