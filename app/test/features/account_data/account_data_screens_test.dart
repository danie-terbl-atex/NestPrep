import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/account_data/state/account_deletion_controller.dart';
import 'package:nestprep/features/account_data/state/account_export_controller.dart';
import 'package:nestprep/features/account_data/ui/account_centre_screen.dart';
import 'package:nestprep/features/account_data/ui/account_export_screen.dart';
import 'package:nestprep/features/account_data/ui/delete_account_screen.dart';
import 'package:nestprep/features/legal/ui/about_screen.dart';
import 'package:nestprep/features/legal/ui/legal_document_screen.dart';
import 'package:nestprep/features/legal/ui/licences_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../support/accessibility_audit.dart';
import '../../support/fake_account_data.dart';
import '../../support/pump_screen.dart';

/// The account centre, Download my data and Delete my account (accounts
/// ADR-0006): every state a person can reach, the way in to each page, and
/// dark at 200% text on a 360-wide phone for each (`FE-08`, `FE-13`, `FE-14`).
void main() {
  late FakeAccountDataGateway gateway;
  late FakeExportSharer sharer;
  late int signOuts;

  setUp(() {
    gateway = FakeAccountDataGateway();
    sharer = FakeExportSharer();
    signOuts = 0;
  });

  Future<void> pumpAt(
    WidgetTester tester,
    String start, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) {
    GoRoute placeholder(String path) =>
        GoRoute(path: path, builder: (_, _) => Text('page $path'));
    return pumpRouter(
      tester,
      router: GoRouter(
        initialLocation: start,
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Text('home')),
          GoRoute(
            path: AccountCentreScreen.path,
            builder: (_, _) => const AccountCentreScreen(),
          ),
          GoRoute(
            path: AccountExportScreen.path,
            builder: (_, _) => ChangeNotifierProvider(
              create: (_) => AccountExportController(
                accountDataGateway: gateway,
                exportSharer: sharer,
              ),
              child: const AccountExportScreen(),
            ),
          ),
          GoRoute(
            path: DeleteAccountScreen.path,
            builder: (_, _) => ChangeNotifierProvider(
              create: (_) => AccountDeletionController(
                accountDataGateway: gateway,
                signOut: () async => signOuts++,
              ),
              child: const DeleteAccountScreen(),
            ),
          ),
          placeholder(AboutScreen.path),
          placeholder(LegalDocumentScreen.privacyPath),
          placeholder(LegalDocumentScreen.termsPath),
          placeholder(LicencesScreen.path),
        ],
      ),
      providers: const [],
      brightness: brightness,
      textScale: scale,
    );
  }

  /// Brings a lazily built row into view, then taps it.
  Future<void> tapInList(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  group('the account centre', () {
    testWidgets('offers both rights and the legal pages', (tester) async {
      await pumpAt(tester, AccountCentreScreen.path);
      await tester.pumpAndSettle();

      expect(find.text(AccountDataCopy.downloadRow), findsOneWidget);
      expect(find.text(AccountDataCopy.deleteRow), findsOneWidget);
      expect(find.text(LegalCopy.privacyTitle), findsOneWidget);
      expect(find.text(LegalCopy.termsTitle), findsOneWidget);
      expect(find.text(LegalCopy.licencesTitle), findsOneWidget);
    });

    testWidgets('each row opens its page', (tester) async {
      await pumpAt(tester, AccountCentreScreen.path);
      await tester.pumpAndSettle();

      await tester.tap(find.text(LegalCopy.termsTitle));
      await tester.pumpAndSettle();
      expect(
        find.text('page ${LegalDocumentScreen.termsPath}'),
        findsOneWidget,
      );
    });

    testWidgets('is accessible and survives dark at 200% on a small phone', (
      tester,
    ) async {
      phone(tester);
      await pumpAt(
        tester,
        AccountCentreScreen.path,
        brightness: Brightness.dark,
        scale: 2,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectAccessible(tester, 'account centre');
    });
  });

  group('Download my data', () {
    testWidgets('says what the file holds before anything is asked', (
      tester,
    ) async {
      await pumpAt(tester, AccountExportScreen.path);
      await tester.pumpAndSettle();

      expect(find.text(AccountDataCopy.exportIncludesTitle), findsOneWidget);
      expect(find.text(AccountDataCopy.exportPrepare), findsOneWidget);
      expect(gateway.exports, 0);
    });

    testWidgets('gathers, then offers the share sheet', (tester) async {
      await pumpAt(tester, AccountExportScreen.path);
      await tester.pumpAndSettle();
      gateway.exportGate = Completer<void>();

      await tester.tap(find.text(AccountDataCopy.exportPrepare));
      await tester.pump();
      expect(find.text(AccountDataCopy.exportPreparing), findsOneWidget);

      gateway.exportGate?.complete();
      await tester.pumpAndSettle();
      expect(find.text(AccountDataCopy.exportReadyTitle), findsOneWidget);

      await tapInList(tester, find.text(AccountDataCopy.exportShare));
      expect(sharer.shared, hasLength(1));
    });

    testWidgets('a refusal is words and a retry', (tester) async {
      gateway.exportError = const AccountDataFailure(
        AccountDataProblem.tooManyRequests,
      );
      await pumpAt(tester, AccountExportScreen.path);
      await tester.pumpAndSettle();
      await tapInList(tester, find.text(AccountDataCopy.exportPrepare));

      expect(
        find.text(AccountDataCopy.problem(AccountDataProblem.tooManyRequests)),
        findsOneWidget,
      );
      gateway.exportError = null;
      await tapInList(tester, find.text(AppCopy.retry));
      expect(find.text(AccountDataCopy.exportReadyTitle), findsOneWidget);
    });

    testWidgets('is accessible and survives dark at 200% on a small phone', (
      tester,
    ) async {
      phone(tester);
      await pumpAt(
        tester,
        AccountExportScreen.path,
        brightness: Brightness.dark,
        scale: 2,
      );
      await tester.pumpAndSettle();
      await tapInList(tester, find.text(AccountDataCopy.exportPrepare));
      expect(tester.takeException(), isNull);
      await expectAccessible(tester, 'download my data');
    });
  });

  group('Delete my account', () {
    testWidgets('holds the layout while the preview loads', (tester) async {
      await pumpAt(tester, DeleteAccountScreen.path);
      await tester.pump();
      expect(find.byKey(const ValueKey('loading')), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets(
      'says what happens to every household, and warns about the store',
      (tester) async {
        await pumpAt(tester, DeleteAccountScreen.path);
        await tester.pumpAndSettle();

        expect(
          find.text(AccountDataCopy.outcomeHandOver('The Parkers', 'Alex')),
          findsOneWidget,
        );
        expect(
          find.text(AccountDataCopy.outcomeEnd('Gran’s house', 2)),
          findsOneWidget,
        );
        expect(
          find.text(AccountDataCopy.outcomeLeave('The Smiths')),
          findsOneWidget,
        );
        await scrollTo(
          tester,
          find.text(AccountDataCopy.renewingSubscriptions(1)),
        );
        expect(
          find.text(AccountDataCopy.renewingSubscriptions(1)),
          findsOneWidget,
        );
      },
    );

    testWidgets('says so plainly when there is no household at all', (
      tester,
    ) async {
      gateway.preview = AccountDataFixtures.nothing;
      await pumpAt(tester, DeleteAccountScreen.path);
      await tester.pumpAndSettle();
      expect(find.text(AccountDataCopy.deleteNoHouseholds), findsOneWidget);
    });

    testWidgets('a preview that cannot be read offers a retry', (tester) async {
      gateway.previewError = const UnavailableFailure();
      await pumpAt(tester, DeleteAccountScreen.path);
      await tester.pumpAndSettle();
      expect(find.text(AppCopy.retry), findsOneWidget);

      gateway.previewError = null;
      await tester.tap(find.text(AppCopy.retry));
      await tester.pumpAndSettle();
      expect(find.text(AccountDataCopy.deleteButton), findsWidgets);
    });

    testWidgets('deletes only once DELETE is typed, then signs out', (
      tester,
    ) async {
      await pumpAt(tester, DeleteAccountScreen.path);
      await tester.pumpAndSettle();
      final button = find.widgetWithText(
        NestButton,
        AccountDataCopy.deleteButton,
      );

      await tapInList(tester, button);
      expect(gateway.deletions, isEmpty);

      await scrollTo(tester, find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'DELETE');
      await tester.pumpAndSettle();
      await tester.ensureVisible(button);
      await tester.tap(button);
      // The spinner runs until the router, on the real app, takes the
      // signed-out person to the sign-in screen — so pump, not settle.
      await tester.pump();
      await tester.pump();
      expect(gateway.deletions, [
        ['h-gran'],
      ]);
      expect(signOuts, 1);
    });

    testWidgets(
      'a changed plan is shown again, with why, and the word cleared',
      (tester) async {
        gateway.deleteError = const AccountDataFailure(
          AccountDataProblem.deletionPlanChanged,
        );
        await pumpAt(tester, DeleteAccountScreen.path);
        await tester.pumpAndSettle();
        await scrollTo(tester, find.byType(TextField));
        await tester.enterText(find.byType(TextField), 'DELETE');
        await tester.pumpAndSettle();
        await tapInList(
          tester,
          find.widgetWithText(NestButton, AccountDataCopy.deleteButton),
        );
        await scrollTo(
          tester,
          find.text(
            AccountDataCopy.problem(AccountDataProblem.deletionPlanChanged),
          ),
        );

        expect(
          find.text(
            AccountDataCopy.problem(AccountDataProblem.deletionPlanChanged),
          ),
          findsOneWidget,
        );
        expect(signOuts, 0);
        expect(gateway.previewCalls, 2);
      },
    );

    testWidgets('is accessible and survives dark at 200% on a small phone', (
      tester,
    ) async {
      phone(tester);
      await pumpAt(
        tester,
        DeleteAccountScreen.path,
        brightness: Brightness.dark,
        scale: 2,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectAccessible(tester, 'delete my account');
    });
  });
}
