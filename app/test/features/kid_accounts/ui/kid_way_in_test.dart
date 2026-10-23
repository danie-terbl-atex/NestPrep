import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/kid_routes.dart';
import 'package:nestprep/features/accounts/ui/code_way_in_sheet.dart';
import 'package:nestprep/features/accounts/ui/sign_in_screen.dart';
import 'package:nestprep/features/household/state/pending_invite.dart';
import 'package:nestprep/features/kid_accounts/ui/kid_code_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:provider/provider.dart';

import '../../../support/pump_screen.dart';

/// The kid's way in is on the sign-in screen, in the one code button it shares
/// with a family invite — a child who cannot find it cannot sign in at all
/// (accounts ADR-0003, ADR-0009, and the lesson on capabilities finished
/// everywhere except the screen). The code's length says which it is.
void main() {
  late StreamController<Uri> links;
  late PendingInvite pending;
  Uri? kidRoute;

  setUp(() {
    links = StreamController<Uri>();
    pending = PendingInvite(links: links.stream);
    kidRoute = null;
  });

  tearDown(() async {
    pending.dispose();
    await links.close();
  });

  Future<void> pump(WidgetTester tester) async {
    await pumpRouter(
      tester,
      router: GoRouter(
        routes: [
          GoRoute(path: '/', builder: (context, state) => const SignInScreen()),
          GoRoute(
            path: KidRoute.codePath,
            builder: (context, state) {
              kidRoute = state.uri;
              return const Placeholder();
            },
          ),
        ],
      ),
      providers: [ChangeNotifierProvider<PendingInvite>.value(value: pending)],
    );
    await tester.pumpAndSettle();
  }

  Future<void> typeCode(WidgetTester tester, String code) async {
    final wayIn = find.text(AppCopy.codeWayIn);
    await tester.ensureVisible(wayIn);
    await tester.pumpAndSettle();
    expect(find.text(AppCopy.codeWayInPrompt), findsOneWidget);
    await tester.tap(wayIn);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(CodeWayInSheet),
        matching: find.byType(TextField),
      ),
      code,
    );
    await tester.pump();
    await tester.tap(find.text(AppCopy.codeWayInContinue));
    await tester.pumpAndSettle();
  }

  testWidgets('six letters take a child to their screen with the code', (
    tester,
  ) async {
    await pump(tester);

    await typeCode(tester, 'ab2cd3');

    expect(find.byType(Placeholder), findsOneWidget);
    expect(kidRoute?.queryParameters[KidCodeScreen.codeParameter], 'AB2CD3');
    expect(pending.code, isNull);
  });

  testWidgets('eight letters are held as a family invite', (tester) async {
    await pump(tester);

    await typeCode(tester, 'abcd2345');

    expect(pending.code, 'ABCD2345');
    expect(find.byType(CodeWayInSheet), findsNothing);
    expect(kidRoute, isNull);
  });

  testWidgets('a code with letters no code uses is refused in words', (
    tester,
  ) async {
    await pump(tester);

    await typeCode(tester, 'OI0L1A');

    expect(find.text(AppCopy.codeWayInInvalid), findsOneWidget);
    expect(kidRoute, isNull);
    expect(pending.code, isNull);
  });

  testWidgets('the continue button waits for a whole code', (tester) async {
    await pump(tester);

    await typeCode(tester, 'ABC23');

    expect(find.byType(CodeWayInSheet), findsOneWidget);
    expect(kidRoute, isNull);
  });
}
