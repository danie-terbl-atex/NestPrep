import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../household/model/member.dart';
import '../data/vault_repository.dart';
import '../model/vault_view.dart';

/// Who opened what, newest first, across the vaults whose log this person may
/// read — every vault for an admin, their own for anybody else (documents
/// ADR-0003). The rules say the same; this only avoids asking for what they
/// would refuse.
///
/// Created behind the vault's lock, so it exists only while the vault is open.
final class VaultViewLogController extends ChangeNotifier {
  VaultViewLogController({
    required VaultRepository vaultRepository,
    required this.householdId,
    required List<Member> members,
    required String viewerMemberId,
    required bool isAdmin,
  }) : _repository = vaultRepository,
       owners = [
         for (final member in members)
           if (isAdmin || member.id == viewerMemberId) member.id,
       ] {
    _start();
  }

  final VaultRepository _repository;
  final String householdId;

  /// The vaults whose logs are read.
  final List<String> owners;

  final _views = <String, List<VaultView>>{};
  final _subscriptions = <StreamSubscription<List<VaultView>>>[];
  AsyncState<List<VaultView>> _log = const AsyncLoading();

  AsyncState<List<VaultView>> get log => _log;

  Future<void> retry() async {
    await _stop();
    _log = const AsyncLoading();
    notifyListeners();
    _start();
  }

  void _start() {
    if (owners.isEmpty) {
      _log = const AsyncData([]);
      return;
    }
    for (final owner in owners) {
      _subscriptions.add(
        _repository
            .watchViews(householdId: householdId, ownerMemberId: owner)
            .listen((views) {
              _views[owner] = views;
              _publish();
            }, onError: _onError),
      );
    }
  }

  void _publish() {
    if (!owners.every(_views.containsKey)) return;
    final merged = _views.values.expand((views) => views).toList()
      ..sort((a, b) {
        final left = a.viewedAt;
        final right = b.viewedAt;
        // A view the server has not stamped yet is the newest there is.
        if (left == null) return -1;
        if (right == null) return 1;
        return right.compareTo(left);
      });
    _log = AsyncData(merged);
    notifyListeners();
  }

  void _onError(Object error) {
    _log = AsyncFailure(error is AppFailure ? error : UnknownFailure(error));
    notifyListeners();
  }

  Future<void> _stop() async {
    final open = List.of(_subscriptions);
    _subscriptions.clear();
    _views.clear();
    await Future.wait(open.map((subscription) => subscription.cancel()));
  }

  @override
  void dispose() {
    unawaited(_stop());
    super.dispose();
  }
}
