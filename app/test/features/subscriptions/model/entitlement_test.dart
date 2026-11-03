import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/subscriptions/model/entitlement_status.dart';
import 'package:nestprep/features/subscriptions/model/grant_days_waiting.dart';
import 'package:nestprep/features/subscriptions/model/grant_source.dart';
import 'package:nestprep/features/subscriptions/model/premium_length.dart';
import 'package:nestprep/features/subscriptions/model/premium_voucher.dart';
import 'package:nestprep/features/subscriptions/model/premium_voucher_kind.dart';

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

  group('given time by source (subscriptions ADR-0003)', () {
    final at = DateTime.utc(2026, 12, 2);

    test('reads the new fields when the server writes them', () {
      final read = Entitlement.fromJson({
        'referralUntil': Timestamp.fromDate(at),
        'referralDaysWaiting': 153,
        'grantUntil': Timestamp.fromDate(at),
        'grantDaysWaiting': {'referral': 30, 'frame': 93, 'code': 30},
      });
      expect(read.givenUntil, at);
      expect(
        read.daysWaiting,
        const GrantDaysWaiting(referral: 30, frame: 93, code: 30),
      );
      expect(read.daysWaiting.total, read.referralDaysWaiting);
    });

    test('falls back to the referral fields an older server writes', () {
      final read = Entitlement.fromJson({
        'referralUntil': Timestamp.fromDate(at),
        'referralDaysWaiting': 60,
      });
      expect(read.grantUntil, isNull);
      expect(read.givenUntil, at);
      expect(read.daysWaiting, const GrantDaysWaiting(referral: 60));
      expect(read.lengthWaiting(GrantSource.referral), const PremiumMonths(2));
      expect(read.lengthWaiting(GrantSource.frame), const PremiumMonths(0));
    });

    test('a key the server leaves out of grantDaysWaiting reads as none', () {
      final read = Entitlement.fromJson({
        'grantDaysWaiting': {'frame': 62},
      });
      expect(read.daysWaiting, const GrantDaysWaiting(frame: 62));
    });

    test('never counts frame or gifted time as referral time', () {
      const waiting = Entitlement(
        referralDaysWaiting: 123,
        grantDaysWaiting: GrantDaysWaiting(frame: 93, code: 30),
      );
      expect(waiting.daysWaiting.referral, 0);
      expect(waiting.lengthWaiting(GrantSource.frame), const PremiumMonths(3));
      expect(waiting.lengthWaiting(GrantSource.code), const PremiumDays(30));
    });

    test('knows paid time from given time', () {
      final paid = Entitlement(storeUntil: at);
      expect(paid.isPaidAt(at.subtract(const Duration(days: 1))), isTrue);
      expect(paid.isPaidAt(at), isFalse);
      expect(Entitlement.free.isPaidAt(at), isFalse);
    });
  });

  group('how long Premium reads', () {
    test('frame time is whole 31-day months, or days when not whole', () {
      expect(PremiumLength.of(GrantSource.frame, 93), const PremiumMonths(3));
      expect(PremiumLength.of(GrantSource.frame, 62), const PremiumMonths(2));
      expect(PremiumLength.of(GrantSource.frame, 31), const PremiumMonths(1));
      expect(PremiumLength.of(GrantSource.frame, 90), const PremiumDays(90));
      expect(PremiumLength.of(GrantSource.frame, 124), const PremiumMonths(4));
    });

    test('93 frame days is never four months', () {
      expect(
        PremiumLength.of(GrantSource.frame, 93),
        isNot(const PremiumMonths(4)),
      );
    });

    test('referral time keeps its 30-day month, a part rounded up', () {
      expect(
        PremiumLength.of(GrantSource.referral, 30),
        const PremiumMonths(1),
      );
      expect(
        PremiumLength.of(GrantSource.referral, 60),
        const PremiumMonths(2),
      );
      expect(
        PremiumLength.of(GrantSource.referral, 31),
        const PremiumMonths(2),
      );
    });

    test('gifted time is always days', () {
      expect(PremiumLength.of(GrantSource.code, 30), const PremiumDays(30));
      expect(PremiumLength.of(GrantSource.code, 31), const PremiumDays(31));
    });

    test('a voucher reads by its own kind', () {
      const frame = PremiumVoucher(
        voucherId: 'o_1',
        kind: PremiumVoucherKind.frame,
        days: 62,
        emailMasked: 's***@gmail.com',
      );
      expect(frame.length, const PremiumMonths(2));
      expect(
        frame.copyWith(kind: PremiumVoucherKind.code).length,
        const PremiumDays(62),
      );
    });
  });
}
