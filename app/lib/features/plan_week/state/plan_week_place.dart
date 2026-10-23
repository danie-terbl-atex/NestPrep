import '../../../shared/failure/app_failure.dart';
import '../../add_to_checkers/data/checkers_place_resolver.dart';
import '../../add_to_checkers/model/checkers_area.dart';
import '../../add_to_checkers/model/checkers_place.dart';

/// Where *Plan my week* shops (the brief's shop card): the area this phone
/// last chose for the household, else where the phone is, else the
/// resolver's own fallback city — which the brief names, so the parent can
/// change it.
final class PlanWeekPlace {
  PlanWeekPlace({
    required this._resolver,
    required this.householdId,
    required this.onChange,
  });

  final CheckersPlaceResolver _resolver;
  final String householdId;
  final void Function() onChange;

  CheckersPlace? _place;

  /// Null until it is known.
  CheckersPlace? get place => _place;

  /// Finds it once, for the brief. Unawaited by the controller, so it keeps
  /// its own failure: one that cannot be found is the fallback city.
  Future<void> restore() async {
    final place = await _orFallback();
    _place ??= place;
    onChange();
  }

  Future<void> choose(CheckersArea area) async {
    await _resolver.choose(householdId, area);
    _place = CheckersPlace.area(area);
    onChange();
  }

  /// The place, found now if it is not known yet.
  Future<CheckersPlace> resolved() async =>
      _place ??= await _resolver.resolve(householdId);

  /// The place, or the fallback city when it cannot be found.
  Future<CheckersPlace> resolvedOrFallback() async =>
      _place ??= await _orFallback();

  Future<CheckersPlace> _orFallback() async {
    try {
      return await _resolver.resolve(householdId);
    } on AppFailure {
      return const CheckersPlace.area(CheckersArea.fallback);
    }
  }
}
