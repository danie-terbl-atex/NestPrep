import 'coordinates.dart';
import 'family_place.dart';
import 'trail.dart';

sealed class TimelineEntry {
  const TimelineEntry({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  Duration get length => to.difference(from);
}

/// Somewhere a member stayed for at least [Timeline.shortestStop].
final class TimelineStop extends TimelineEntry {
  const TimelineStop({
    required super.from,
    required super.to,
    required this.centre,
    this.place,
  });

  final Coordinates centre;
  final FamilyPlace? place;
}

/// The movement between two stops.
final class TimelineJourney extends TimelineEntry {
  const TimelineJourney({
    required super.from,
    required super.to,
    required this.metres,
    required this.path,
  });

  final double metres;
  final List<Coordinates> path;
}

/// A day's points read as stops and journeys, on the phone, from the one day
/// document (live-location ADR-0004).
abstract final class Timeline {
  static const stopRadiusMetres = 120.0;
  static const shortestStop = Duration(minutes: 5);

  /// A lone point followed by this much silence: the phone went still and
  /// stopped recording, which a moving phone recording every five minutes
  /// never does.
  static const quietStop = Duration(minutes: 10);

  static List<TimelineEntry> of(TrailDay day, List<FamilyPlace> places) {
    final points = day.points;
    final entries = <TimelineEntry>[];
    final moving = <TrailPoint>[];
    var i = 0;
    while (i < points.length) {
      final anchor = points[i];
      var j = i;
      while (j + 1 < points.length &&
          points[j + 1].point.metresTo(anchor.point) <= stopRadiusMetres) {
        j++;
      }
      // Nothing is recorded while a phone sits still, so a stay lasts until
      // the next point that has moved away, not until the last one recorded.
      final until = j + 1 < points.length ? points[j + 1].at : points[j].at;
      final stayed = j > i
          ? points[j].at.difference(anchor.at) >= shortestStop
          : until.difference(anchor.at) >= quietStop;
      if (stayed) {
        _closeJourney(entries, moving, endsAt: anchor);
        final centre = _centreOf(points.sublist(i, j + 1));
        entries.add(
          TimelineStop(
            from: anchor.at,
            to: until,
            centre: centre,
            place: FamilyPlace.at(centre, places),
          ),
        );
        moving
          ..clear()
          ..add(points[j]);
        i = j + 1;
      } else {
        moving.add(anchor);
        i++;
      }
    }
    _closeJourney(entries, moving);
    return entries;
  }

  static void _closeJourney(
    List<TimelineEntry> entries,
    List<TrailPoint> moving, {
    TrailPoint? endsAt,
  }) {
    final path = [...moving, ?endsAt];
    if (path.length < 2) return;
    var metres = 0.0;
    for (var k = 1; k < path.length; k++) {
      metres += path[k - 1].point.metresTo(path[k].point);
    }
    entries.add(
      TimelineJourney(
        from: path.first.at,
        to: path.last.at,
        metres: metres,
        path: [for (final point in path) point.point],
      ),
    );
  }

  static Coordinates _centreOf(List<TrailPoint> points) {
    var latitude = 0.0;
    var longitude = 0.0;
    for (final point in points) {
      latitude += point.point.latitude;
      longitude += point.point.longitude;
    }
    return Coordinates(
      latitude: latitude / points.length,
      longitude: longitude / points.length,
    );
  }
}
