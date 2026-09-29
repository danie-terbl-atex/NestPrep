import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../../shared/time/calendar_date.dart';
import '../data/two_homes_directory.dart';
import '../data/two_homes_repository.dart';
import '../model/co_parent_link.dart';
import '../model/handover_note.dart';
import '../model/handover_view.dart';

/// One handover: read from this home's copy, saved to both through
/// `saveCoParentHandover` (household ADR-0004). The draft lives in the
/// screen's fields; this holds what is stored and sends what is saved.
final class HandoverController extends ChangeNotifier with ActionFailureHolder {
  HandoverController({
    required TwoHomesRepository twoHomesRepository,
    required TwoHomesDirectory twoHomesDirectory,
    required this.householdId,
    required this.linkId,
    required this.date,
  }) : _repository = twoHomesRepository,
       _directory = twoHomesDirectory {
    _subscribe();
  }

  final TwoHomesRepository _repository;
  final TwoHomesDirectory _directory;
  final String householdId;
  final String linkId;
  final CalendarDate date;

  final _subscriptions = <StreamSubscription<Object?>>[];
  CoParentLink? _link;
  HandoverNote? _note;
  bool _noteArrived = false;
  bool _linkArrived = false;
  AppFailure? _readFailure;
  bool _isSaving = false;
  bool _justSaved = false;

  bool get isSaving => _isSaving;

  /// True after a save lands, until the next edit — the screen says so.
  bool get justSaved => _justSaved;

  /// The link and the note together; null link means it is gone.
  AsyncState<HandoverView?> get view {
    final failure = _readFailure;
    if (failure != null) return AsyncFailure(failure);
    if (!_linkArrived || !_noteArrived) return const AsyncLoading();
    final link = _link;
    return AsyncData(
      link == null ? null : HandoverView(link: link, note: _note),
    );
  }

  void edited() {
    if (!_justSaved) return;
    _justSaved = false;
    notifyListeners();
  }

  Future<bool> save({
    required List<HandoverItem> items,
    String? medicine,
    String? homework,
    String? clothes,
    String? note,
  }) async {
    if (_isSaving) return false;
    _isSaving = true;
    _justSaved = false;
    notifyListeners();
    await runAction(
      () => _directory.saveHandover(
        householdId: householdId,
        linkId: linkId,
        date: date,
        items: [
          for (final item in items)
            if (item.text.trim().isNotEmpty)
              HandoverItem(text: item.text.trim(), packed: item.packed),
        ],
        medicine: _clean(medicine),
        homework: _clean(homework),
        clothes: _clean(clothes),
        note: _clean(note),
      ),
    );
    _isSaving = false;
    _justSaved = actionFailure == null;
    notifyListeners();
    return _justSaved;
  }

  static String? _clean(String? text) {
    final trimmed = text?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Future<void> retry() async {
    await _cancel();
    _readFailure = null;
    _linkArrived = false;
    _noteArrived = false;
    notifyListeners();
    _subscribe();
  }

  void _subscribe() {
    _subscriptions
      ..add(
        _repository.watchLink(householdId: householdId, linkId: linkId).listen((
          link,
        ) {
          _link = link;
          _linkArrived = true;
          notifyListeners();
        }, onError: _onError),
      )
      ..add(
        _repository
            .watchHandover(householdId: householdId, linkId: linkId, date: date)
            .listen((note) {
              _note = note;
              _noteArrived = true;
              notifyListeners();
            }, onError: _onError),
      );
  }

  void _onError(Object error) {
    _readFailure = error is AppFailure ? error : UnknownFailure(error);
    notifyListeners();
  }

  Future<void> _cancel() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
