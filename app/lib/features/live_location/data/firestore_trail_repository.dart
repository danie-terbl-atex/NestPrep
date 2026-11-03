import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/coordinates.dart';
import '../model/trail.dart';
import 'trail_repository.dart';

final class FirestoreTrailRepository implements TrailRepository {
  FirestoreTrailRepository(this._firestore);

  static const trailsPath = 'locationTrails';
  static const daysPath = 'trailDays';
  static const eventsPath = 'placeEvents';

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _trail(
    String householdId,
    String memberId,
  ) => _firestore
      .collection('households')
      .doc(householdId)
      .collection(trailsPath)
      .doc(memberId);

  @override
  Future<TrailDay> loadDay({
    required String householdId,
    required String memberId,
    required CalendarDate day,
    required DateTime from,
    required DateTime to,
  }) async {
    final trail = _trail(householdId, memberId);
    try {
      final dayRead = trail.collection(daysPath).doc(day.iso).get();
      final eventsRead = trail
          .collection(eventsPath)
          .where('at', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .where('at', isLessThan: Timestamp.fromDate(to))
          .limit(TrailRepository.eventLimit)
          .get();
      final read = await Future.wait<Object>([dayRead, eventsRead]);
      final dayDocument = read[0] as DocumentSnapshot<Map<String, dynamic>>;
      final events = read[1] as QuerySnapshot<Map<String, dynamic>>;
      return TrailDay(
        points: pointsFrom(dayDocument.data()),
        events: [
          for (final document in events.docs) ?eventFrom(document.data()),
        ]..sort((a, b) => a.at.compareTo(b.at)),
      );
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }

  @override
  Future<void> clearHistory({
    required String householdId,
    required String memberId,
  }) async {
    final trail = _trail(householdId, memberId);
    try {
      for (final path in [daysPath, eventsPath]) {
        while (true) {
          final page = await trail.collection(path).limit(100).get();
          if (page.docs.isEmpty) break;
          final batch = _firestore.batch();
          for (final document in page.docs) {
            batch.delete(document.reference);
          }
          await batch.commit();
        }
      }
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }

  /// The device writes these; a point that does not parse is skipped, never a
  /// failed day (`BE-10`).
  static List<TrailPoint> pointsFrom(Map<String, dynamic>? data) {
    final raw = data?['points'];
    if (raw is! List) return const [];
    final points = <TrailPoint>[
      for (final entry in raw)
        if (entry is Map &&
            entry['t'] is int &&
            entry['la'] is num &&
            entry['lo'] is num)
          TrailPoint(
            at: DateTime.fromMillisecondsSinceEpoch(
              (entry['t'] as int) * 1000,
              isUtc: true,
            ),
            point: Coordinates(
              latitude: (entry['la'] as num).toDouble(),
              longitude: (entry['lo'] as num).toDouble(),
            ),
            accuracyMetres: entry['ac'] is int ? entry['ac'] as int : 0,
          ),
    ]..sort((a, b) => a.at.compareTo(b.at));
    return points;
  }

  static PlaceEvent? eventFrom(Map<String, dynamic> data) {
    final at = data['at'];
    final placeId = data['placeId'];
    final kind = PlaceEventKind.values.asNameMap()[data['kind']];
    if (at is! Timestamp || placeId is! String || kind == null) return null;
    return PlaceEvent(placeId: placeId, kind: kind, at: at.toDate().toUtc());
  }
}
