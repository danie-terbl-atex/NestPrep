import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/documents_route.dart';
import 'package:nestprep/features/documents/model/document_folder.dart';
import 'package:nestprep/features/documents/model/household_document.dart';
import 'package:nestprep/features/documents/model/vault_lock_state.dart';
import 'package:nestprep/features/documents/model/vault_view.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/vault_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/household_clock.dart';

import '../../../support/fake_vault.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_documents.dart';

/// The view log and search, through the real Documents shell (documents
/// ADR-0003, ADR-0005), and the way into the vaults from the folders.
void main() {
  late DocumentsFakes fakes;
  final home = DocumentsRoute.pathFor(Fixtures.householdId);
  final log = DocumentsRoute.vaultLogPathFor(Fixtures.householdId);
  final search = DocumentsRoute.searchPathFor(Fixtures.householdId);

  setUp(() => fakes = DocumentsFakes());
  tearDown(() => fakes.close());

  Future<void> letItOpen(WidgetTester tester) async {
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  VaultView opened(String id, {String by = 'm-thandi'}) => VaultView(
    id: id,
    documentId: 'passport',
    documentName: 'Emma passport',
    viewerMemberId: by,
    viewedAt: DateTime.now().toUtc(),
  );

  void answerHouseholdPapers() {
    fakes.documents.emitFolders([
      const DocumentFolder(id: 'f-car', name: 'Car', createdBy: 'm-sam'),
    ]);
    fakes.documents.emitDocuments([
      HouseholdDocument(
        id: 'licence',
        folderId: 'f-car',
        name: 'Licence disc',
        contentType: 'application/pdf',
        sizeBytes: 1000,
        uploadedBy: 'm-sam',
        tags: const ['Car'],
        expiresOn: HouseholdClock('Africa/Johannesburg').today.addDays(5),
      ),
    ]);
  }

  group('the view log', () {
    testWidgets('names who opened what, in whose vault', (tester) async {
      await pumpDocuments(tester, fakes: fakes, location: log);
      await letItOpen(tester);
      fakes.vaults.emitViews('m-sam', []);
      fakes.vaults.emitViews('m-thandi', []);
      fakes.vaults.emitViews('m-kid', [opened('v1')]);
      await tester.pumpAndSettle();

      expect(find.text('Emma passport'), findsOneWidget);
      expect(
        find.textContaining(
          VaultCopy.logLine('Thandi Helper', VaultCopy.vaultOf('Kid Parker')),
        ),
        findsOneWidget,
      );
      expect(find.text(VaultCopy.logBody), findsOneWidget);
    });

    testWidgets('an open through a shared link says so, with nobody named', (
      tester,
    ) async {
      await pumpDocuments(tester, fakes: fakes, location: log);
      await letItOpen(tester);
      fakes.vaults.emitViews('m-sam', []);
      fakes.vaults.emitViews('m-thandi', []);
      fakes.vaults.emitViews('m-kid', [
        opened('v1').copyWith(viewerMemberId: null, shareId: 'share-1'),
      ]);
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          VaultCopy.logLine(
            VaultCopy.logThroughLink,
            VaultCopy.vaultOf('Kid Parker'),
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('says so when nothing has been opened', (tester) async {
      await pumpDocuments(tester, fakes: fakes, location: log);
      await letItOpen(tester);
      for (final owner in ['m-sam', 'm-thandi', 'm-kid']) {
        fakes.vaults.emitViews(owner, []);
      }
      await tester.pumpAndSettle();
      expect(find.text(VaultCopy.logEmptyTitle), findsOneWidget);
    });

    testWidgets('a refused log offers a retry, never a code', (tester) async {
      await pumpDocuments(tester, fakes: fakes, location: log);
      await letItOpen(tester);
      fakes.vaults.failViews('m-kid', const PermissionDeniedFailure());
      await tester.pumpAndSettle();
      expect(find.text(AppCopy.retry), findsOneWidget);
    });

    testWidgets('is behind the lock like every vault screen', (tester) async {
      fakes.deviceLock.outcome = UnlockOutcome.cancelled;
      await pumpDocuments(tester, fakes: fakes, location: log);
      await tester.pumpAndSettle();
      expect(find.text(VaultCopy.lockedTitle), findsOneWidget);
      expect(find.text(VaultCopy.logTitle), findsNothing);
    });

    testWidgets('renders in dark and at 200% text without overflowing', (
      tester,
    ) async {
      onASmallPhone(tester);
      await pumpDocuments(
        tester,
        fakes: fakes,
        location: log,
        brightness: Brightness.dark,
        textScale: 2,
      );
      await letItOpen(tester);
      fakes.vaults.emitViews('m-sam', []);
      fakes.vaults.emitViews('m-thandi', []);
      fakes.vaults.emitViews('m-kid', [
        opened('v1'),
        opened('v2', by: 'm-sam'),
      ]);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('search', () {
    testWidgets('while the vaults are locked, searches the household\'s '
        'papers and says so', (tester) async {
      await pumpDocuments(tester, fakes: fakes, location: search);
      await tester.pump();
      answerHouseholdPapers();
      await tester.pumpAndSettle();

      expect(find.text(VaultCopy.searchLockedNote), findsOneWidget);
      expect(find.text('Licence disc'), findsOneWidget);
      expect(find.text(VaultCopy.expiresIn(5)), findsOneWidget);
    });

    testWidgets('unlocking from search brings the vaults into the results', (
      tester,
    ) async {
      await pumpDocuments(tester, fakes: fakes, location: search);
      await tester.pump();
      answerHouseholdPapers();
      await tester.pumpAndSettle();

      await tester.tap(find.text(VaultCopy.unlock));
      await letItOpen(tester);
      answerEmptyVaults(fakes);
      fakes.vaults.emitVault('m-kid', [
        vaultDocument('passport', name: 'Kid passport', tags: const ['ID']),
      ]);
      await tester.pumpAndSettle();

      expect(find.text(VaultCopy.searchLockedNote), findsNothing);
      expect(find.text('Kid passport'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'kid parker');
      await tester.pumpAndSettle();
      expect(find.text('Kid passport'), findsOneWidget);
      expect(find.text('Licence disc'), findsNothing);
    });

    testWidgets('filters by household only, and by tag', (tester) async {
      await pumpDocuments(
        tester,
        fakes: fakes,
        location: DocumentsRoute.searchPathFor(
          Fixtures.householdId,
          person: DocumentsRoute.householdPerson,
        ),
      );
      await tester.pump();
      answerHouseholdPapers();
      await tester.pumpAndSettle();

      expect(find.text('Licence disc'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'nothing like it');
      await tester.pumpAndSettle();
      expect(find.text(VaultCopy.searchNoResultsTitle), findsOneWidget);

      await tester.tap(find.text(VaultCopy.searchClearFilters));
      await tester.pumpAndSettle();
      expect(
        find.text(VaultCopy.searchNoResultsTitle),
        findsOneWidget,
        reason: 'clearing the filters keeps what was typed',
      );
    });

    testWidgets('renders in dark and at 200% text without overflowing', (
      tester,
    ) async {
      onASmallPhone(tester);
      await pumpDocuments(
        tester,
        fakes: fakes,
        location: search,
        brightness: Brightness.dark,
        textScale: 2,
      );
      await tester.pump();
      answerHouseholdPapers();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('the way in, from the folders', () {
    testWidgets('the vaults card says they are locked, and opens the lock', (
      tester,
    ) async {
      fakes.deviceLock.outcome = UnlockOutcome.cancelled;
      await pumpDocuments(tester, fakes: fakes, location: home);
      await tester.pump();
      answerLibrary(fakes);
      await tester.pumpAndSettle();

      expect(find.text(VaultCopy.entryTitle), findsOneWidget);
      expect(find.text(VaultCopy.entryLocked), findsOneWidget);

      await tester.tap(find.text(VaultCopy.entryTitle));
      await tester.pumpAndSettle();
      expect(find.text(VaultCopy.lockedTitle), findsOneWidget);
    });

    testWidgets('and search is in the header, with no folders at all', (
      tester,
    ) async {
      await pumpDocuments(tester, fakes: fakes, location: home);
      await tester.pump();
      answerLibrary(fakes);
      await tester.pumpAndSettle();

      expect(find.text(AppCopy.documentsEmptyTitle), findsOneWidget);
      expect(find.text(VaultCopy.entryTitle), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(VaultCopy.searchTitle));
      await tester.pumpAndSettle();
      expect(find.text(VaultCopy.searchHint), findsOneWidget);
    });

    testWidgets('household papers that expire soon are shown above the '
        'folders', (tester) async {
      await pumpDocuments(tester, fakes: fakes, location: home);
      await tester.pump();
      answerHouseholdPapers();
      await tester.pumpAndSettle();

      expect(find.text(VaultCopy.expiringTitle), findsOneWidget);
      expect(find.text('Licence disc'), findsOneWidget);
    });
  });
}
