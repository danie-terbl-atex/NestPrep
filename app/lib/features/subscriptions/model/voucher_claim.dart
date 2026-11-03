import 'package:freezed_annotation/freezed_annotation.dart';

part 'voucher_claim.freezed.dart';

@freezed
abstract class VoucherClaim with _$VoucherClaim {
  const factory VoucherClaim({
    required String grantId,
    required int days,
    required bool queued,
    DateTime? startsAt,
  }) = _VoucherClaim;
}
