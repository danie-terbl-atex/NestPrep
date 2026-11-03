import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../data/feedback_repository.dart';
import '../model/feedback_draft.dart';

enum FeedbackStatus { editing, sending, delivered, queued }

final class FeedbackController extends ChangeNotifier {
  FeedbackController({
    required this._repository,
    required this._uid,
    this._householdId,
    this._screen,
  });

  final FeedbackRepository _repository;
  final String _uid;
  final String? _householdId;
  final String? _screen;

  FeedbackKind? _kind;
  FeedbackArea? _area;
  String _message = '';
  bool _mayContact = false;
  FeedbackStatus _status = FeedbackStatus.editing;
  AppFailure? _failure;

  FeedbackKind? get kind => _kind;
  FeedbackArea? get area => _area;
  bool get mayContact => _mayContact;
  FeedbackStatus get status => _status;
  AppFailure? get failure => _failure;
  bool get isSending => _status == FeedbackStatus.sending;
  bool get canSend => _kind != null && _message.trim().isNotEmpty && !isSending;

  void chooseKind(FeedbackKind kind) {
    _kind = kind;
    notifyListeners();
  }

  void chooseArea(FeedbackArea? area) {
    _area = _area == area ? null : area;
    notifyListeners();
  }

  void setMessage(String message) {
    final hadText = _message.trim().isNotEmpty;
    _message = message;
    if (hadText != _message.trim().isNotEmpty) notifyListeners();
  }

  void setMayContact(bool value) {
    _mayContact = value;
    notifyListeners();
  }

  Future<void> send() async {
    final kind = _kind;
    if (kind == null || !canSend) return;
    _status = FeedbackStatus.sending;
    _failure = null;
    notifyListeners();
    try {
      final delivery = await _repository.send(
        uid: _uid,
        draft: FeedbackDraft(
          kind: kind,
          message: _message.trim(),
          mayContact: _mayContact,
          area: _area,
          screen: _screen,
          householdId: _householdId,
        ),
      );
      _status = switch (delivery) {
        FeedbackDelivery.delivered => FeedbackStatus.delivered,
        FeedbackDelivery.queued => FeedbackStatus.queued,
      };
    } on AppFailure catch (failure) {
      _failure = failure;
      _status = FeedbackStatus.editing;
    }
    notifyListeners();
  }

  void startAnother() {
    _kind = null;
    _area = null;
    _message = '';
    _mayContact = false;
    _status = FeedbackStatus.editing;
    _failure = null;
    notifyListeners();
  }
}
