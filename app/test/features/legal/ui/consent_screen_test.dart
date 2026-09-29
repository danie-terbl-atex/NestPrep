import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/features/legal/ui/consent_screen.dart';
import 'package:nestprep/features/legal/ui/legal_document_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_auth.dart';
import '../../../support/fake_legal.dart';

/// The consent step (accounts ADR-0005), from the person's side.
void main() {
  late FakeAccountRepository accounts;

  setUp(() => accounts = FakeAccountRepository());
  tearDown(() => accounts.close());

  Future<void> pumpConsent(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) => pumpLegal(
    tester,
    location: ConsentScreen.path,
    accounts: accounts,
    brightness: brightness,
    textScale: textScale,
  );

  Future<void> reach(WidgetTester tester, String label) async {
    await tester.scrollUntilVisible(
      find.text(label),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
  }

  Future<void> tick(WidgetTester tester, String label) async {
    await reach(tester, label);
    await tester.tap(find.text(label));
    await tester.pump();
  }

  Future<void> press(WidgetTester tester, String label) async {
    await reach(tester, label);
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('says what NestPrep keeps before asking', (tester) async {
    await pumpConsent(tester);
    expect(find.text(LegalCopy.consentTitle), findsOneWidget);
    expect(find.text(LegalCopy.consentChildren), findsOneWidget);
    expect(find.text(LegalCopy.consentHealth), findsOneWidget);
    expect(find.text(LegalCopy.consentDocuments), findsOneWidget);
    expect(find.text(LegalCopy.consentLocation), findsOneWidget);
  });

  testWidgets('agreeing takes both ticks, then records it', (tester) async {
    await pumpConsent(tester);
    await press(tester, LegalCopy.consentAccept);
    expect(accounts.acceptedLegal, isEmpty, reason: 'nothing is ticked yet');

    await tick(tester, LegalCopy.consentAdult);
    await press(tester, LegalCopy.consentAccept);
    expect(accounts.acceptedLegal, isEmpty, reason: 'one tick is not enough');

    await tick(tester, LegalCopy.consentAgree);
    await press(tester, LegalCopy.consentAccept);
    expect(accounts.acceptedLegal, hasLength(1));
  });

  testWidgets('a tick is a checkbox to a screen reader', (tester) async {
    await pumpConsent(tester);
    final handle = tester.ensureSemantics();
    await tick(tester, LegalCopy.consentAdult);
    expect(
      tester.getSemantics(find.text(LegalCopy.consentAdult)),
      matchesSemantics(
        label: LegalCopy.consentAdult,
        hasCheckedState: true,
        isChecked: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('a failed write shows why and can be tried again', (
    tester,
  ) async {
    accounts.failWritesWith = const UnavailableFailure();
    await pumpConsent(tester);
    await tick(tester, LegalCopy.consentAdult);
    await tick(tester, LegalCopy.consentAgree);
    await press(tester, LegalCopy.consentAccept);
    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );

    accounts.failWritesWith = null;
    await press(tester, AppCopy.retry);
    expect(accounts.acceptedLegal, hasLength(1));
  });

  testWidgets('both documents are a tap away', (tester) async {
    await pumpConsent(tester);
    await press(tester, LegalCopy.consentReadPrivacy);
    expect(find.byType(LegalDocumentScreen), findsOneWidget);
    expect(find.text(LegalCopy.privacyTitle), findsOneWidget);
  });

  testWidgets('the way out is signing out', (tester) async {
    final auth = FakeAuthGateway();
    final session = SessionController(
      authGateway: auth,
      accountRepository: accounts,
    );
    addTearDown(() async {
      session.dispose();
      await auth.close();
    });
    await pumpLegal(
      tester,
      location: ConsentScreen.path,
      accounts: accounts,
      session: session,
    );
    await press(tester, LegalCopy.consentSignOut);
    // Where that lands is the router's, and its tests prove it.
    expect(auth.signOutCount, 1);
    expect(accounts.acceptedLegal, isEmpty);
  });

  testWidgets('survives dark at 200% text on a 360-wide phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpConsent(tester, brightness: Brightness.dark, textScale: 2);
    await reach(tester, LegalCopy.consentSignOut);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
