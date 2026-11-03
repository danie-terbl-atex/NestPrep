import '../../../shared/failure/app_failure.dart';
import 'voucher_claim.dart';

sealed class VoucherClaimState {
  const VoucherClaimState();
}

final class VoucherWaiting extends VoucherClaimState {
  const VoucherWaiting();
}

final class VoucherClaiming extends VoucherClaimState {
  const VoucherClaiming();
}

final class VoucherAdded extends VoucherClaimState {
  const VoucherAdded({required this.claim, required this.householdName});

  final VoucherClaim claim;
  final String householdName;
}

final class VoucherRefused extends VoucherClaimState {
  const VoucherRefused(this.failure);

  final AppFailure failure;

  bool get endsVoucher => switch (failure) {
    final PremiumVoucherFailure refusal => refusal.endsVoucher,
    HouseholdFailure(problem: HouseholdProblem.notSignedIn) => true,
    _ => false,
  };
}
