import 'package:flutter/foundation.dart';

import '../../../design/tokens/nest_member_palette.dart';
import '../../../shared/failure/app_failure.dart';
import '../data/household_directory.dart';

/// The controller for someone who belongs to no household yet: create one, or
/// type the code somebody sent them (household ADR-0002). Both are callables,
/// so both need the network and both can refuse.
final class HouseholdGateController extends ChangeNotifier {
  HouseholdGateController({
    required HouseholdDirectory householdDirectory,
    required this.suggestedName,
    required this.defaultTimeZone,
  }) : _directory = householdDirectory;

  final HouseholdDirectory _directory;

  /// What to call the person's own profile before they change it — the name
  /// Google gave us.
  final String suggestedName;

  /// The timezone a new household starts in (household ADR-0001).
  final String defaultTimeZone;

  bool _isBusy = false;
  AppFailure? _failure;

  bool get isBusy => _isBusy;
  AppFailure? get failure => _failure;

  void dismissFailure() {
    if (_failure == null) return;
    _failure = null;
    notifyListeners();
  }

  Future<bool> createHousehold({
    required String householdName,
    required String myName,
    String? timeZone,
  }) => _run(
    () => _directory.createHousehold(
      name: householdName,
      timeZone: timeZone ?? defaultTimeZone,
      adminDisplayName: myName,
      adminColorName: MemberColor.violet.name,
    ),
  );

  Future<bool> joinWithCode(String code) =>
      _run(() => _directory.redeemInvite(code));

  Future<bool> _run(Future<Object?> Function() action) async {
    if (_isBusy) return false;
    _isBusy = true;
    _failure = null;
    notifyListeners();
    try {
      await action();
      // The account document gains the household; the session is listening, so
      // the router moves the screen on. Nothing is kept here.
      return true;
    } on AppFailure catch (failure) {
      _failure = failure;
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}
