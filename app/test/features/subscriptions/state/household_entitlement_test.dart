import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/subscriptions/model/entitlement_status.dart';
import 'package:nestprep/features/subscriptions/state/household_entitlement.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_subscriptions.dart';

/// The household's premium as the app sees it (subscriptions ADR-0001):
/// only what the entitlement document says, never a guess, and it ends at
/// its instant with nothing having to change.
void main() {
  late FakeEntitlementRepository repository;
  var now = DateTime.utc(2026, 10, 5, 10);

  setUp(() {
    repository = FakeEntitlementRepository();
    now = DateTime.utc(2026, 10, 5, 10);
  });

  tearDown(() => repository.close());

  HouseholdEntitlement watching() {
    final entitlement = HouseholdEntitlement(
      entitlementRepository: repository,
      householdId: 'h1',
      now: () => now,
    );
    addTearDown(entitlement.dispose);
    return entitlement;
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('is not premium while it is still loading — the server decides', () {
    final entitlement = watching();
    expect(entitlement.entitlement, isA<AsyncLoading<Entitlement>>());
    expect(entitlement.isPremium, isFalse);
  });

  test('is premium until premiumUntil, and not a moment after', () async {
    final entitlement = watching();
    repository.emit(
      Entitlement(
        premiumUntil: now.add(const Duration(days: 30)),
        status: EntitlementStatus.active,
      ),
    );
    await settle();
    expect(entitlement.isPremium, isTrue);

    now = now.add(const Duration(days: 31));
    expect(entitlement.isPremium, isFalse);
  });

  test(
    'tells its listeners when premium runs out, with no document changing',
    () async {
      final entitlement = watching();
      repository.emit(
        Entitlement(
          premiumUntil: now.add(const Duration(milliseconds: 30)),
          status: EntitlementStatus.cancelled,
        ),
      );
      await settle();
      var told = 0;
      entitlement.addListener(() => told++);
      now = now.add(const Duration(seconds: 1));
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(told, 1);
      expect(entitlement.isPremium, isFalse);
    },
  );

  test(
    'a read that fails is a failure to show, with a retry that listens again',
    () async {
      final entitlement = watching();
      repository.fail(const PermissionDeniedFailure());
      await settle();
      expect(entitlement.entitlement, isA<AsyncFailure<Entitlement>>());

      entitlement.retry();
      repository.emit(Entitlement.free);
      await settle();
      expect(entitlement.entitlement, isA<AsyncData<Entitlement>>());
      expect(entitlement.isPremium, isFalse);
    },
  );
}
