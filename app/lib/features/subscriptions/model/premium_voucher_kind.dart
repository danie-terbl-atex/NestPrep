import 'grant_source.dart';

enum PremiumVoucherKind {
  frame,
  code;

  GrantSource get source => switch (this) {
    PremiumVoucherKind.frame => GrantSource.frame,
    PremiumVoucherKind.code => GrantSource.code,
  };
}
