import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/documents/model/share_lifetime.dart';
import 'package:nestprep/features/documents/model/share_target.dart';
import 'package:nestprep/features/documents/state/document_shares_controller.dart';
import 'package:nestprep/features/documents/state/share_link_composer.dart';
import 'package:nestprep/features/nanny_hub/model/shift.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_document_tools.dart';
import '../../../support/fake_nanny_shifts.dart';
import '../../../support/household_fixtures.dart';

/// Sharing one document by a link (documents ADR-0006): the sheet's choices
/// and the one request it makes, and the list of live links with the way to
/// stop each.
void main() {
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  const card = ShareTarget(
    householdId: Fixtures.householdId,
    ownerMemberId: Fixtures.kidMemberId,
    documentId: 'card',
    name: 'Kid medical aid card',
    tags: [],
  );

  group('the share sheet', () {
    late FakeDocumentShareDirectory directory;
    late FakeShiftRepository shifts;

    setUp(() {
      directory = FakeDocumentShareDirectory();
      shifts = FakeShiftRepository();
    });

    ShareLinkComposer composer({ShareTarget target = card}) {
      final made = ShareLinkComposer(
        directory: directory,
        target: target,
        shifts: shifts,
        members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
      );
      addTearDown(made.dispose);
      return made;
    }

    test('suggests a day, with no PIN', () {
      final sheet = composer();
      expect(sheet.lifetime, const HoursLifetime(24));
      expect(sheet.asksForPin, isFalse);
      expect(sheet.canCreate, isTrue);
    });

    test('offers each open shift by its carer\'s name', () async {
      final sheet = composer();
      shifts.openShifts.add([
        const Shift(
          id: 'shift-1',
          carerMemberId: Fixtures.thandiMemberId,
          startedBy: Fixtures.samMemberId,
        ),
      ]);
      await settle();

      expect(sheet.shiftOptions.single.carerName, 'Thandi Helper');
      sheet.chooseLifetime(sheet.shiftOptions.single);
      await sheet.create();
      expect(directory.created.single.lifetime, sheet.shiftOptions.single);
    });

    test('a chosen shift that ends while the sheet is open is no longer the '
        'choice', () async {
      final sheet = composer();
      const shift = Shift(
        id: 'shift-1',
        carerMemberId: Fixtures.thandiMemberId,
        startedBy: Fixtures.samMemberId,
      );
      shifts.openShifts.add([shift]);
      await settle();
      sheet.chooseLifetime(sheet.shiftOptions.single);

      shifts.openShifts.add([]);
      await settle();

      expect(sheet.lifetime, ShareLifetime.suggested);
    });

    test('a PIN must be 4 to 8 digits before a link is made', () async {
      final sheet = composer()..setAsksForPin(true);
      expect(sheet.canCreate, isFalse);
      expect(sheet.showsPinProblem, isFalse, reason: 'nothing typed yet');

      sheet.setPin('12');
      expect(sheet.showsPinProblem, isTrue);
      await sheet.create();
      expect(directory.created, isEmpty);

      sheet.setPin('2468');
      await sheet.create();
      expect(directory.created.single.pin, '2468');
      expect(sheet.link, isNotNull);
    });

    test('turning the PIN off sends none, whatever was typed', () async {
      final sheet = composer()
        ..setAsksForPin(true)
        ..setPin('2468')
        ..setAsksForPin(false);
      await sheet.create();
      expect(directory.created.single.pin, isNull);
    });

    test('an ID document is recognised for the second look', () {
      expect(composer().isIdentityDocument, isFalse);
      expect(
        composer(
          target: const ShareTarget(
            householdId: Fixtures.householdId,
            ownerMemberId: Fixtures.kidMemberId,
            documentId: 'p',
            name: 'Kid passport',
            tags: [],
          ),
        ).isIdentityDocument,
        isTrue,
      );
    });

    test('makes one link at a time', () async {
      final sheet = composer();
      directory.holdCreate = Completer<void>();
      final first = sheet.create();
      await sheet.create();
      expect(sheet.isCreating, isTrue);
      directory.holdCreate!.complete();
      await first;
      expect(directory.created, hasLength(1));
      expect(sheet.canCreate, isFalse, reason: 'the link is made');
    });

    test(
      'a refusal is kept as copy for the sheet, and it can try again',
      () async {
        final sheet = composer();
        directory.failWith = const DocumentFailure(
          DocumentProblem.tooManyShares,
        );
        await sheet.create();
        expect(sheet.failure, isA<DocumentFailure>());
        expect(sheet.link, isNull);
        expect(sheet.canCreate, isTrue);
      },
    );
  });

  group('the live links', () {
    late FakeDocumentShareRepository repository;
    late FakeDocumentShareDirectory directory;
    final now = DateTime.utc(2026, 9, 29, 12);

    setUp(() {
      repository = FakeDocumentShareRepository();
      directory = FakeDocumentShareDirectory();
    });
    tearDown(() => repository.close());

    DocumentSharesController list({bool isFamily = true}) {
      final made = DocumentSharesController(
        repository: repository,
        directory: directory,
        householdId: Fixtures.householdId,
        viewerUid: Fixtures.thandiUid,
        isFamily: isFamily,
        now: () => now,
      );
      addTearDown(made.dispose);
      return made;
    }

    test('asks for the whole household for the family, only their own '
        'otherwise', () {
      list();
      list(isFamily: false);
      expect(repository.asked, [
        (isFamily: true, viewerUid: Fixtures.thandiUid),
        (isFamily: false, viewerUid: Fixtures.thandiUid),
      ]);
    });

    test(
      'shows what is live, dropping what ran out since it was asked',
      () async {
        final links = list();
        expect(links.shares, isA<AsyncLoading<Object?>>());
        repository.emit([
          aShare('live', expiresAt: now.add(const Duration(hours: 1))),
          aShare('gone', expiresAt: now.subtract(const Duration(minutes: 1))),
        ]);
        await settle();

        final shown = switch (links.shares) {
          AsyncData(:final value) => value.map((share) => share.id).toList(),
          _ => const <String>[],
        };
        expect(shown, ['live']);
      },
    );

    test('a failed read is an error state with a retry', () async {
      final links = list();
      repository.fail(const PermissionDeniedFailure());
      await settle();
      expect(links.shares, isA<AsyncFailure<Object?>>());

      await links.retry();
      expect(links.shares, isA<AsyncLoading<Object?>>());
    });

    test('stops a link once, and keeps a refusal for the screen', () async {
      final links = list();
      await links.stop(aShare('s1'));
      expect(directory.revoked, ['s1']);
      expect(links.isStopping('s1'), isFalse);

      directory.failWith = const UnavailableFailure();
      await links.stop(aShare('s2'));
      expect(links.actionFailure, isA<UnavailableFailure>());
    });
  });
}
