import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/feedback/model/feedback_draft.dart';
import 'package:nestprep/features/feedback/state/feedback_controller.dart';
import 'package:nestprep/features/feedback/ui/feedback_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../support/accessibility_audit.dart';
import '../../support/fake_feedback.dart';
import '../../support/pump_screen.dart';

void main() {
  late FakeFeedbackRepository repository;

  setUp(() => repository = FakeFeedbackRepository());

  Future<void> pumpFeedback(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    await pumpRouter(
      tester,
      router: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Text('home')),
          GoRoute(path: '/account', builder: (_, _) => const Text('centre')),
          GoRoute(
            path: FeedbackScreen.path,
            builder: (context, state) => ChangeNotifierProvider(
              create: (_) => FeedbackController(
                repository: repository,
                uid: 'uid-sam',
                householdId: 'h1',
                screen: state.uri.queryParameters[FeedbackScreen.fromParameter],
              ),
              child: const FeedbackScreen(),
            ),
          ),
        ],
      ),
      providers: const [],
      brightness: brightness,
      textScale: scale,
    );
    await tester.pumpAndSettle();
    unawaited(
      GoRouter.of(tester.element(find.text('home'))).push<void>(
        FeedbackScreen.location(from: '/households/:householdId/lunch'),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  Future<void> tapInList(WidgetTester tester, Finder finder) async {
    await reveal(tester, finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> fillIn(WidgetTester tester, String message) async {
    await tapInList(
      tester,
      find.byKey(const ValueKey('feedback-kind-problem')),
    );
    final field = find.descendant(
      of: find.byKey(const ValueKey('feedback-message')),
      matching: find.byType(EditableText),
    );
    await reveal(tester, field);
    await tester.enterText(field, message);
    await tester.pumpAndSettle();
  }

  final send = find.byKey(const ValueKey('feedback-send'));

  Future<NestButton> sendButton(WidgetTester tester) async {
    await reveal(tester, send);
    return tester.widget<NestButton>(send);
  }

  testWidgets('sends once a kind is chosen and something is written', (
    tester,
  ) async {
    await pumpFeedback(tester);
    expect((await sendButton(tester)).onPressed, isNull);
    final field = find.descendant(
      of: find.byKey(const ValueKey('feedback-message')),
      matching: find.byType(EditableText),
    );
    await reveal(tester, field);
    await tester.enterText(field, 'No kind yet');
    await tester.pumpAndSettle();
    expect((await sendButton(tester)).onPressed, isNull);

    await fillIn(tester, 'The grocery list forgets ticks');
    await tapInList(
      tester,
      find.byKey(const ValueKey('feedback-area-groceries')),
    );
    await tapInList(tester, find.text(FeedbackCopy.mayContact));
    await tapInList(tester, send);

    expect(find.text(FeedbackCopy.deliveredTitle), findsOneWidget);
    expect(find.text(FeedbackCopy.deliveredBody), findsOneWidget);
    final sent = repository.sent.single.draft;
    expect(sent.kind, FeedbackKind.problem);
    expect(sent.area, FeedbackArea.groceries);
    expect(sent.mayContact, isTrue);
    expect(sent.screen, '/households/:householdId/lunch');
  });

  testWidgets('says the message waits for the phone to be online', (
    tester,
  ) async {
    repository.delivery = FeedbackDelivery.queued;
    await pumpFeedback(tester);
    await fillIn(tester, 'Offline in the car park');
    await tapInList(tester, send);

    expect(find.text(FeedbackCopy.queuedBody), findsOneWidget);
  });

  testWidgets('a refusal shows above the form and keeps the words', (
    tester,
  ) async {
    repository.refuseWith = const UnavailableFailure();
    await pumpFeedback(tester);
    await fillIn(tester, 'Keep me');
    await tapInList(tester, send);

    await reveal(
      tester,
      find.text(AppCopy.failure(const UnavailableFailure())),
    );
    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
    expect(find.text('Keep me'), findsOneWidget);
  });

  testWidgets('shows it is sending and cannot be sent twice', (tester) async {
    repository.gate = Completer<void>();
    await pumpFeedback(tester);
    await fillIn(tester, 'Once only');
    await reveal(tester, send);
    await tester.tap(send);
    await tester.pump();

    expect(tester.widget<NestButton>(send).isLoading, isTrue);
    expect(tester.widget<NestButton>(send).onPressed, isNull);
    repository.gate?.complete();
    await tester.pumpAndSettle();
    expect(repository.sent, hasLength(1));
  });

  testWidgets('Done goes back to where it was opened from', (tester) async {
    await pumpFeedback(tester);
    await fillIn(tester, 'Thanks');
    await tapInList(tester, send);
    await tapInList(tester, find.byKey(const ValueKey('feedback-done')));

    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('Send something else starts a clean form', (tester) async {
    await pumpFeedback(tester);
    await fillIn(tester, 'First');
    await tapInList(tester, send);
    await tapInList(tester, find.text(FeedbackCopy.another));

    expect(find.text('First'), findsNothing);
    expect((await sendButton(tester)).onPressed, isNull);
  });

  testWidgets('is accessible and survives dark at 200% on a small phone', (
    tester,
  ) async {
    phone(tester);
    await pumpFeedback(tester, brightness: Brightness.dark, scale: 2);
    expect(tester.takeException(), isNull);
    await expectAccessible(tester, 'send feedback');

    await fillIn(tester, 'Big text');
    await tapInList(tester, send);
    expect(tester.takeException(), isNull);
    await expectAccessible(tester, 'feedback sent');
  });
}
