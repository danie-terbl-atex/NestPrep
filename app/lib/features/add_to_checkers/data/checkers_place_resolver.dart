import '../../live_location/data/location_source.dart';
import '../model/checkers_area.dart';
import '../model/checkers_place.dart';
import 'checkers_area_preference.dart';

/// Decides where a product search looks (the Checkers build contract): the
/// area chosen on this phone first — a choice beats the device — then the
/// phone's position when location is already allowed (never asking), and
/// Cape Town when there is neither.
final class CheckersPlaceResolver {
  const CheckersPlaceResolver({
    required LocationSource locationSource,
    required CheckersAreaPreference areaPreference,
  }) : _location = locationSource,
       _areas = areaPreference;

  final LocationSource _location;
  final CheckersAreaPreference _areas;

  Future<CheckersPlace> resolve(String householdId) async {
    final chosen = await _areas.read(householdId);
    if (chosen != null) return CheckersPlace.area(chosen);
    final here = await _location.positionIfAlreadyAllowed();
    if (here != null) return CheckersPlace.device(here);
    return const CheckersPlace.area(CheckersArea.fallback);
  }

  Future<void> choose(String householdId, CheckersArea area) =>
      _areas.write(householdId, area);
}
