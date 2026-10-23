import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../data/household_directory.dart';

/// The Close household screen's controller (household ADR-0007): let the
/// person type the confirmation, and close — once.
///
/// It holds no rule of its own. Whether this account may close the household
/// is the server's to decide, again, when the call arrives; this only keeps
/// the button shut until the word is typed, and never sends twice (`FE-10`).
/// When it works the account's own document changes, which the session is
/// listening to, so the router moves the screen on by itself.
final class CloseHouseholdController extends ChangeNotifier {
  CloseHouseholdController({
    required HouseholdDirectory householdDirectory,
    required this.householdId,
  }) : _directory = householdDirectory;

  /// The word the person types. The server checks the same word.
  static const confirmationWord = 'CLOSE';

  final HouseholdDirectory _directory;
  final String householdId;

  String _typed = '';
  bool _isClosing = false;
  bool _isClosed = false;
  AppFailure? _failure;
  bool _isDisposed = false;

  bool get isClosing => _isClosing;

  /// Closed on the server; the screen is about to be moved on.
  bool get isClosed => _isClosed;

  /// Why the last close did not happen.
  AppFailure? get failure => _failure;

  bool get isConfirmed => _typed.trim().toUpperCase() == confirmationWord;

  bool get canClose => isConfirmed && !_isClosing && !_isClosed;

  void typeConfirmation(String value) {
    _typed = value;
    _notify();
  }

  Future<void> close() async {
    if (!canClose) return;
    _isClosing = true;
    _failure = null;
    _notify();
    try {
      await _directory.closeHousehold(
        householdId: householdId,
        confirmation: confirmationWord,
      );
      _isClosed = true;
    } on AppFailure catch (failure) {
      _failure = failure;
    } finally {
      _isClosing = false;
      _notify();
    }
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
