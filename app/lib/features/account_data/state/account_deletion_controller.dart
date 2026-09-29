import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../data/account_data_gateway.dart';
import '../model/deletion_preview.dart';

/// The Delete my account screen's controller (accounts ADR-0006): read what
/// deleting would do, let the person type the confirmation, and delete — once.
///
/// It holds no rule of its own. The server decides every household's outcome
/// and refuses if the plan has changed since it was read; this only keeps the
/// button shut until the word is typed, and never sends twice (`FE-10`).
final class AccountDeletionController extends ChangeNotifier {
  AccountDeletionController({
    required AccountDataGateway accountDataGateway,
    required Future<void> Function() signOut,
  }) : _gateway = accountDataGateway,
       _endSession = signOut {
    unawaited(load());
  }

  /// The word the person types. The server checks the same word.
  static const confirmationWord = 'DELETE';

  final AccountDataGateway _gateway;
  final Future<void> Function() _endSession;

  AsyncState<DeletionPreview> _preview = const AsyncLoading();
  String _typed = '';
  bool _isDeleting = false;
  AppFailure? _deleteFailure;
  bool _isDisposed = false;

  AsyncState<DeletionPreview> get preview => _preview;
  bool get isDeleting => _isDeleting;

  /// Why the last delete did not happen; the preview above it is still true.
  AppFailure? get deleteFailure => _deleteFailure;

  bool get isConfirmed => _typed.trim().toUpperCase() == confirmationWord;

  bool get canDelete =>
      _preview is AsyncData<DeletionPreview> && isConfirmed && !_isDeleting;

  Future<void> load() async {
    _preview = const AsyncLoading();
    _notify();
    try {
      _preview = AsyncData(await _gateway.previewDeletion());
    } on AppFailure catch (failure) {
      _preview = AsyncFailure(failure);
    }
    _notify();
  }

  void typeConfirmation(String value) {
    _typed = value;
    _notify();
  }

  /// Deletes the account and signs this phone out. A plan that changed is
  /// read again, so what the person sees is what would happen now, and they
  /// confirm again.
  Future<void> delete() async {
    final preview = _preview;
    if (!canDelete || preview is! AsyncData<DeletionPreview>) return;
    _isDeleting = true;
    _deleteFailure = null;
    _notify();
    try {
      await _gateway.deleteAccount(
        endingHouseholdIds: preview.value.endingHouseholdIds,
      );
    } on AppFailure catch (failure) {
      _isDeleting = false;
      _deleteFailure = failure;
      _notify();
      if (failure case AccountDataFailure(
        problem: AccountDataProblem.deletionPlanChanged,
      )) {
        _typed = '';
        await load();
      }
      return;
    }
    // The account is gone on the server; this phone's session goes with it.
    await _endSession();
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
