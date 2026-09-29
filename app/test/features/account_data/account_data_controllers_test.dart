import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/account_data/model/account_export.dart';
import 'package:nestprep/features/account_data/model/deletion_preview.dart';
import 'package:nestprep/features/account_data/state/account_deletion_controller.dart';
import 'package:nestprep/features/account_data/state/account_export_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../support/fake_account_data.dart';

/// The two account-data controllers (accounts ADR-0006): what they allow,
/// what they send, and that neither ever sends twice (`FE-10`).
void main() {
  group('AccountDeletionController', () {
    late FakeAccountDataGateway gateway;
    late int signOuts;
    late AccountDeletionController controller;

    setUp(() async {
      gateway = FakeAccountDataGateway();
      signOuts = 0;
      controller = AccountDeletionController(
        accountDataGateway: gateway,
        signOut: () async => signOuts++,
      );
      await pumpEventQueue();
    });

    tearDown(() => controller.dispose());

    test('reads the preview on the way in', () {
      expect(controller.preview, isA<AsyncData<DeletionPreview>>());
      expect(gateway.previewCalls, 1);
    });

    test('keeps the button shut until DELETE is typed — in any case, spaces around it', () {
      expect(controller.canDelete, isFalse);
      controller.typeConfirmation('delet');
      expect(controller.canDelete, isFalse);
      controller.typeConfirmation('  delete ');
      expect(controller.canDelete, isTrue);
    });

    test(
      'sends the households it would end, then signs this phone out',
      () async {
        controller.typeConfirmation('DELETE');
        await controller.delete();
        expect(gateway.deletions, [
          ['h-gran'],
        ]);
        expect(signOuts, 1);
      },
    );

    test(
      'sends once, however often it is pressed while one is on its way',
      () async {
        controller.typeConfirmation('DELETE');
        gateway.deleteGate = Completer<void>();
        final first = controller.delete();
        expect(controller.isDeleting, isTrue);
        expect(controller.canDelete, isFalse);
        await controller.delete();
        gateway.deleteGate?.complete();
        await first;
        expect(gateway.deletions, hasLength(1));
      },
    );

    test('a refusal leaves the account signed in and says why', () async {
      controller.typeConfirmation('DELETE');
      gateway.deleteError = const UnavailableFailure();
      await controller.delete();
      expect(signOuts, 0);
      expect(controller.deleteFailure, isA<UnavailableFailure>());
      expect(controller.isDeleting, isFalse);
      expect(controller.canDelete, isTrue, reason: 'the person may try again');
    });

    test('a changed plan is read again and must be confirmed again', () async {
      controller.typeConfirmation('DELETE');
      gateway
        ..deleteError = const AccountDataFailure(
          AccountDataProblem.deletionPlanChanged,
        )
        ..preview = AccountDataFixtures.nothing;
      await controller.delete();
      expect(gateway.previewCalls, 2);
      final preview = controller.preview;
      expect(
        preview is AsyncData<DeletionPreview> &&
            preview.value.households.isEmpty,
        isTrue,
      );
      expect(controller.isConfirmed, isFalse);
      expect(signOuts, 0);
    });

    test('a preview that cannot be read is the error state, and retry reads it again', () async {
      gateway.previewError = const UnavailableFailure();
      await controller.load();
      expect(controller.preview, isA<AsyncFailure<DeletionPreview>>());
      expect(controller.canDelete, isFalse);
      gateway.previewError = null;
      await controller.load();
      expect(controller.preview, isA<AsyncData<DeletionPreview>>());
    });
  });

  group('DeletionPreview', () {
    test('agrees to end exactly the households whose outcome is end', () {
      expect(AccountDataFixtures.handOverAndEnd.endingHouseholdIds, ['h-gran']);
      expect(AccountDataFixtures.nothing.endingHouseholdIds, isEmpty);
    });

    test('reads an outcome the server names, and nothing else', () {
      expect(
        HouseholdDeletionOutcome.fromName('handOver'),
        HouseholdDeletionOutcome.handOver,
      );
      expect(HouseholdDeletionOutcome.fromName('explode'), isNull);
    });
  });

  group('AccountExportController', () {
    late FakeAccountDataGateway gateway;
    late FakeExportSharer sharer;
    late AccountExportController controller;

    setUp(() {
      gateway = FakeAccountDataGateway();
      sharer = FakeExportSharer();
      controller = AccountExportController(
        accountDataGateway: gateway,
        exportSharer: sharer,
      );
    });

    tearDown(() => controller.dispose());

    test('starts idle, asking for nothing', () {
      expect(controller.export, isA<AsyncData<DownloadedExport?>>());
      expect(gateway.exports, 0);
    });

    test(
      'prepares once, however often it is pressed while it gathers',
      () async {
        gateway.exportGate = Completer<void>();
        final first = controller.prepare();
        expect(controller.isPreparing, isTrue);
        await controller.prepare();
        gateway.exportGate?.complete();
        await first;
        expect(gateway.exports, 1);
        final export = controller.export;
        expect(
          export is AsyncData<DownloadedExport?> && export.value != null,
          isTrue,
        );
      },
    );

    test('shares the file under its own name', () async {
      await controller.prepare();
      await controller.share();
      expect(sharer.shared, ['nestprep-my-data.json']);
      expect(controller.shareFailure, isNull);
    });

    test(
      'says so when the share sheet will not open, and keeps the file',
      () async {
        await controller.prepare();
        sharer.opens = false;
        await controller.share();
        expect(
          controller.shareFailure,
          const TypeMatcher<AccountDataFailure>().having(
            (failure) => failure.problem,
            'problem',
            AccountDataProblem.shareUnavailable,
          ),
        );
        expect(controller.export, isA<AsyncData<DownloadedExport?>>());
      },
    );

    test('a refused export is the error state — three an hour is the server’s rule', () async {
      gateway.exportError = const AccountDataFailure(
        AccountDataProblem.tooManyRequests,
      );
      await controller.prepare();
      expect(controller.export, isA<AsyncFailure<DownloadedExport?>>());
    });

    test('a download that fails after the export is written is the error state too', () async {
      gateway.downloadError = const NotFoundFailure();
      await controller.prepare();
      expect(controller.export, isA<AsyncFailure<DownloadedExport?>>());
    });
  });
}
