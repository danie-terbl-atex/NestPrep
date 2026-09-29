import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../../shared/time/calendar_date.dart';
import '../data/two_homes_directory.dart';
import '../data/two_homes_repository.dart';
import '../model/co_parent_link.dart';

/// The two-homes screen: this household's links, open ones first, and the
/// two decisions an admin makes about one from the list — confirming the home
/// that accepted a code, and ending a link (household ADR-0004).
final class TwoHomesController extends ChangeNotifier with ActionFailureHolder {
  TwoHomesController({
    required TwoHomesRepository twoHomesRepository,
    required TwoHomesDirectory twoHomesDirectory,
    required this.householdId,
    required this.today,
  }) : _repository = twoHomesRepository,
       _directory = twoHomesDirectory {
    _subscribe();
  }

  final TwoHomesRepository _repository;
  final TwoHomesDirectory _directory;
  final String householdId;

  /// The household's today, from `HouseholdClock` at the route.
  final CalendarDate today;

  StreamSubscription<List<CoParentLink>>? _subscription;
  AsyncState<List<CoParentLink>> _links = const AsyncLoading();
  String? _busyLinkId;

  AsyncState<List<CoParentLink>> get links => _links;

  /// The link an answer is being sent for, so its buttons show it.
  String? get busyLinkId => _busyLinkId;

  /// Pending and active links, pending first — those need somebody.
  List<CoParentLink> get openLinks => switch (_links) {
    AsyncData(:final value) => [
      ...value.where((link) => link.isPending),
      ...value.where((link) => link.isActive),
    ],
    _ => const [],
  };

  /// Declined and ended links: the history both homes keep.
  List<CoParentLink> get pastLinks => switch (_links) {
    AsyncData(:final value) => value.where((link) => !link.isOpen).toList(),
    _ => const [],
  };

  Future<void> confirm(CoParentLink link, {required bool accept}) => _busy(
    link,
    () => _directory.confirmLink(
      householdId: householdId,
      linkId: link.id,
      accept: accept,
    ),
  );

  Future<void> end(CoParentLink link) => _busy(
    link,
    () => _directory.endLink(householdId: householdId, linkId: link.id),
  );

  Future<void> _busy(CoParentLink link, Future<void> Function() action) async {
    _busyLinkId = link.id;
    notifyListeners();
    await runAction(action);
    _busyLinkId = null;
    notifyListeners();
  }

  Future<void> retry() async {
    await _subscription?.cancel();
    _links = const AsyncLoading();
    notifyListeners();
    _subscribe();
  }

  void _subscribe() {
    _subscription = _repository
        .watchLinks(householdId)
        .listen(
          (links) {
            _links = AsyncData(links);
            notifyListeners();
          },
          onError: (Object error) {
            _links = AsyncFailure(
              error is AppFailure ? error : UnknownFailure(error),
            );
            notifyListeners();
          },
        );
  }

  Future<void> _cancel() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
