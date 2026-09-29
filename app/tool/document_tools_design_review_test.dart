import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/documents/data/document_share_directory.dart';
import 'package:nestprep/features/documents/model/share_target.dart';
import 'package:nestprep/features/documents/state/document_shares_controller.dart';
import 'package:nestprep/features/documents/state/offline_copies_controller.dart';
import 'package:nestprep/features/documents/state/offline_copy_source.dart';
import 'package:nestprep/features/documents/state/vault_lock_controller.dart';
import 'package:nestprep/features/documents/ui/document_shares_screen.dart';
import 'package:nestprep/features/documents/ui/offline_copies_screen.dart';
import 'package:nestprep/features/documents/ui/share_link_sheet.dart';
import 'package:nestprep/features/household/data/invite_sharer.dart';
import 'package:nestprep/features/nanny_hub/data/shift_repository.dart';
import 'package:nestprep/features/nanny_hub/model/shift.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/vault_copy.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../test/support/fake_document_tools.dart';
import '../test/support/fake_documents.dart';
import '../test/support/fake_invite_sharer.dart';
import '../test/support/fake_nanny_shifts.dart';
import '../test/support/fake_vault.dart';
import '../test/support/household_fixtures.dart';
import 'review_press.dart';

/// Documents V2 in the design-review press (documents ADR-0006, ADR-0007):
/// the share sheet with a shift on, the link once made, the live links, and
/// the phone's offline copies — light and dark. Regenerate with
///
///     flutter test tool/document_tools_design_review_test.dart --update-goldens
void main() {
  setUpAll(() async {
    tz_data.initializeTimeZones();
    await loadEveryFont();
  });

  final soon = DateTime.now().toUtc().add(const Duration(hours: 5));

  for (final brightness in Brightness.values) {
    final suffix = brightness.name;

    testWidgets('shared links, $suffix', (tester) async {
      final shares = FakeDocumentShareRepository();
      addTearDown(shares.close);
      final controller = DocumentSharesController(
        repository: shares,
        directory: FakeDocumentShareDirectory(),
        householdId: Fixtures.householdId,
        viewerUid: Fixtures.samUid,
        isFamily: true,
      );
      addTearDown(controller.dispose);
      await captureScreen(
        tester,
        'shared-links-$suffix',
        screen: const DocumentSharesScreen(),
        providers: [
          ChangeNotifierProvider<DocumentSharesController>.value(
            value: controller,
          ),
        ],
        brightness: brightness,
        emit: () async => shares.emit([
          aShare('s1', hasPin: true, openCount: 2, shiftId: 'shift-1'),
          aShare('s2', documentName: 'Car insurance', ownerMemberId: null),
          aShare('s3', documentName: 'Emma vaccinations', expiresAt: soon),
        ]),
      );
    });

    testWidgets('offline copies, $suffix', (tester) async {
      final lock = VaultLockController(
        deviceLock: FakeDeviceLock(),
        reason: VaultCopy.unlockReason,
      );
      addTearDown(lock.dispose);
      final store = InMemoryOfflineCopyStore();
      for (final (id, owner) in [
        ('Medical aid card', Fixtures.kidMemberId),
        ('Home insurance', null),
      ]) {
        await store.save(
          Fixtures.samUid,
          anOfflineCopy(id, ownerMemberId: owner),
          onePixelPng,
        );
      }
      final controller = OfflineCopiesController(
        store: store,
        accessCheck: FakeOfflineAccessCheck(),
        source: OfflineCopySource(
          documentStore: FakeDocumentStore(),
          vaultStore: FakeVaultStore(),
          documentDirectory: FakeDocumentDirectory(),
          householdId: Fixtures.householdId,
        ),
        pdfPageRenderer: FakePdfPageRenderer(),
        lock: lock,
        householdId: Fixtures.householdId,
        uid: Fixtures.samUid,
      );
      addTearDown(controller.dispose);
      await captureScreen(
        tester,
        'offline-copies-$suffix',
        screen: const OfflineCopiesScreen(),
        providers: [
          ChangeNotifierProvider<VaultLockController>.value(value: lock),
          ChangeNotifierProvider<OfflineCopiesController>.value(
            value: controller,
          ),
        ],
        brightness: brightness,
        emit: () async {
          await tester.runAsync(lock.unlock);
          await tester.pumpAndSettle();
        },
      );
    });

    for (final (name, makesLink) in [
      ('share-sheet', false),
      ('share-link-ready', true),
    ]) {
      testWidgets('$name, $suffix', (tester) async {
        final shifts = FakeShiftRepository();
        await captureScreen(
          tester,
          '$name-$suffix',
          screen: const _SheetOpener(),
          providers: [
            Provider<DocumentShareDirectory>.value(
              value: FakeDocumentShareDirectory(),
            ),
            Provider<InviteSharer>.value(value: FakeInviteSharer()),
            Provider<ShiftRepository>.value(value: shifts),
          ],
          brightness: brightness,
          emit: () async {
            await tester.tap(find.text(_SheetOpener.label));
            await tester.pumpAndSettle();
            shifts.openShifts.add([
              const Shift(
                id: 'shift-1',
                carerMemberId: Fixtures.thandiMemberId,
                startedBy: Fixtures.samMemberId,
              ),
            ]);
            await tester.pumpAndSettle();
            if (makesLink) {
              await tester.tap(find.text(ShareLinkCopy.create));
              await tester.pumpAndSettle();
            }
          },
        );
      });
    }
  }
}

/// A screen whose one job is to open the share sheet for the press.
class _SheetOpener extends StatelessWidget {
  const _SheetOpener();

  static const label = 'Open';

  @override
  Widget build(BuildContext context) => NestScaffold(
    title: AppCopy.documentsTitle,
    body: NestButton(
      label: label,
      onPressed: () => showShareLinkSheet(
        context: context,
        target: const ShareTarget(
          householdId: Fixtures.householdId,
          ownerMemberId: Fixtures.kidMemberId,
          documentId: 'card',
          name: 'Medical aid card',
          tags: [],
        ),
      ),
    ),
  );
}
