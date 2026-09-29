import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/kid_routes.dart';
import 'package:nestprep/features/accounts/ui/sign_in_screen.dart';
import 'package:nestprep/shared/copy/kid_copy.dart';

import '../../../support/pump_screen.dart';

/// The kid's way in is on the sign-in screen, beside the grown-ups' — a child
/// who cannot find it cannot sign in at all (accounts ADR-0003, and the lesson
/// on capabilities finished everywhere except the screen).
void main() {
  testWidgets('the sign-in screen offers a child the way in, and it opens', (
    tester,
  ) async {
    await pumpRouter(
      tester,
      router: GoRouter(
        routes: [
          GoRoute(path: '/', builder: (context, state) => const SignInScreen()),
          GoRoute(
            path: KidRoute.codePath,
            builder: (context, state) => const Placeholder(),
          ),
        ],
      ),
      providers: const [],
    );
    await tester.pumpAndSettle();

    final wayIn = find.text(KidCopy.signInWithCode);
    await tester.ensureVisible(wayIn);
    await tester.pumpAndSettle();
    expect(find.text(KidCopy.signInPrompt), findsOneWidget);

    await tester.tap(wayIn);
    await tester.pumpAndSettle();

    expect(find.byType(Placeholder), findsOneWidget);
  });
}
