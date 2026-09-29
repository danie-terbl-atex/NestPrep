import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/features/accounts/ui/session_gate_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_auth.dart';
import '../../../support/pump_kit.dart';

/// The very first screen on a cold start, and the only one that can be reached
/// either signed in or out.
///
/// It showed three grey bars and no words for as long as the session read took
/// — which on a bad connection is long enough to look broken. `sessionStarting`
/// had been written for it and never used.
void main() {
  late FakeAuthGateway auth;
  late FakeAccountRepository accounts;
  late SessionController session;

  setUp(() {
    auth = FakeAuthGateway();
    accounts = FakeAccountRepository();
    session = SessionController(authGateway: auth, accountRepository: accounts);
  });

  tearDown(() async {
    session.dispose();
    await auth.close();
    await accounts.close();
  });

  Future<void> pump(WidgetTester tester) => pumpKit(
    tester,
    ChangeNotifierProvider<SessionController>.value(
      value: session,
      child: const SessionGateScreen(),
    ),
  );

  testWidgets('says what it is doing while it works out who you are', (
    tester,
  ) async {
    await pump(tester);
    await tester.pump();

    expect(find.text(AppCopy.sessionStarting), findsOneWidget);
    expect(find.byType(NestBrandMark), findsOneWidget, reason: 'the splash');
    expect(
      find.byType(NestSkeleton),
      findsOneWidget,
      reason: 'the words go with something that moves, not instead of it',
    );
  });

  testWidgets('a failed session read says so, and offers a retry', (
    tester,
  ) async {
    await pump(tester);
    auth.failStreamWith(const UnavailableFailure());
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.retry), findsOneWidget);
    expect(
      find.text(AppCopy.sessionStarting),
      findsNothing,
      reason: 'it is no longer starting; it has stopped',
    );
  });

  testWidgets('and retrying asks again', (tester) async {
    await pump(tester);
    auth.failStreamWith(const UnavailableFailure());
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppCopy.retry));
    await tester.pump();

    expect(find.text(AppCopy.sessionStarting), findsOneWidget);
  });
}
