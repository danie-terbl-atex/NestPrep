import '../model/premium_voucher.dart';
import '../model/voucher_claim.dart';

abstract interface class PremiumVoucherDirectory {
  Future<List<PremiumVoucher>> vouchersForMe();

  Future<VoucherClaim> claim({
    required String voucherId,
    required String householdId,
  });

  Future<String> sendEmailCode(String email);

  Future<String> verifyEmailCode({required String email, required String code});
}
