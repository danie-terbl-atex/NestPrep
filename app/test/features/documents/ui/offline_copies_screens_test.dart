import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/documents_route.dart';
import 'package:nestprep/features/documents/model/document_folder.dart';
import 'package:nestprep/features/documents/model/household_document.dart';
import 'package:nestprep/features/documents/model/vault_lock_state.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/vault_copy.dart';

import '../../../support/fake_document_tools.dart';
import '../../../support/fake_vault.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_documents.dart';

/// Offline copies, through the real Documents shell over fakes (documents
/// ADR-0007): behind the vaults' lock, kept from a document's own sheet with
/// a badge to show it, opened with no connection, and removed.
void main() {
  late DocumentsFakes fakes;
  final offlinePath = DocumentsRoute.offlinePathFor(Fixtures.householdId);
  final kidVault = DocumentsRoute.vaultPersonPathFor(
    Fixtures.householdId,
    Fixtures.kidMemberId,
  );
  final folderPath = DocumentsRoute.folderPathFor(
    Fixtures.householdId,
    'f-house',
  );

  setUp(() => fakes = DocumentsFakes());
  tearDown(() => fakes.close());

  Future<void> letItOpen(WidgetTester tester) async {
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> tapOn(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('the offline screen', () {
    testWidgets('stays behind the lock until the phone says yes', (
      tester,
    ) async {
      fakes.deviceLock.outcome = UnlockOutcome.cancelled;
      await fakes.offlineStore.save(
        Fixtures.samUid,
        anOfflineCopy('card'),
        onePixelPng,
      );
      await pumpDocuments(tester, fakes: fakes, location: offlinePath);
      await letItOpen(tester);

      expect(find.text(VaultCopy.lockedTitle), findsOneWidget);
      expect(find.text('Copy of card'), findsNothing);
      expect(fakes.offlineCheck.checked, isEmpty);
    });

    testWidgets('says what it is for when nothing is kept', (tester) async {
      await pumpDocuments(tester, fakes: fakes, location: offlinePath);
      await letItOpen(tester);
      await tester.pumpAndSettle();

      expect(find.text(OfflineCopiesCopy.emptyTitle), findsOneWidget);
      expect(find.text(OfflineCopiesCopy.emptyBody), findsOneWidget);
    });

    testWidgets('lists each copy with its badge and the room they take, and '
        'opens one from the phone', (tester) async {
      await fakes.offlineStore.save(
        Fixtures.samUid,
        anOfflineCopy('card', ownerMemberId: Fixtures.kidMemberId),
        onePixelPng,
      );
      await pumpDocuments(tester, fakes: fakes, location: offlinePath);
      await letItOpen(tester);
      await tester.pumpAndSettle();

      expect(find.text('Copy of card'), findsOneWidget);
      expect(find.text(OfflineCopiesCopy.badge), findsOneWidget);
      expect(find.textContaining('1 of 20 kept'), findsOneWidget);
      expect(find.text(OfflineCopiesCopy.checked), findsOneWidget);

      await tapOn(tester, find.text('Copy of card'));
      expect(find.byType(Image), findsWidgets);
      // Opened from the phone: the server was not asked for anything.
      expect(fakes.directory.opened, isEmpty);
    });

    testWidgets('removes every copy after asking', (tester) async {
      await fakes.offlineStore.save(
        Fixtures.samUid,
        anOfflineCopy('card'),
        onePixelPng,
      );
      await pumpDocuments(tester, fakes: fakes, location: offlinePath);
      await letItOpen(tester);
      await tester.pumpAndSettle();

      await tapOn(tester, find.text(OfflineCopiesCopy.removeAll));
      expect(find.text(OfflineCopiesCopy.removeAllTitle), findsOneWidget);
      await tapOn(tester, find.text(OfflineCopiesCopy.removeAll).last);

      expect(find.text(OfflineCopiesCopy.emptyTitle), findsOneWidget);
      expect(await fakes.offlineStore.list(Fixtures.samUid), isEmpty);
    });

    testWidgets('renders in dark and at 200% text without overflowing', (
      tester,
    ) async {
      onASmallPhone(tester);
      await fakes.offlineStore.save(
        Fixtures.samUid,
        anOfflineCopy('card', ownerMemberId: Fixtures.kidMemberId),
        onePixelPng,
      );
      await pumpDocuments(
        tester,
        fakes: fakes,
        location: offlinePath,
        brightness: Brightness.dark,
        textScale: 2,
      );
      await letItOpen(tester);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('keeping a document', () {
    testWidgets('a vault document is kept from its sheet, logged, and its row '
        'says so', (tester) async {
      await pumpDocuments(tester, fakes: fakes, location: kidVault);
      await letItOpen(tester);
      answerEmptyVaults(fakes);
      fakes.vaults.emitVault('m-kid', [vaultDocument('card', name: 'Card')]);
      await tester.pumpAndSettle();

      await tapOn(tester, find.text('Card'));
      final opensBefore = fakes.directory.opened.length;
      await tapOn(tester, find.text(OfflineCopiesCopy.keep));

      expect(fakes.directory.opened.length, opensBefore + 1);
      final kept = await fakes.offlineStore.list(Fixtures.samUid);
      expect(kept.single.ownerMemberId, Fixtures.kidMemberId);
      expect(find.text(OfflineCopiesCopy.remove), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text(OfflineCopiesCopy.badge), findsOneWidget);
    });

    testWidgets('a household document asks for the lock first, then keeps', (
      tester,
    ) async {
      fakes.store.bytes = onePixelPng;
      await pumpDocuments(tester, fakes: fakes, location: folderPath);
      fakes.documents.emitFolders([
        const DocumentFolder(
          id: 'f-house',
          name: 'House',
          createdBy: Fixtures.samMemberId,
        ),
      ]);
      fakes.documents.emitDocuments([
        const HouseholdDocument(
          id: 'policy',
          folderId: 'f-house',
          name: 'Car insurance',
          contentType: 'image/png',
          sizeBytes: 3,
          uploadedBy: Fixtures.samMemberId,
        ),
      ]);
      await tester.pumpAndSettle();

      await tapOn(tester, find.text('Car insurance'));
      expect(find.text(ShareLinkCopy.shareAction), findsOneWidget);
      await tapOn(tester, find.text(OfflineCopiesCopy.keep));

      expect(fakes.deviceLock.asked, 1);
      final kept = await fakes.offlineStore.list(Fixtures.samUid);
      expect(kept.single.name, 'Car insurance');
      expect(kept.single.ownerMemberId, isNull);
    });

    testWidgets('with the switch off, a sheet offers neither', (tester) async {
      await pumpDocuments(
        tester,
        fakes: fakes,
        location: kidVault,
        flagsDefaultOn: false,
      );
      await letItOpen(tester);
      answerEmptyVaults(fakes);
      fakes.vaults.emitVault('m-kid', [vaultDocument('card', name: 'Card')]);
      await tester.pumpAndSettle();

      await tapOn(tester, find.text('Card'));
      expect(find.text(OfflineCopiesCopy.keep), findsNothing);
      expect(find.text(ShareLinkCopy.shareAction), findsNothing);
      expect(find.text(AppCopy.documentsDelete), findsOneWidget);
    });
  });
}
