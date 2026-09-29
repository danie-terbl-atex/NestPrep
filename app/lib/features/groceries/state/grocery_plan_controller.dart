import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../lunch_box/model/lunch_week.dart';
import '../data/grocery_repository.dart';
import '../data/grocery_suggestion_source.dart';
import '../model/grocery_item.dart';
import '../model/grocery_need.dart';
import '../model/grocery_plan_changes.dart';
import '../model/grocery_plan_diff.dart';
import '../model/grocery_plan_line.dart';
import '../model/grocery_plan_settings.dart';
import '../model/grocery_plan_view.dart';
import '../model/grocery_proposal.dart';
import 'grocery_keep_in_step.dart';

/// The week's plans against the list (groceries ADR-0002): every source the
/// viewer may see, the list, and the household's settings, joined into one
/// [GroceryPlanView]. It proposes; it writes only what a person chose, or —
/// with keep-in-step on — what the diff says, through [GroceryKeepInStep].
final class GroceryPlanController extends ChangeNotifier
    with ActionFailureHolder {
  GroceryPlanController({
    required GroceryRepository groceryRepository,
    required List<GrocerySuggestionSource> sources,
    required this._wording,
    required this.householdId,
    required this.memberId,
    required this.week,
    required this.canEdit,
    required this.seesEverySource,
    DateTime Function()? now,
  }) : _repository = groceryRepository,
       _sources = List.unmodifiable(sources),
       _now = now ?? DateTime.now {
    _keeper = GroceryKeepInStep(write: _write, report: recordFailure);
    _subscribe();
  }

  final GroceryRepository _repository;

  /// Only the sources this viewer's grants cover; the route filters them.
  final List<GrocerySuggestionSource> _sources;
  final GroceryPlanLine Function(GroceryProposal) _wording;
  final DateTime Function() _now;
  late final GroceryKeepInStep _keeper;

  final String householdId;
  final String memberId;
  final LunchWeek week;

  /// `groceries` at edit: may add to the list at all.
  final bool canEdit;

  /// Sees every registered source — the condition for keeping in step, so a
  /// viewer blind to one plan never takes that plan's items off.
  final bool seesEverySource;

  final _subscriptions = <StreamSubscription<Object?>>[];
  final _needs = <String, List<GroceryNeed>>{};
  List<GroceryItem>? _items;
  GroceryPlanSettings? _settings;

  AsyncState<GroceryPlanView> _view = const AsyncLoading();

  AsyncState<GroceryPlanView> get view => _view;

  /// Whether there is anything to propose from at all.
  bool get hasSources => _sources.isNotEmpty;

  /// The clock the diff was classified with, for "bought 2 days ago".
  DateTime get now => _now();

  Future<void> retry() async {
    await _cancel();
    _needs.clear();
    _items = null;
    _settings = null;
    _view = const AsyncLoading();
    notifyListeners();
    _subscribe();
  }

  /// Writes what a person left ticked in the sheet — adds, refreshes and
  /// removals, in one batch.
  Future<void> apply({
    required Set<String> addKeys,
    required Set<String> refreshIds,
    required Set<String> removeIds,
  }) async {
    final (diff, items) = (_diff, _items);
    if (!canEdit || diff == null || items == null) return;
    final changes = GroceryPlanChanges.chosen(
      diff,
      existingIds: {for (final item in items) item.id},
      addKeys: addKeys,
      refreshIds: refreshIds,
      removeIds: removeIds,
    );
    if (changes.isEmpty) return;
    await runAction(() => _write(changes));
  }

  Future<void> setKeepInStep(bool keepInStep) async {
    if (!canEdit || (keepInStep && !seesEverySource)) return;
    await runAction(
      () => _repository.setKeepInStep(
        householdId: householdId,
        keepInStep: keepInStep,
        memberId: memberId,
      ),
    );
  }

  /// Marks a name *usually in the house*, or puts it back on the plans.
  Future<void> setStaple(String key, {required bool isStaple}) async {
    final settings = _settings ?? GroceryPlanSettings.empty;
    if (!canEdit || settings.isStaple(key) == isStaple) return;
    if (isStaple &&
        settings.staples.length >= GroceryPlanSettings.stapleLimit) {
      return;
    }
    await runAction(
      () => _repository.setStaple(
        householdId: householdId,
        key: key,
        isStaple: isStaple,
        memberId: memberId,
      ),
    );
  }

  GroceryPlanDiff? get _diff => switch (_view) {
    AsyncData(value: final view) => view.diff,
    _ => null,
  };

  Future<void> _write(GroceryPlanChanges changes) =>
      _repository.applyPlanChanges(
        householdId: householdId,
        changes: changes,
        memberId: memberId,
      );

  void _subscribe() {
    for (final source in _sources) {
      _subscriptions.add(
        source.watchNeeds(householdId, week).listen((needs) {
          _needs[source.id] = needs;
          _publish();
        }, onError: _onError),
      );
    }
    _subscriptions
      ..add(
        _repository.watchItems(householdId).listen((items) {
          _items = items;
          _publish();
        }, onError: _onError),
      )
      ..add(
        _repository.watchPlanSettings(householdId).listen((settings) {
          _settings = settings;
          _publish();
        }, onError: _onError),
      );
  }

  void _publish() {
    final (items, settings) = (_items, _settings);
    if (items == null || settings == null) return;
    if (_sources.any((source) => !_needs.containsKey(source.id))) return;

    final proposals = GroceryProposal.merge([
      for (final source in _sources) ...?_needs[source.id],
    ]);
    final diff = GroceryPlanDiff.of(
      week: week.key,
      lines: [for (final proposal in proposals) _wording(proposal)],
      items: items,
      staples: settings.staples.toSet(),
      now: _now(),
    );
    _view = AsyncData(
      GroceryPlanView(
        week: week,
        diff: diff,
        settings: settings,
        canKeepInStep: canEdit && seesEverySource,
      ),
    );
    notifyListeners();
    if (settings.keepInStep && canEdit && seesEverySource) {
      _keeper.consider(
        GroceryPlanChanges.all(
          diff,
          existingIds: {for (final item in items) item.id},
        ),
      );
    }
  }

  void _onError(Object error) {
    _view = AsyncFailure(error is AppFailure ? error : UnknownFailure(error));
    notifyListeners();
  }

  Future<void> _cancel() async {
    final subscriptions = List.of(_subscriptions);
    _subscriptions.clear();
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
  }

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
