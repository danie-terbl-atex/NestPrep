import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import '../model/premium_voucher.dart';
import '../model/premium_voucher_kind.dart';
import '../model/voucher_claim.dart';
import 'premium_voucher_directory.dart';
import 'subscription_failure_mapper.dart';

final class CallablePremiumVoucherDirectory implements PremiumVoucherDirectory {
  const CallablePremiumVoucherDirectory(this._functions);

  static const vouchersCallable = 'premiumVouchersForMe';
  static const claimCallable = 'claimPremiumVoucher';
  static const sendCodeCallable = 'sendVoucherEmailCode';
  static const verifyCodeCallable = 'verifyVoucherEmailCode';

  final FirebaseFunctions _functions;

  @override
  Future<List<PremiumVoucher>> vouchersForMe() async {
    final result = await _call(vouchersCallable, const {});
    final vouchers = result['vouchers'];
    if (vouchers is! List) return const [];
    return [for (final entry in vouchers) ?voucherFrom(entry)];
  }

  @override
  Future<VoucherClaim> claim({
    required String voucherId,
    required String householdId,
  }) async {
    final result = await _call(claimCallable, {
      'voucherId': voucherId,
      'householdId': householdId,
    });
    final claim = claimFrom(result);
    if (claim == null) {
      throw UnknownFailure(StateError('$claimCallable answered no grant'));
    }
    return claim;
  }

  @override
  Future<String> sendEmailCode(String email) async {
    final result = await _call(sendCodeCallable, {'email': email});
    return _maskedFrom(result, sendCodeCallable, 'sent');
  }

  @override
  Future<String> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    final result = await _call(verifyCodeCallable, {
      'email': email,
      'code': code,
    });
    return _maskedFrom(result, verifyCodeCallable, 'verified');
  }

  static PremiumVoucher? voucherFrom(Object? entry) {
    if (entry
        case {
          'voucherId': final String voucherId,
          'kind': final String kindName,
          'days': final num days,
          'emailMasked': final String emailMasked,
        }
        when days > 0) {
      final kind = PremiumVoucherKind.values
          .where((value) => value.name == kindName)
          .firstOrNull;
      if (kind == null) return null;
      final sku = entry['sku'];
      return PremiumVoucher(
        voucherId: voucherId,
        kind: kind,
        days: days.toInt(),
        emailMasked: emailMasked,
        sku: sku is String ? sku : null,
        isTest: entry['isTest'] == true,
      );
    }
    return null;
  }

  static VoucherClaim? claimFrom(Map<Object?, Object?> result) {
    if (result case {
      'grantId': final String grantId,
      'days': final num days,
      'queued': final bool queued,
    }) {
      final startsAt = switch (result['startsAt']) {
        final String at => DateTime.tryParse(at)?.toUtc(),
        _ => null,
      };
      return VoucherClaim(
        grantId: grantId,
        days: days.toInt(),
        queued: queued,
        startsAt: startsAt,
      );
    }
    return null;
  }

  static String _maskedFrom(
    Map<Object?, Object?> result,
    String callable,
    String flag,
  ) {
    if (result case {'emailMasked': final String masked}
        when result[flag] == true) {
      return masked;
    }
    throw UnknownFailure(StateError('$callable answered no email'));
  }

  Future<Map<Object?, Object?>> _call(
    String name,
    Map<String, Object?> payload,
  ) async {
    try {
      final result = await _functions
          .httpsCallable(name)
          .call<Object?>(payload);
      final data = result.data;
      return data is Map ? data : const {};
    } on FirebaseFunctionsException catch (error) {
      throw failureFromSubscriptionCallable(error);
    }
  }
}
