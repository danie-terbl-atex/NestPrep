part of 'app_failure.dart';

enum PremiumVoucherProblem {
  voucherNotFound,
  notYourVoucher,
  voucherClaimed,
  voucherVoid,
  testVoucher,
  codeUsedUp,
  codeAlreadyUsed,
  codeNotEligible,
  codeYearlyLimit,
  codeExpired,
  codePaused,
  emailCodeWrong,
  emailCodeExpired,
  emailCodeTooManyTries,
  emailAlreadyVerified,
  tooManyCodes,
}

enum VoucherRefusalScope { household, person }

final class PremiumVoucherFailure extends AppFailure {
  const PremiumVoucherFailure(this.problem, {this.scope});

  final PremiumVoucherProblem problem;
  final VoucherRefusalScope? scope;

  bool get endsVoucher => switch (problem) {
    PremiumVoucherProblem.voucherNotFound ||
    PremiumVoucherProblem.notYourVoucher ||
    PremiumVoucherProblem.voucherClaimed ||
    PremiumVoucherProblem.voucherVoid ||
    PremiumVoucherProblem.testVoucher ||
    PremiumVoucherProblem.codeUsedUp ||
    PremiumVoucherProblem.codeExpired => true,
    PremiumVoucherProblem.codeAlreadyUsed =>
      scope == VoucherRefusalScope.person,
    _ => false,
  };

  @override
  bool operator ==(Object other) =>
      other is PremiumVoucherFailure &&
      other.problem == problem &&
      other.scope == scope;

  @override
  int get hashCode => Object.hash(problem, scope);
}
