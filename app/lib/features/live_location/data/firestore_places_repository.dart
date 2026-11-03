import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../model/coordinates.dart';
import '../model/family_place.dart';
import 'places_repository.dart';

final class FirestorePlacesRepository implements PlacesRepository {
  FirestorePlacesRepository(this._firestore);

  static const placesPath = 'places';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _places(String householdId) =>
      _firestore
          .collection('households')
          .doc(householdId)
          .collection(placesPath);

  @override
  Stream<List<FamilyPlace>> watchPlaces(String householdId) =>
      _places(householdId)
          .limit(FamilyPlace.householdLimit)
          .snapshots()
          .map(
            (snapshot) => [
              for (final document in snapshot.docs)
                ?placeFrom(document.id, document.data()),
            ],
          )
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Future<void> save(String householdId, FamilyPlace place) => _guarded(() {
    final places = _places(householdId);
    final document = place.id.isEmpty ? places.doc() : places.doc(place.id);
    return document.set(placeData(place));
  });

  @override
  Future<void> delete(String householdId, String placeId) =>
      _guarded(() => _places(householdId).doc(placeId).delete());

  static Map<String, Object> placeData(FamilyPlace place) => {
    'name': place.name.trim(),
    'centre': GeoPoint(place.centre.latitude, place.centre.longitude),
    'radiusMetres': place.radiusMetres,
    'icon': place.icon.name,
    'alerts': {'arrive': place.alertOnArrive, 'leave': place.alertOnLeave},
    'updatedAt': FieldValue.serverTimestamp(),
  };

  static FamilyPlace? placeFrom(String id, Map<String, dynamic> data) {
    final centre = data['centre'];
    final name = data['name'];
    final radius = data['radiusMetres'];
    if (centre is! GeoPoint || name is! String || radius is! int) return null;
    final alerts = data['alerts'];
    return FamilyPlace(
      id: id,
      name: name,
      centre: Coordinates(
        latitude: centre.latitude,
        longitude: centre.longitude,
      ),
      radiusMetres: radius,
      icon: PlaceIcon.values.asNameMap()[data['icon']] ?? PlaceIcon.other,
      alertOnArrive: alerts is Map && alerts['arrive'] == true,
      alertOnLeave: alerts is Map && alerts['leave'] == true,
    );
  }

  Future<void> _guarded(Future<void> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
