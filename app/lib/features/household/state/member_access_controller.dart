import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../data/household_directory.dart';
import '../model/access_grant.dart';
import '../model/access_level.dart';
import '../model/household_area.dart';

/// The access editor's controller: the grant a parent is choosing for one kid,
/// helper or carer, before it is saved (household ADR-0003).
///
/// The draft is the one piece of state here, and it is the editor's own —
/// the choices somebody is part-way through making. What is *saved* stays in
/// the household listener the screen reads, never copied in (`FE-07`).
final class MemberAccessController extends ChangeNotifier
    with ActionFailureHolder {
  MemberAccessController({
    required HouseholdDirectory householdDirectory,
    required this.householdId,
    required this.memberId,
    required AccessGrant startingFrom,
  }) : _directory = householdDirectory,
       _draft = startingFrom;

  final HouseholdDirectory _directory;
  final String householdId;
  final String memberId;

  AccessGrant _draft;
  bool _isSaving = false;
  AccessGrant? _lastSaved;

  AccessGrant get draft => _draft;
  bool get isSaving => _isSaving;

  /// The draft is what this screen last saved, so the button says so. The
  /// listener catches up a moment later: the write was the Function's, not
  /// this client's, so it is not in the local cache until the server sends it.
  bool get justSaved => _lastSaved != null && _lastSaved == _draft;

  /// Whether there is anything to save against what the household holds now.
  bool hasChangesFrom(AccessGrant current) => _draft != current && !justSaved;

  void setLevel(HouseholdArea area, AccessLevel level) {
    final next = _draft.withLevel(area, level);
    if (next == _draft) return;
    _draft = next;
    clearFailureQuietly();
    notifyListeners();
  }

  /// Starts again from a whole grant — the role's suggestion, or nothing.
  void applyPreset(AccessGrant preset) {
    if (preset == _draft) return;
    _draft = preset;
    clearFailureQuietly();
    notifyListeners();
  }

  /// Saves the draft. One save at a time, so a double tap cannot send two
  /// (`FE-10`). Answers whether it landed.
  Future<bool> save() async {
    if (_isSaving) return false;
    _isSaving = true;
    clearFailureQuietly();
    notifyListeners();
    final sending = _draft;
    try {
      await _directory.setMemberAccess(
        householdId: householdId,
        memberId: memberId,
        access: sending,
      );
      _lastSaved = sending;
      return true;
    } on AppFailure catch (failure) {
      recordFailure(failure);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
