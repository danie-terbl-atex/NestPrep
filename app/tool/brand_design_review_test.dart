import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/features/accounts/ui/session_gate_screen.dart';
import 'package:nestprep/features/groceries/state/grocery_list_controller.dart';
import 'package:nestprep/features/groceries/ui/grocery_list_screen.dart';
import 'package:provider/provider.dart';

import '../test/support/fake_auth.dart';
import '../test/support/fake_grocery_repository.dart';
import '../test/support/household_fixtures.dart';
import 'review_press.dart';

/// Not a test — the brand's own screenshot press (design-system ADR-0003).
/// The places the nest appears that the other presses do not reach: the
/// launch screen the native splash hands over to, and a first-run empty state.
///
///     flutter test tool/brand_design_review_test.dart --update-goldens
void main() {
  setUpAll(loadEveryFont);

  /// The launch screen while the session is still being read. Its skeleton
  /// pulses until the read lands, which a settling press would wait on for
  /// ever, so the picture is taken as a reduce-motion phone would show it.
  Future<void> launch(WidgetTester tester, Brightness brightness) async {
    final auth = FakeAuthGateway();
    final accounts = FakeAccountRepository();
    final session = SessionController(
      authGateway: auth,
      accountRepository: accounts,
    );
    addTearDown(() async {
      session.dispose();
      await auth.close();
      await accounts.close();
    });
    await captureScreen(
      tester,
      'launch-${brightness.name}',
      screen: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: const SessionGateScreen(),
        ),
      ),
      providers: [
        ChangeNotifierProvider<SessionController>.value(value: session),
      ],
      brightness: brightness,
      emit: () async {},
    );
  }

  /// A new household's grocery list, before anybody has added a thing.
  Future<void> emptyList(WidgetTester tester, Brightness brightness) async {
    final repository = FakeGroceryRepository();
    addTearDown(repository.close);
    final controller = GroceryListController(
      groceryRepository: repository,
      householdId: Fixtures.householdId,
      memberId: Fixtures.samMemberId,
    );
    addTearDown(controller.dispose);
    await captureScreen(
      tester,
      'groceries-empty-${brightness.name}',
      screen: GroceryListScreen(onSelectTab: (_) {}),
      providers: [
        ChangeNotifierProvider<GroceryListController>.value(value: controller),
      ],
      brightness: brightness,
      emit: () async => repository.emitItems(const []),
    );
  }

  for (final brightness in Brightness.values) {
    testWidgets('the launch screen — ${brightness.name}', (tester) async {
      await launch(tester, brightness);
    });
    testWidgets('a first-run empty list — ${brightness.name}', (tester) async {
      await emptyList(tester, brightness);
    });
  }
}
