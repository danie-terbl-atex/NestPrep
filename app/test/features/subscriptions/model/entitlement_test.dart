import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/subscriptions/model/entitlement_status.dart';

/// The household's entitlement as the app reads it (subscriptions
/// ADR-0001): premium is the date alone, and a document from a newer server
/// is read rather than refused (`BE-10`).
void main() {
  group('Entitlement', () {
    final now = DateTime.utc(2026, 10, 5);

    test('a household with no document is free and has never lapsed', () {
      expect(Entitlement.free.isPremiumAt(now), isFalse);
      expect(Entitlement.free.hasLapsedAt(now), isFalse);
    });

    test('has lapsed once it bought and is no longer premium', () {
      final ended = Entitlement(
        premiumUntil: now.subtract(const Duration(days: 1)),
        status: EntitlementStatus.expired,
      );
      expect(ended.isPremiumAt(now), isFalse);
      expect(ended.hasLapsedAt(now), isTrue);
    });

    test('reads a status this build has never heard of as none, and keeps the date', () {
      final read = Entitlement.fromJson({
        'status': 'somethingNew',
        'plan': 'fortnightly',
        'store': 'webStore',
      });
      expect(read.status, EntitlementStatus.none);
      expect(read.plan, isNull);
      expect(read.store, isNull);
    });
  });
}
