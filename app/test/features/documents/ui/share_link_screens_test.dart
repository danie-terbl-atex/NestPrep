import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/documents_route.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/nanny_hub/model/shift.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_document_tools.dart';
import '../../../support/fake_vault.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_documents.dart';

/// Sharing one document by a link, through the real Documents shell over
/// fakes (documents ADR-0006): the way in from Documents, the share sheet on
/// a vault document, the link shown once, and the list of live links.
void main() {
  late DocumentsFakes fakes;
  final documentsPath = DocumentsRoute.pathFor(Fixtures.householdId);
  final sharesPath = DocumentsRoute.sharesPathFor(Fixtures.householdId);
  final kidVault = DocumentsRoute.vaultPersonPathFor(
    Fixtures.householdId,
    Fixtures.kidMemberId,
  );

  setUp(() => fakes = DocumentsFakes());
  tearDown(() => fakes.close());

  Future<void> tapOn(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openKidDocument(
    WidgetTester tester, {
    String name = 'Card',
  }) async {
    await pumpDocuments(tester, fakes: fakes, location: kidVault);
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    answerEmptyVaults(fakes);
    fakes.vaults.emitVault('m-kid', [vaultDocument('card', name: name)]);
    await tester.pumpAndSettle();
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
  }

  group('the way in', () {
    testWidgets('Documents offers Shared links and Offline copies while they '
        'are switched on', (tester) async {
      await pumpDocuments(tester, fakes: fakes, location: documentsPath);
      answerLibrary(fakes);
      await tester.pumpAndSettle();

      expect(find.text(ShareLinkCopy.listEntry), findsOneWidget);
      expect(find.text(OfflineCopiesCopy.entry), findsOneWidget);

      await tester.ensureVisible(find.text(ShareLinkCopy.listEntry));
      await tester.tap(find.text(ShareLinkCopy.listEntry));
      await tester.pump();
      fakes.shares.emit([]);
      await tester.pumpAndSettle();
      expect(find.text(ShareLinkCopy.listBody), findsOneWidget);
    });

    testWidgets('and neither in a build where they are switched off', (
      tester,
    ) async {
      await pumpDocuments(
        tester,
        fakes: fakes,
        location: documentsPath,
        flagsDefaultOn: false,
      );
      answerLibrary(fakes);
      await tester.pumpAndSettle();

      expect(find.text(ShareLinkCopy.listEntry), findsNothing);
      expect(find.text(OfflineCopiesCopy.entry), findsNothing);
    });

    testWidgets('a switch turned off while somebody looks takes its way in '
        'away', (tester) async {
      await pumpDocuments(tester, fakes: fakes, location: documentsPath);
      answerLibrary(fakes);
      await tester.pumpAndSettle();

      fakes.flagSource.emit({'documentShareLinks': false});
      await tester.pumpAndSettle();

      expect(find.text(ShareLinkCopy.listEntry), findsNothing);
      expect(find.text(OfflineCopiesCopy.entry), findsOneWidget);
    });
  });

  group('the share sheet', () {
    testWidgets('makes a link for a day and shows it once, to send or copy', (
      tester,
    ) async {
      await openKidDocument(tester);
      await tapOn(tester, find.text(ShareLinkCopy.shareAction));
      expect(find.text(ShareLinkCopy.sheetBody), findsOneWidget);

      await tapOn(tester, find.text(ShareLinkCopy.create));

      final request = fakes.shareDirectory.created.single;
      expect(request.ownerMemberId, Fixtures.kidMemberId);
      expect(request.documentId, 'card');
      expect(request.pin, isNull);
      expect(find.text(ShareLinkCopy.readyTitle), findsWidgets);
      expect(find.textContaining('documentShare?t=abc123'), findsOneWidget);

      await tapOn(tester, find.text(ShareLinkCopy.send));
      expect(fakes.sharer.sent.single.text, contains('documentShare?t=abc123'));
    });

    testWidgets('with a PIN, and until the shift that is on now ends', (
      tester,
    ) async {
      await openKidDocument(tester);
      await tapOn(tester, find.text(ShareLinkCopy.shareAction));
      fakes.shifts.openShifts.add([
        const Shift(
          id: 'shift-1',
          carerMemberId: Fixtures.thandiMemberId,
          startedBy: Fixtures.samMemberId,
        ),
      ]);
      await tester.pumpAndSettle();

      await tapOn(
        tester,
        find.text(ShareLinkCopy.untilShiftEnds('Thandi Helper')),
      );
      expect(find.text(ShareLinkCopy.shiftNote), findsOneWidget);
      await tapOn(tester, find.text(ShareLinkCopy.pinToggle));
      await tester.enterText(find.byType(TextField).last, '2468');
      await tester.pumpAndSettle();
      await tapOn(tester, find.text(ShareLinkCopy.create));

      final request = fakes.shareDirectory.created.single;
      expect(request.pin, '2468');
      expect(find.text(ShareLinkCopy.endsWithShift), findsOneWidget);
      expect(find.text(ShareLinkCopy.withPinReminder), findsWidgets);
    });

    testWidgets('an ID document asks twice, and backing out makes nothing', (
      tester,
    ) async {
      await openKidDocument(tester, name: 'Kid passport');
      await tapOn(tester, find.text(ShareLinkCopy.shareAction));
      expect(find.text(ShareLinkCopy.identityBody), findsOneWidget);

      await tapOn(tester, find.text(ShareLinkCopy.create));
      expect(find.text(ShareLinkCopy.identityTitle), findsOneWidget);
      await tapOn(tester, find.text(AppCopy.householdCancel));
      expect(fakes.shareDirectory.created, isEmpty);

      await tapOn(tester, find.text(ShareLinkCopy.create));
      await tapOn(tester, find.text(ShareLinkCopy.identityConfirm));
      expect(fakes.shareDirectory.created, hasLength(1));
    });

    testWidgets(
      'a refusal is said in words, and the sheet stays to try again',
      (tester) async {
        fakes.shareDirectory.failWith = const DocumentFailure(
          DocumentProblem.tooManyShares,
        );
        await openKidDocument(tester);
        await tapOn(tester, find.text(ShareLinkCopy.shareAction));
        await tapOn(tester, find.text(ShareLinkCopy.create));

        expect(
          find.text(ShareLinkCopy.problem(DocumentProblem.tooManyShares)),
          findsOneWidget,
        );
        expect(find.text(ShareLinkCopy.create), findsOneWidget);
      },
    );

    testWidgets('a vault shared with a helper to read is not hers to send', (
      tester,
    ) async {
      await pumpDocuments(
        tester,
        fakes: fakes,
        location: kidVault,
        view: Fixtures.helperView(
          AccessGrant.uniform(AccessLevel.none)
              .withLevel(HouseholdArea.documents, AccessLevel.edit),
        ),
        viewerUid: Fixtures.thandiUid,
      );
      for (var frame = 0; frame < 6; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      fakes.vaults.emitVault(Fixtures.thandiMemberId, []);
      fakes.vaults.emitGrants(Fixtures.thandiMemberId, []);
      fakes.vaults.emitGrantTo(Fixtures.samMemberId, isGranted: false);
      fakes.vaults.emitGrantTo(Fixtures.kidMemberId, isGranted: true);
      // The kid's vault is listened to once the grant has arrived.
      await tester.pump();
      fakes.vaults.emitVault('m-kid', [vaultDocument('card', name: 'Card')]);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Card'));
      await tester.pumpAndSettle();

      expect(find.text(ShareLinkCopy.shareAction), findsNothing);
      expect(find.text(OfflineCopiesCopy.keep), findsOneWidget);
    });
  });

  group('the live links', () {
    Future<void> openList(WidgetTester tester) async {
      await pumpDocuments(tester, fakes: fakes, location: sharesPath);
      await tester.pump();
    }

    testWidgets('holds its layout while they load', (tester) async {
      await openList(tester);
      expect(find.text(ShareLinkCopy.listTitle), findsOneWidget);
      expect(find.text(ShareLinkCopy.emptyTitle), findsNothing);
    });

    testWidgets('says what to do when nothing is shared', (tester) async {
      await openList(tester);
      fakes.shares.emit([]);
      await tester.pumpAndSettle();
      expect(find.text(ShareLinkCopy.emptyTitle), findsOneWidget);
      expect(find.text(ShareLinkCopy.emptyBody), findsOneWidget);
    });

    testWidgets('shows each link — its PIN, its opens, who made it — and '
        'stops one after asking', (tester) async {
      await openList(tester);
      fakes.shares.emit([
        aShare('s1', hasPin: true, openCount: 2),
        aShare('s2', documentName: 'Car insurance', ownerMemberId: null),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Medical aid card'), findsOneWidget);
      expect(find.text(ShareLinkCopy.withPin), findsOneWidget);
      expect(find.textContaining(ShareLinkCopy.opened(2)), findsOneWidget);
      expect(
        find.textContaining(ShareLinkCopy.madeBy('Sam Parent')),
        findsWidgets,
      );

      await tapOn(
        tester,
        find.bySemanticsLabel(ShareLinkCopy.stopLabel('Car insurance')),
      );
      expect(find.text(ShareLinkCopy.stopTitle), findsOneWidget);
      await tapOn(tester, find.text(ShareLinkCopy.stop));
      expect(fakes.shareDirectory.revoked, ['s2']);
    });

    testWidgets('a list that cannot be read offers a retry, never a code', (
      tester,
    ) async {
      await openList(tester);
      fakes.shares.fail(const PermissionDeniedFailure());
      await tester.pumpAndSettle();
      expect(find.text(AppCopy.retry), findsOneWidget);
    });

    testWidgets('renders in dark and at 200% text without overflowing', (
      tester,
    ) async {
      onASmallPhone(tester);
      await pumpDocuments(
        tester,
        fakes: fakes,
        location: sharesPath,
        brightness: Brightness.dark,
        textScale: 2,
      );
      fakes.shares.emit([
        aShare('s1', hasPin: true, openCount: 3, shiftId: 'shift-1'),
        aShare('s2', documentName: 'A very long name for the car insurance'),
      ]);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
