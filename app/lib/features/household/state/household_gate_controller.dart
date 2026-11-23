import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../design/tokens/nest_member_palette.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/best_effort.dart';
import '../../../shared/time/household_clock.dart';
import '../../starter_content/data/starter_content_repository.dart';
import '../data/household_directory.dart';

/// The controller for someone who belongs to no household yet: create one, or
/// type the code somebody sent them (household ADR-0002). Both are callables,
/// so both need the network and both can refuse.
final class HouseholdGateController extends ChangeNotifier {
  HouseholdGateController({
    required HouseholdDirectory householdDirectory,
    required this._starterContent,
    required this._startsWithExamples,
    required this.suggestedName,
    required this.defaultTimeZone,
  }) : _directory = householdDirectory;

  final HouseholdDirectory _directory;
  final StarterContentRepository _starterContent;
  final bool Function() _startsWithExamples;

  /// What to call the person's own profile before they change it — the name
  /// Google gave us.
  final String suggestedName;

  /// The timezone a new household starts in (household ADR-0001).
  final String defaultTimeZone;

  bool _isBusy = false;
  bool _isDisposed = false;
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
  }) => _run(() async {
    final zone = timeZone ?? defaultTimeZone;
    final created = await _directory.createHousehold(
      name: householdName,
      timeZone: zone,
      adminDisplayName: myName,
      adminColorName: MemberColor.violet.name,
    );
    if (!_startsWithExamples()) return created;
    // Not awaited: the household exists whether or not its examples land, and
    // a write to a backend that has gone quiet never completes.
    unawaited(_seedExamples(created, zone));
    return created;
  });

  Future<void> _seedExamples(CreatedHousehold created, String zone) =>
      bestEffort(
        'starter content',
        code: 'seed',
        run: () => _starterContent.seed(
          householdId: created.householdId,
          memberId: created.memberId,
          today: HouseholdClock(zone).today,
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
      // Success takes the screen, and this controller with it, off the router
      // before the call has answered.
      if (!_isDisposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
