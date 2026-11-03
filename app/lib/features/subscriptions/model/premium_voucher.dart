import 'package:freezed_annotation/freezed_annotation.dart';

import 'premium_length.dart';
import 'premium_voucher_kind.dart';

part 'premium_voucher.freezed.dart';

@freezed
abstract class PremiumVoucher with _$PremiumVoucher {
  const factory PremiumVoucher({
    required String voucherId,
    required PremiumVoucherKind kind,
    required int days,
    required String emailMasked,
    String? sku,
    @Default(false) bool isTest,
  }) = _PremiumVoucher;

  const PremiumVoucher._();

  PremiumLength get length => PremiumLength.of(kind.source, days);
}
