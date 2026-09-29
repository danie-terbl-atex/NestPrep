import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/documents_route.dart';
import 'package:nestprep/features/documents/model/vault_grant.dart';
import 'package:nestprep/features/documents/model/vault_lock_state.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/vault_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/time/household_clock.dart';

import '../../../support/fake_vault.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_documents.dart';

/// The vault's screens, through the real Documents shell over fakes (documents
/// ADR-0002, ADR-0003): the lock in front of them, a person per folder, what
/// is in each, and opening one — which the server must log first.
void main() {
  late DocumentsFakes fakes;
  final vaultPath = DocumentsRoute.vaultPathFor(Fixtures.householdId);
  final kidVault = DocumentsRoute.vaultPersonPathFor(
    Fixtures.householdId,
    Fixtures.kidMemberId,
  );

  setUp(() => fakes = DocumentsFakes());
  tearDown(() => fakes.close());

  CalendarDate today() => HouseholdClock('Africa/Johannesburg').today;

  /// Lets the lock screen ask and the vault open, without waiting for the
  /// loading skeleton to stop — it pulses until the vaults answer.
  Future<void> letItOpen(WidgetTester tester) async {
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> openVault(WidgetTester tester, String location) async {
    await pumpDocuments(tester, fakes: fakes, location: location);
    await letItOpen(tester);
  }

  group('the lock', () {
    testWidgets('asks the phone on arrival, and opens the vaults when it '
        'says yes', (tester) async {
      await openVault(tester, vaultPath);
      expect(fakes.deviceLock.asked, 1);

      answerEmptyVaults(fakes);
      await tester.pumpAndSettle();

      expect(find.text(VaultCopy.lockedTitle), findsNothing);
      expect(find.text(VaultCopy.vaultOf('Kid Parker')), findsOneWidget);
    });

    testWidgets('stays shut on a phone with no screen lock, and says what to '
        'do', (tester) async {
      fakes.deviceLock.outcome = UnlockOutcome.noScreenLock;
      await openVault(tester, vaultPath);

      expect(find.text(VaultCopy.lockedTitle), findsOneWidget);
      expect(find.text(VaultCopy.noScreenLock), findsOneWidget);
      expect(fakes.vaults.watchedVaults, isEmpty);
    });

    testWidgets('backing out of the prompt leaves the lock screen quiet, with '
        'a way to try again', (tester) async {
      fakes.deviceLock.outcome = UnlockOutcome.cancelled;
      await openVault(tester, vaultPath);

      expect(find.text(VaultCopy.lockUnavailable), findsNothing);
      fakes.deviceLock.outcome = UnlockOutcome.unlocked;
      await tester.tap(find.text(VaultCopy.unlock));
      await letItOpen(tester);
      expect(find.text(VaultCopy.lockedTitle), findsNothing);
    });

    testWidgets('the lock button shuts the vaults again', (tester) async {
      await openVault(tester, vaultPath);
      answerEmptyVaults(fakes);
      await tester.pumpAndSettle();
      fakes.deviceLock.outcome = UnlockOutcome.cancelled;

      await tester.tap(find.bySemanticsLabel(VaultCopy.lockNow));
      await tester.pumpAndSettle();

      expect(find.text(VaultCopy.lockedTitle), findsOneWidget);
      expect(fakes.vaults.watchedVaults, isEmpty);
    });
  });

  group('the vault home', () {
    testWidgets('holds its layout while the vaults load', (tester) async {
      await openVault(tester, vaultPath);
      expect(find.text(VaultCopy.homeTitle), findsOneWidget);
      expect(find.text(VaultCopy.homeEmptyTitle), findsNothing);
    });

    testWidgets('shows a folder per person, with what needs renewing on top', (
      tester,
    ) async {
      await openVault(tester, vaultPath);
      answerEmptyVaults(fakes);
      fakes.vaults.emitVault('m-kid', [
        vaultDocument('passport', expiresOn: today().addDays(10)),
      ]);
      await tester.pumpAndSettle();

      expect(find.text(VaultCopy.expiringTitle), findsWidgets);
      expect(find.text(VaultCopy.expiresIn(10)), findsOneWidget);
      expect(find.text(VaultCopy.vaultOf('Sam Parent')), findsOneWidget);
      expect(find.text(VaultCopy.vaultOf('Thandi Helper')), findsOneWidget);
    });

    testWidgets('says when no vault is open to this person', (tester) async {
      // Somebody who has claimed no profile and is not an admin.
      await pumpDocuments(
        tester,
        fakes: fakes,
        location: vaultPath,
        view: Fixtures.view(viewerUid: 'uid-nobody'),
        viewerUid: 'uid-nobody',
      );
      await letItOpen(tester);
      for (final owner in ['m-sam', 'm-thandi', 'm-kid']) {
        fakes.vaults.emitGrantTo(owner, isGranted: false);
      }
      await tester.pumpAndSettle();

      expect(find.text(VaultCopy.homeEmptyTitle), findsOneWidget);
    });

    testWidgets('a vault that cannot be read offers a retry, never a code', (
      tester,
    ) async {
      await openVault(tester, vaultPath);
      fakes.vaults.failVault('m-kid', const PermissionDeniedFailure());
      await tester.pumpAndSettle();

      expect(find.text(AppCopy.retry), findsOneWidget);
      expect(find.textContaining('permission'), findsNothing);
    });

    testWidgets('renders in dark and at 200% text without overflowing', (
      tester,
    ) async {
      onASmallPhone(tester);
      await pumpDocuments(
        tester,
        fakes: fakes,
        location: vaultPath,
        brightness: Brightness.dark,
        textScale: 2,
      );
      await letItOpen(tester);
      answerEmptyVaults(fakes);
      fakes.vaults.emitVault('m-kid', [
        vaultDocument('passport', expiresOn: today()),
      ]);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('one person\'s vault', () {
    testWidgets('an empty vault still offers the way to fill it', (
      tester,
    ) async {
      await openVault(tester, kidVault);
      answerEmptyVaults(fakes);
      await tester.pumpAndSettle();

      expect(find.text(VaultCopy.personEmptyTitle), findsOneWidget);
      expect(find.bySemanticsLabel(AppCopy.documentsAdd), findsOneWidget);
      expect(find.bySemanticsLabel(VaultCopy.accessTitle), findsOneWidget);
    });

    testWidgets('lists what is in it with its expiry and tags', (tester) async {
      await openVault(tester, kidVault);
      answerEmptyVaults(fakes);
      fakes.vaults.emitVault('m-kid', [
        vaultDocument(
          'passport',
          name: 'Emma passport',
          tags: const ['Travel'],
          expiresOn: today().addDays(-2),
        ),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Emma passport'), findsOneWidget);
      expect(find.text(VaultCopy.expired), findsOneWidget);
      expect(find.text('Travel'), findsOneWidget);
      expect(find.text(VaultCopy.opensAreLogged), findsOneWidget);
    });

    testWidgets('opening one asks the server first, then draws its pages', (
      tester,
    ) async {
      await openVault(tester, kidVault);
      answerEmptyVaults(fakes);
      fakes.vaults.emitVault('m-kid', [vaultDocument('passport')]);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Passport'));
      await tester.pumpAndSettle();

      expect(fakes.directory.opened.single.documentId, 'passport');
      expect(fakes.vaultStore.reads, ['passport']);
      expect(fakes.renderer.renders, 1);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('a refused open shows the reason in words', (tester) async {
      fakes.directory.failOpenWith = const DocumentFailure(
        DocumentProblem.vaultNotShared,
      );
      await openVault(tester, kidVault);
      answerEmptyVaults(fakes);
      fakes.vaults.emitVault('m-kid', [vaultDocument('passport')]);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Passport'));
      await tester.pumpAndSettle();

      expect(
        find.text(AppCopy.documentProblem(DocumentProblem.vaultNotShared)),
        findsOneWidget,
      );
      expect(fakes.vaultStore.reads, isEmpty);
    });

    testWidgets('a scan is shown back to check, named, and then filed', (
      tester,
    ) async {
      await openVault(tester, kidVault);
      answerEmptyVaults(fakes);
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel(AppCopy.documentsAdd));
      await tester.pumpAndSettle();
      await tester.tap(find.text(VaultCopy.scan));
      await tester.pumpAndSettle();

      expect(find.text(VaultCopy.reviewTitle), findsOneWidget);
      expect(find.text(VaultCopy.side(0)), findsOneWidget);
      expect(find.text(VaultCopy.side(1)), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Emma passport');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(VaultCopy.saveToVault));
      await tester.tap(find.text(VaultCopy.saveToVault));
      await tester.pumpAndSettle();
      await fakes.vaultStore.nextUpload!.finish();
      await tester.pumpAndSettle();

      expect(fakes.composer.composed, [2]);
      expect(fakes.vaults.added.single.name, 'Emma passport');
      expect(fakes.vaults.added.single.ownerMemberId, Fixtures.kidMemberId);
    });

    testWidgets('sharing is a switch per person who has joined', (
      tester,
    ) async {
      await openVault(tester, kidVault);
      answerEmptyVaults(fakes);
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel(VaultCopy.accessTitle));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(fakes.vaults.granted.single.granteeUid, Fixtures.thandiUid);

      fakes.vaults.emitGrants('m-kid', [
        const VaultGrant(
          id: Fixtures.thandiUid,
          memberId: Fixtures.thandiMemberId,
          grantedBy: Fixtures.samMemberId,
        ),
      ]);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(fakes.vaults.revoked.single.granteeUid, Fixtures.thandiUid);
    });

    testWidgets('a vault shared with a helper is read-only to her', (
      tester,
    ) async {
      await pumpDocuments(
        tester,
        fakes: fakes,
        location: kidVault,
        view: Fixtures.view(viewerUid: Fixtures.thandiUid),
        viewerUid: Fixtures.thandiUid,
      );
      await letItOpen(tester);
      fakes.vaults.emitVault('m-thandi', []);
      fakes.vaults.emitGrants('m-thandi', []);
      fakes.vaults.emitGrantTo('m-sam', isGranted: false);
      fakes.vaults.emitGrantTo('m-kid', isGranted: true);
      await letItOpen(tester);
      fakes.vaults.emitVault('m-kid', [vaultDocument('passport')]);
      await tester.pumpAndSettle();

      expect(find.text(VaultCopy.readOnlyNote), findsOneWidget);
      expect(find.bySemanticsLabel(AppCopy.documentsAdd), findsNothing);
      expect(find.bySemanticsLabel(VaultCopy.accessTitle), findsNothing);
    });

    testWidgets('renders in dark and at 200% text without overflowing', (
      tester,
    ) async {
      onASmallPhone(tester);
      await pumpDocuments(
        tester,
        fakes: fakes,
        location: kidVault,
        brightness: Brightness.dark,
        textScale: 2,
      );
      await letItOpen(tester);
      answerEmptyVaults(fakes);
      fakes.vaults.emitVault('m-kid', [
        vaultDocument(
          'passport',
          name: 'Emma\'s passport, renewed at the Home Affairs office',
          tags: const ['Travel', 'ID'],
          expiresOn: today().addDays(12),
        ),
      ]);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('the lock screen renders in dark and at 200% text', (
    tester,
  ) async {
    onASmallPhone(tester);
    fakes.deviceLock.outcome = UnlockOutcome.lockedOut;
    await pumpDocuments(
      tester,
      fakes: fakes,
      location: vaultPath,
      brightness: Brightness.dark,
      textScale: 2,
    );
    await letItOpen(tester);

    expect(tester.takeException(), isNull);
    expect(find.text(VaultCopy.lockedOut), findsOneWidget);
  });
}
