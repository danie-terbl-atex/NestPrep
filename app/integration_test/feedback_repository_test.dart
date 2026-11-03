import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/feedback/data/firestore_feedback_repository.dart';
import 'package:nestprep/features/feedback/model/feedback_draft.dart';
import 'package:nestprep/features/feedback/state/feedback_controller.dart';
import 'package:nestprep/features/feedback/ui/feedback_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import 'household_fixture.dart';

/// Feedback against the real Firestore and the real rules (feedback
/// ADR-0001): the screen sends through the repository and the server
/// acknowledges it, and a household the sender is not in is refused.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late TestHousehold home;
  late FirestoreFeedbackRepository feedback;

  setUpAll(() async {
    home = await signInAndCreateAHousehold();
    feedback = FirestoreFeedbackRepository(home.firestore);
  });

  tearDownAll(() async => home.signOut());

  String uid() => FirebaseAuth.instance.currentUser!.uid;

  for (final brightness in Brightness.values) {
    testWidgets(
      'the screen sends it and the server takes it (${brightness.name})',
      (tester) async {
        final router = GoRouter(
          initialLocation: FeedbackScreen.location(
            from: '/households/:householdId/lunch',
          ),
          routes: [
            GoRoute(
              path: FeedbackScreen.path,
              builder: (context, state) => ChangeNotifierProvider(
                create: (_) => FeedbackController(
                  repository: feedback,
                  uid: uid(),
                  householdId: home.id,
                  screen:
                      state.uri.queryParameters[FeedbackScreen.fromParameter],
                ),
                child: const FeedbackScreen(),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);
        final nest = brightness == Brightness.dark
            ? NestTheme.dark()
            : NestTheme.light();
        await tester.pumpWidget(
          MaterialApp.router(theme: nestThemeData(nest), routerConfig: router),
        );
        await tester.pumpAndSettle();
        await Future<void>.delayed(const Duration(seconds: 2));

        await tester.tap(find.byKey(const ValueKey('feedback-kind-problem')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.descendant(
            of: find.byKey(const ValueKey('feedback-message')),
            matching: find.byType(EditableText),
          ),
          'Integration ${brightness.name}: the grocery list forgets ticks',
        );
        await tester.pumpAndSettle();
        final groceries = find.byKey(const ValueKey('feedback-area-groceries'));
        await tester.ensureVisible(groceries);
        await tester.tap(groceries);
        await tester.pumpAndSettle();
        await Future<void>.delayed(const Duration(seconds: 2));

        final send = find.byKey(const ValueKey('feedback-send'));
        await tester.ensureVisible(send);
        await tester.tap(send);
        await tester.pumpAndSettle();
        for (var i = 0; i < 50; i++) {
          if (find.text(FeedbackCopy.deliveredTitle).evaluate().isNotEmpty) {
            break;
          }
          await tester.pump(const Duration(milliseconds: 200));
        }

        expect(find.text(FeedbackCopy.deliveredBody), findsOneWidget);
        await Future<void>.delayed(const Duration(seconds: 3));
      },
    );
  }

  testWidgets('a household the sender is not in is refused', (tester) async {
    await expectLater(
      feedback.send(
        uid: uid(),
        draft: const FeedbackDraft(
          kind: FeedbackKind.idea,
          message: 'Not my household',
          mayContact: false,
          householdId: 'somebody-elses-household',
        ),
      ),
      throwsA(isA<PermissionDeniedFailure>()),
    );
  });
}
