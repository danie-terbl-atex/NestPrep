import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../../household/model/member.dart';
import '../../nanny_hub/data/shift_repository.dart';
import '../../nanny_hub/model/shift.dart';
import '../data/document_share_directory.dart';
import '../model/identity_document_hint.dart';
import '../model/share_lifetime.dart';
import '../model/share_request.dart';
import '../model/share_target.dart';
import '../model/shared_link.dart';

/// The "share with a link" sheet (documents ADR-0006): how long, whether to
/// ask for a PIN, a second look at an ID document, and the link once made.
///
/// A shift is offered only while one is open; the choice of shifts is read
/// from the nanny hub's own repository, and a household without the hub — or
/// a viewer who cannot see it — simply gets the fixed lengths.
final class ShareLinkComposer extends ChangeNotifier {
  ShareLinkComposer({
    required this._directory,
    required this.target,
    ShiftRepository? shifts,
    this._members = const [],
  }) {
    if (shifts != null) {
      _shiftSubscription = shifts
          .watchOpenShifts(target.householdId)
          .listen(_onShifts, onError: _onShiftsError);
    }
  }

  final DocumentShareDirectory _directory;
  final ShareTarget target;
  final List<Member> _members;
  StreamSubscription<List<Shift>>? _shiftSubscription;

  ShareLifetime _lifetime = ShareLifetime.suggested;
  List<ShiftLifetime> _shiftOptions = const [];
  var _asksForPin = false;
  var _pin = '';
  var _isCreating = false;
  SharedLink? _link;
  AppFailure? _failure;

  ShareLifetime get lifetime => _lifetime;
  List<ShiftLifetime> get shiftOptions => _shiftOptions;
  bool get asksForPin => _asksForPin;
  String get pin => _pin;
  bool get isCreating => _isCreating;
  SharedLink? get link => _link;
  AppFailure? get failure => _failure;

  /// An ID or a passport asks twice (documents ADR-0006).
  bool get isIdentityDocument => IdentityDocumentHint.looksLikeIdentity(
    name: target.name,
    tags: target.tags,
  );

  /// Whether the PIN, if asked for, is one the server will take.
  bool get isPinValid => !_asksForPin || ShareRequest.isPin(_pin);

  /// Worth saying only once somebody has typed enough to be wrong.
  bool get showsPinProblem =>
      _asksForPin && _pin.isNotEmpty && !ShareRequest.isPin(_pin);

  bool get canCreate => !_isCreating && _link == null && isPinValid;

  void chooseLifetime(ShareLifetime lifetime) {
    _lifetime = lifetime;
    notifyListeners();
  }

  void setAsksForPin(bool asks) {
    _asksForPin = asks;
    notifyListeners();
  }

  void setPin(String pin) {
    _pin = pin;
    notifyListeners();
  }

  /// Makes the link; one request at a time (`FE-10`).
  Future<void> create() async {
    if (!canCreate) return;
    _isCreating = true;
    _failure = null;
    notifyListeners();
    try {
      _link = await _directory.create(
        ShareRequest(
          householdId: target.householdId,
          ownerMemberId: target.ownerMemberId,
          documentId: target.documentId,
          lifetime: _lifetime,
          pin: _asksForPin ? _pin : null,
        ),
      );
    } on AppFailure catch (failure) {
      _failure = failure;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  void _onShifts(List<Shift> shifts) {
    _shiftOptions = [
      for (final shift in shifts)
        if (shift.isOpen)
          ShiftLifetime(shiftId: shift.id, carerName: _nameOf(shift)),
    ];
    // A chosen shift that has just ended is no longer a choice.
    if (_lifetime is ShiftLifetime && !_shiftOptions.contains(_lifetime)) {
      _lifetime = ShareLifetime.suggested;
    }
    notifyListeners();
  }

  String _nameOf(Shift shift) =>
      _members
          .where((member) => member.id == shift.carerMemberId)
          .firstOrNull
          ?.displayName ??
      '';

  void _onShiftsError(Object error) {
    // Without the shifts, the fixed lengths are still every choice there is.
    AppLog.failure('share link shifts', code: 'unreadable', error: error);
  }

  @override
  void dispose() {
    unawaited(_shiftSubscription?.cancel());
    super.dispose();
  }
}
