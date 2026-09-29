import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../../shared/time/calendar_date.dart';
import '../data/two_homes_directory.dart';
import '../data/two_homes_repository.dart';
import '../model/change_request.dart';
import '../model/co_parent_link.dart';
import '../model/custody_schedule.dart';
import '../model/custody_side.dart';
import '../model/handover_note.dart';
import '../model/two_homes_access.dart';

/// One link's screen: the link itself, the handovers written up around now,
/// and the requests between the two homes (household ADR-0004).
///
/// Each read is opened only when the viewer's grant lets them make it — a
/// rule is not a filter, so a listener the rules refuse is a listener that
/// fails, not one that comes back empty.
final class LinkController extends ChangeNotifier with ActionFailureHolder {
  LinkController({
    required TwoHomesRepository twoHomesRepository,
    required TwoHomesDirectory twoHomesDirectory,
    required this.householdId,
    required this.linkId,
    required this.today,
    required this.access,
  }) : _repository = twoHomesRepository,
       _directory = twoHomesDirectory {
    _subscribe();
  }

  final TwoHomesRepository _repository;
  final TwoHomesDirectory _directory;
  final String householdId;
  final String linkId;
  final CalendarDate today;
  final TwoHomesAccess access;

  /// How far back and ahead handovers are read: last fortnight's notes are
  /// still useful, and twelve weeks is as far as the screen looks.
  static const handoversBack = 14;
  static const handoversAhead = 84;

  final _subscriptions = <StreamSubscription<Object?>>[];
  AsyncState<CoParentLink?> _link = const AsyncLoading();
  List<ChangeRequest> _requests = const [];
  Map<CalendarDate, HandoverNote> _handovers = const {};
  bool _isSending = false;

  AsyncState<CoParentLink?> get link => _link;
  List<ChangeRequest> get requests => _requests;
  bool get isSending => _isSending;

  List<ChangeRequest> get waiting =>
      _requests.where((request) => request.isPending).toList();

  List<ChangeRequest> get answered =>
      _requests.where((request) => !request.isPending).toList();

  HandoverNote? handoverOn(CalendarDate date) => _handovers[date];

  Future<bool> proposeSwap({
    required CalendarDate from,
    required CalendarDate to,
    required CustodySide toSide,
    String? note,
  }) => _send(
    () => _directory.proposeSwap(
      householdId: householdId,
      linkId: linkId,
      from: from,
      to: to,
      toSide: toSide,
      note: _clean(note),
    ),
  );

  Future<bool> proposeSchedule(CustodySchedule schedule, {String? note}) =>
      _send(
        () => _directory.proposeSchedule(
          householdId: householdId,
          linkId: linkId,
          schedule: schedule,
          note: _clean(note),
        ),
      );

  Future<bool> answer(
    ChangeRequest request,
    ChangeAnswer answer, {
    String? note,
  }) => _send(
    () => _directory.answerChange(
      householdId: householdId,
      linkId: linkId,
      requestId: request.id,
      answer: answer,
      note: _clean(note),
    ),
  );

  Future<bool> end() =>
      _send(() => _directory.endLink(householdId: householdId, linkId: linkId));

  Future<bool> confirm({required bool accept}) => _send(
    () => _directory.confirmLink(
      householdId: householdId,
      linkId: linkId,
      accept: accept,
    ),
  );

  Future<void> retry() async {
    await _cancel();
    _link = const AsyncLoading();
    _requests = const [];
    _handovers = const {};
    notifyListeners();
    _subscribe();
  }

  /// Whether it went; a refusal is held for the banner (`FE-09`).
  Future<bool> _send(Future<void> Function() action) async {
    if (_isSending) return false;
    _isSending = true;
    notifyListeners();
    await runAction(action);
    _isSending = false;
    notifyListeners();
    return actionFailure == null;
  }

  static String? _clean(String? text) {
    final trimmed = text?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  void _subscribe() {
    _subscriptions.add(
      _repository.watchLink(householdId: householdId, linkId: linkId).listen((
        link,
      ) {
        _link = AsyncData(link);
        notifyListeners();
      }, onError: _onError),
    );
    if (access.canSeeRequests) {
      _subscriptions.add(
        _repository
            .watchRequests(householdId: householdId, linkId: linkId)
            .listen((requests) {
              _requests = requests;
              notifyListeners();
            }, onError: _onPartError),
      );
    }
    if (access.canSeeHandovers) {
      _subscriptions.add(
        _repository
            .watchHandovers(
              householdId: householdId,
              linkId: linkId,
              from: today.addDays(-handoversBack),
              to: today.addDays(handoversAhead),
            )
            .listen((notes) {
              _handovers = {for (final note in notes) note.date: note};
              notifyListeners();
            }, onError: _onPartError),
      );
    }
  }

  void _onError(Object error) {
    _link = AsyncFailure(error is AppFailure ? error : UnknownFailure(error));
    notifyListeners();
  }

  /// The link still stands without its requests or notes; the banner says
  /// that part could not be read (`ENG-10`).
  void _onPartError(Object error) =>
      recordFailure(error is AppFailure ? error : UnknownFailure(error));

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
