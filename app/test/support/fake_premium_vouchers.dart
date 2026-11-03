import 'dart:async';

import 'package:nestprep/features/subscriptions/data/premium_voucher_directory.dart';
import 'package:nestprep/features/subscriptions/model/premium_voucher.dart';
import 'package:nestprep/features/subscriptions/model/premium_voucher_kind.dart';
import 'package:nestprep/features/subscriptions/model/voucher_claim.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// The Premium voucher callables (subscriptions ADR-0003, ADR-0004),
/// answering as a test sets them and recording what was asked.
final class FakePremiumVoucherDirectory implements PremiumVoucherDirectory {
  List<PremiumVoucher> waiting = [];

  /// What a successful verify adds to [waiting], as a proven email would.
  List<PremiumVoucher> provenByEmail = [];

  AppFailure? failListWith;
  AppFailure? failClaimWith;
  AppFailure? failSendWith;
  AppFailure? failVerifyWith;
  bool queued = false;

  Completer<void>? holdClaim;

  var listed = 0;
  final claimed = <({String voucherId, String householdId})>[];
  final sentTo = <String>[];
  final verified = <({String email, String code})>[];

  static const frame = PremiumVoucher(
    voucherId: 'order1_1',
    kind: PremiumVoucherKind.frame,
    days: 93,
    sku: 'frame-15',
    emailMasked: 's***@gmail.com',
  );

  static const gift = PremiumVoucher(
    voucherId: 'gift1',
    kind: PremiumVoucherKind.code,
    days: 30,
    emailMasked: 's***@icloud.com',
  );

  @override
  Future<List<PremiumVoucher>> vouchersForMe() async {
    listed++;
    final failure = failListWith;
    if (failure != null) throw failure;
    return [...waiting];
  }

  @override
  Future<VoucherClaim> claim({
    required String voucherId,
    required String householdId,
  }) async {
    await holdClaim?.future;
    final failure = failClaimWith;
    if (failure != null) throw failure;
    claimed.add((voucherId: voucherId, householdId: householdId));
    waiting.removeWhere((voucher) => voucher.voucherId == voucherId);
    return VoucherClaim(grantId: 'grant-$voucherId', queued: queued);
  }

  @override
  Future<String> sendEmailCode(String email) async {
    final failure = failSendWith;
    if (failure != null) throw failure;
    sentTo.add(email);
    return 'p***@example.com';
  }

  @override
  Future<String> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    final failure = failVerifyWith;
    if (failure != null) throw failure;
    verified.add((email: email, code: code));
    waiting = [...waiting, ...provenByEmail];
    return 'p***@example.com';
  }
}
