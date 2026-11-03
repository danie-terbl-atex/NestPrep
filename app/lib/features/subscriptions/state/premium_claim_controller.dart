import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../household/data/household_repository.dart';
import '../../household/model/household.dart';
import '../data/premium_voucher_directory.dart';
import '../model/premium_voucher.dart';
import '../model/voucher_claim_state.dart';
import 'premium_voucher_inbox.dart';

final class PremiumClaimController extends ChangeNotifier {
  PremiumClaimController({
    required this._directory,
    required this._inbox,
    required HouseholdRepository householdRepository,
    required this.uid,
    required Household current,
    required List<String> householdIds,
  }) : _households = householdRepository {
    _vouchers = [..._inbox.waiting];
    _inbox.addListener(_onInbox);
    unawaited(_loadHouseholds(current, householdIds));
  }

  final PremiumVoucherDirectory _directory;
  final PremiumVoucherInbox _inbox;
  final HouseholdRepository _households;
  final String uid;

  late List<PremiumVoucher> _vouchers;
  final _states = <String, VoucherClaimState>{};
  AsyncState<List<Household>> _familyHouseholds = const AsyncLoading();
  String? _selectedId;
  bool _isDisposed = false;

  List<PremiumVoucher> get vouchers => _vouchers;

  AsyncState<List<Household>> get households => _familyHouseholds;

  Household? get selected => switch (_familyHouseholds) {
    AsyncData(:final value) =>
      value.where((household) => household.id == _selectedId).firstOrNull,
    _ => null,
  };

  bool get isClaiming =>
      _states.values.any((state) => state is VoucherClaiming);

  bool get isFinished =>
      _vouchers.isNotEmpty &&
      _vouchers.every(
        (voucher) => switch (stateOf(voucher)) {
          VoucherAdded() => true,
          final VoucherRefused refused => refused.endsVoucher,
          _ => false,
        },
      );

  VoucherClaimState stateOf(PremiumVoucher voucher) =>
      _states[voucher.voucherId] ?? const VoucherWaiting();

  void select(String householdId) {
    if (_selectedId == householdId) return;
    _selectedId = householdId;
    _states.removeWhere(
      (_, state) => state is VoucherRefused && !state.endsVoucher,
    );
    _notify();
  }

  Future<void> claim(PremiumVoucher voucher) async {
    final household = selected;
    if (household == null || isClaiming) return;
    if (stateOf(voucher) is VoucherAdded) return;
    _states[voucher.voucherId] = const VoucherClaiming();
    _notify();
    VoucherClaimState outcome;
    try {
      final claim = await _directory.claim(
        voucherId: voucher.voucherId,
        householdId: household.id,
      );
      outcome = VoucherAdded(claim: claim, householdName: household.name);
    } on AppFailure catch (failure) {
      outcome = VoucherRefused(failure);
    }
    _states[voucher.voucherId] = outcome;
    if (outcome is VoucherAdded ||
        (outcome is VoucherRefused && outcome.endsVoucher)) {
      _inbox.settle(voucher.voucherId);
    }
    _notify();
  }

  void _onInbox() {
    final known = {for (final voucher in _vouchers) voucher.voucherId};
    final fresh = [
      for (final voucher in _inbox.waiting)
        if (!known.contains(voucher.voucherId)) voucher,
    ];
    if (fresh.isEmpty) return;
    _vouchers = [..._vouchers, ...fresh];
    _notify();
  }

  Future<void> _loadHouseholds(Household current, List<String> ids) async {
    final others = [
      for (final id in ids)
        if (id != current.id) id,
    ];
    AsyncState<List<Household>> loaded;
    try {
      final read = others.isEmpty
          ? const <Household>[]
          : await _households.readHouseholds(others);
      loaded = AsyncData([
        for (final household in [current, ...read])
          if (household.roleOf(uid)?.isFamily ?? false) household,
      ]);
    } on AppFailure catch (failure) {
      loaded = (current.roleOf(uid)?.isFamily ?? false)
          ? AsyncData([current])
          : AsyncFailure(failure);
    }
    _familyHouseholds = loaded;
    if (loaded case AsyncData(:final value) when value.isNotEmpty) {
      _selectedId = value.first.id;
    }
    _notify();
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _inbox.removeListener(_onInbox);
    super.dispose();
  }
}
