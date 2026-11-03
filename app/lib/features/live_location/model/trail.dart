import 'coordinates.dart';

/// One recorded point of a member's day (live-location ADR-0004).
class TrailPoint {
  const TrailPoint({
    required this.at,
    required this.point,
    required this.accuracyMetres,
  });

  final DateTime at;
  final Coordinates point;
  final int accuracyMetres;
}

enum PlaceEventKind { arrive, leave }

/// A phone reaching or leaving one of the household's places.
class PlaceEvent {
  const PlaceEvent({
    required this.placeId,
    required this.kind,
    required this.at,
  });

  final String placeId;
  final PlaceEventKind kind;
  final DateTime at;
}

/// Everything recorded about one member on one household-local day.
class TrailDay {
  const TrailDay({required this.points, required this.events});

  static const empty = TrailDay(points: [], events: []);

  /// In time order.
  final List<TrailPoint> points;
  final List<PlaceEvent> events;

  bool get isEmpty => points.isEmpty && events.isEmpty;
}
