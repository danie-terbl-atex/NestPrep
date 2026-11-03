import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../data/premium_voucher_directory.dart';
import '../model/premium_voucher.dart';

final class PremiumVoucherInbox extends ChangeNotifier {
  PremiumVoucherInbox({required this._directory});

  final PremiumVoucherDirectory _directory;

  String? _uid;
  int _generation = 0;
  AsyncState<List<PremiumVoucher>> _vouchers = const AsyncData([]);
  bool _hasOffered = false;
  bool _isDisposed = false;

  AsyncState<List<PremiumVoucher>> get vouchers => _vouchers;

  List<PremiumVoucher> get waiting => switch (_vouchers) {
    AsyncData(:final value) => value,
    _ => const [],
  };

  bool get shouldOffer => !_hasOffered && waiting.isNotEmpty;

  void attach(String uid) {
    if (_uid == uid) return;
    _uid = uid;
    _hasOffered = false;
    _vouchers = const AsyncData([]);
    unawaited(refresh());
  }

  Future<void> refresh() async {
    if (_uid == null) return;
    final generation = ++_generation;
    if (_vouchers is! AsyncData || waiting.isEmpty) {
      _vouchers = const AsyncLoading();
      _notify();
    }
    AsyncState<List<PremiumVoucher>> answer;
    try {
      answer = AsyncData(await _directory.vouchersForMe());
    } on AppFailure catch (failure) {
      AppLog.failure('premium vouchers', code: 'unread', error: failure);
      answer = AsyncFailure(failure);
    }
    if (generation != _generation) return;
    _vouchers = answer;
    _notify();
  }

  void markOffered() => _hasOffered = true;

  void settle(String voucherId) {
    if (!waiting.any((voucher) => voucher.voucherId == voucherId)) return;
    _vouchers = AsyncData([
      for (final voucher in waiting)
        if (voucher.voucherId != voucherId) voucher,
    ]);
    _notify();
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
