import 'coordinates.dart';

enum PlaceIcon { home, school, work, sport, shop, family, other }

/// One of the household's places at `households/{id}/places/{placeId}`
/// (live-location ADR-0006): watched as a geofence on every sharing phone.
class FamilyPlace {
  const FamilyPlace({
    required this.id,
    required this.name,
    required this.centre,
    required this.radiusMetres,
    required this.icon,
    required this.alertOnArrive,
    required this.alertOnLeave,
  });

  static const smallestRadius = 75;
  static const largestRadius = 500;
  static const defaultRadius = 150;
  static const longestName = 40;
  static const householdLimit = 30;

  final String id;
  final String name;
  final Coordinates centre;
  final int radiusMetres;
  final PlaceIcon icon;
  final bool alertOnArrive;
  final bool alertOnLeave;

  bool contains(Coordinates point) => centre.metresTo(point) <= radiusMetres;

  FamilyPlace copyWith({
    String? name,
    Coordinates? centre,
    int? radiusMetres,
    PlaceIcon? icon,
    bool? alertOnArrive,
    bool? alertOnLeave,
  }) => FamilyPlace(
    id: id,
    name: name ?? this.name,
    centre: centre ?? this.centre,
    radiusMetres: radiusMetres ?? this.radiusMetres,
    icon: icon ?? this.icon,
    alertOnArrive: alertOnArrive ?? this.alertOnArrive,
    alertOnLeave: alertOnLeave ?? this.alertOnLeave,
  );

  /// The place a point is inside, the smallest first when two overlap.
  static FamilyPlace? at(Coordinates point, List<FamilyPlace> places) {
    final inside = [
      for (final place in places)
        if (place.contains(point)) place,
    ]..sort((a, b) => a.radiusMetres.compareTo(b.radiusMetres));
    return inside.firstOrNull;
  }
}
