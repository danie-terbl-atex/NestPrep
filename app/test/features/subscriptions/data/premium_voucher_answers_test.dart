import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/subscriptions/data/callable_premium_voucher_directory.dart';
import 'package:nestprep/features/subscriptions/model/premium_voucher.dart';
import 'package:nestprep/features/subscriptions/model/premium_voucher_kind.dart';
import 'package:nestprep/features/subscriptions/model/voucher_claim.dart';

/// The voucher callables' answers, parsed rather than cast (`ENG-09`,
/// subscriptions ADR-0003): an answer of the wrong shape is a Function newer
/// or older than this build, and is dropped rather than crashing.
void main() {
  group('a voucher in premiumVouchersForMe', () {
    test('reads every field the contract names', () {
      expect(
        CallablePremiumVoucherDirectory.voucherFrom({
          'voucherId': 'order1_1',
          'kind': 'frame',
          'days': 93,
          'sku': 'frame-15',
          'emailMasked': 's***@gmail.com',
          'isTest': true,
        }),
        const PremiumVoucher(
          voucherId: 'order1_1',
          kind: PremiumVoucherKind.frame,
          days: 93,
          sku: 'frame-15',
          emailMasked: 's***@gmail.com',
          isTest: true,
        ),
      );
      expect(
        CallablePremiumVoucherDirectory.voucherFrom({
          'voucherId': 'g1',
          'kind': 'code',
          'days': 30.0,
          'sku': null,
          'emailMasked': 'p***@icloud.com',
        }),
        const PremiumVoucher(
          voucherId: 'g1',
          kind: PremiumVoucherKind.code,
          days: 30,
          emailMasked: 'p***@icloud.com',
        ),
      );
    });

    test('drops a kind this build does not know, and a broken shape', () {
      for (final entry in <Object?>[
        {'voucherId': 'x', 'kind': 'partner', 'days': 30, 'emailMasked': 'a'},
        {'voucherId': 'x', 'kind': 'frame', 'days': 0, 'emailMasked': 'a'},
        {'voucherId': 'x', 'kind': 'frame', 'emailMasked': 'a'},
        {'kind': 'frame', 'days': 31, 'emailMasked': 'a'},
        'not a map',
        null,
      ]) {
        expect(CallablePremiumVoucherDirectory.voucherFrom(entry), isNull);
      }
    });
  });

  group('the answer to claimPremiumVoucher', () {
    test('reads a grant that starts now', () {
      expect(
        CallablePremiumVoucherDirectory.claimFrom({
          'grantId': 'g1',
          'days': 93,
          'startsAt': '2026-11-03T08:00:00.000Z',
          'queued': false,
        }),
        const VoucherClaim(grantId: 'g1', queued: false),
      );
    });

    test('reads a queued grant with no start yet', () {
      expect(
        CallablePremiumVoucherDirectory.claimFrom({
          'grantId': 'g2',
          'days': 30,
          'startsAt': null,
          'queued': true,
        }),
        const VoucherClaim(grantId: 'g2', queued: true),
      );
    });

    test('is nothing when the shape is wrong', () {
      expect(
        CallablePremiumVoucherDirectory.claimFrom({'grantId': 'g3'}),
        isNull,
      );
    });
  });
}
