import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/kid_routes.dart';
import 'package:nestprep/features/accounts/data/auth_gateway.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/features/kid_accounts/data/kid_sign_in_directory.dart';
import 'package:nestprep/features/kid_accounts/ui/kid_code_screen.dart';
import 'package:provider/provider.dart';

import '../support/fake_auth.dart';
import '../support/fake_kid_sign_in.dart';
import '../support/pump_screen.dart';

/// A code typed on the sign-in screen's code sheet arrives at the kid's screen
/// in the route, and is redeemed there without being typed again (accounts
/// ADR-0009).
void main() {
  late FakeKidSignInDirectory directory;
  late FakeAuthGateway auth;
  late FakeAccountRepository accounts;
  late SessionController session;

  setUp(() {
    directory = FakeKidSignInDirectory();
    auth = FakeAuthGateway();
    accounts = FakeAccountRepository();
    session = SessionController(authGateway: auth, accountRepository: accounts);
  });

  tearDown(() async {
    session.dispose();
    await auth.close();
    await accounts.close();
  });

  Future<void> pumpAt(WidgetTester tester, String location) async {
    await pumpRouter(
      tester,
      router: GoRouter(initialLocation: location, routes: kidRoutes(session)),
      providers: [
        Provider<KidSignInDirectory>.value(value: directory),
        Provider<AuthGateway>.value(value: auth),
      ],
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a code in the route is redeemed as the screen opens', (
    tester,
  ) async {
    await pumpAt(tester, KidCodeScreen.pathWithCode('AB2CD3'));

    expect(directory.redeemed, ['AB2CD3']);
  });

  testWidgets('without one, the screen waits for the child to type', (
    tester,
  ) async {
    await pumpAt(tester, KidCodeScreen.path);

    expect(find.byType(KidCodeScreen), findsOneWidget);
    expect(directory.redeemed, isEmpty);
  });
}
