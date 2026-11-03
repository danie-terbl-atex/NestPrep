import '../model/family_place.dart';

abstract interface class PlacesRepository {
  Stream<List<FamilyPlace>> watchPlaces(String householdId);

  /// A new place when [place]'s id is empty.
  Future<void> save(String householdId, FamilyPlace place);

  Future<void> delete(String householdId, String placeId);
}
