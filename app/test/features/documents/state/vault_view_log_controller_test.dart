import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/documents/model/vault_view.dart';
import 'package:nestprep/features/documents/state/vault_view_log_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_vault.dart';
import '../../../support/household_fixtures.dart';

/// The view log (documents ADR-0003): an admin reads every vault's, anybody
/// else their own, merged newest first.
void main() {
  late FakeVaultRepository repository;

  setUp(() => repository = FakeVaultRepository());
  tearDown(() => repository.close());

  VaultViewLogController build({
    required bool isFamily,
    String viewer = 'm-sam',
  }) => VaultViewLogController(
    vaultRepository: repository,
    householdId: Fixtures.householdId,
    members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
    viewerMemberId: viewer,
    isFamily: isFamily,
  );

  VaultView view(String id, DateTime? at) => VaultView(
    id: id,
    documentId: 'passport',
    documentName: 'Passport',
    viewerMemberId: 'm-sam',
    viewedAt: at,
  );

  test('an admin reads every vault\'s log, newest first', () async {
    final controller = build(isFamily: true);
    expect(controller.owners, ['m-sam', 'm-thandi', 'm-kid']);

    repository.emitViews('m-sam', [view('a', DateTime.utc(2027, 6, 1, 9))]);
    repository.emitViews('m-thandi', []);
    repository.emitViews('m-kid', [
      view('b', DateTime.utc(2027, 6, 1, 10)),
      view('c', null),
    ]);
    await pumpEventQueue();

    final log = (controller.log as AsyncData<List<VaultView>>).value;
    expect([for (final entry in log) entry.id], ['c', 'b', 'a']);
    expect(log.first.ownerMemberId, 'm-kid');
    controller.dispose();
  });

  test('anybody else reads only who opened their own vault', () {
    final controller = build(isFamily: false, viewer: 'm-thandi');
    expect(controller.owners, ['m-thandi']);
    controller.dispose();
  });

  test('somebody with no profile of their own has an empty log, not a '
      'spinner', () {
    final controller = build(isFamily: false, viewer: '');
    expect(controller.log, isA<AsyncData<List<VaultView>>>());
    controller.dispose();
  });

  test('a refusal is shown as one, with a way to try again', () async {
    final controller = build(isFamily: false, viewer: 'm-thandi');
    repository.failViews('m-thandi', const PermissionDeniedFailure());
    await pumpEventQueue();
    expect(controller.log, isA<AsyncFailure<List<VaultView>>>());

    await controller.retry();
    repository.emitViews('m-thandi', []);
    await pumpEventQueue();
    expect(controller.log, isA<AsyncData<List<VaultView>>>());
    controller.dispose();
  });
}
