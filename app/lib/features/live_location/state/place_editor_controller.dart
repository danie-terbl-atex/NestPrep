import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../data/location_source.dart';
import '../data/places_repository.dart';
import '../model/coordinates.dart';
import '../model/family_place.dart';

final class PlaceEditorController extends ChangeNotifier
    with ActionFailureHolder {
  PlaceEditorController({
    required PlacesRepository placesRepository,
    required LocationSource locationSource,
    required this.householdId,
    FamilyPlace? place,
    Coordinates? startAt,
  }) : _repository = placesRepository,
       _source = locationSource,
       isNew = place == null,
       _draft =
           place ??
           FamilyPlace(
             id: '',
             name: '',
             centre: startAt ?? const Coordinates(latitude: 0, longitude: 0),
             radiusMetres: FamilyPlace.defaultRadius,
             icon: PlaceIcon.home,
             alertOnArrive: true,
             alertOnLeave: false,
           ),
       _hasCentre = place != null || startAt != null;

  final PlacesRepository _repository;
  final LocationSource _source;
  final String householdId;
  final bool isNew;
  FamilyPlace _draft;
  bool _hasCentre;
  bool _saving = false;
  int _jumps = 0;

  /// How many times the centre was moved by something other than the map —
  /// the map follows each one.
  int get jumps => _jumps;

  FamilyPlace get draft => _draft;
  bool get hasCentre => _hasCentre;
  bool get saving => _saving;

  bool get canSave =>
      !_saving &&
      _hasCentre &&
      _draft.name.trim().isNotEmpty &&
      _draft.name.trim().length <= FamilyPlace.longestName;

  void rename(String name) => _change(_draft.copyWith(name: name));
  void moveTo(Coordinates centre) {
    _hasCentre = true;
    _change(_draft.copyWith(centre: centre));
  }

  void resize(int metres) => _change(
    _draft.copyWith(
      radiusMetres: metres.clamp(
        FamilyPlace.smallestRadius,
        FamilyPlace.largestRadius,
      ),
    ),
  );
  void chooseIcon(PlaceIcon icon) => _change(_draft.copyWith(icon: icon));
  void alertOnArrive({required bool on}) =>
      _change(_draft.copyWith(alertOnArrive: on));
  void alertOnLeave({required bool on}) =>
      _change(_draft.copyWith(alertOnLeave: on));

  Future<void> useWhereIAm() => runAction(() async {
    if (await _source.requestConsent() != LocationConsent.granted) {
      throw const LocationFailure(LocationProblem.permissionRefused);
    }
    final here = await _source.positionIfAlreadyAllowed();
    if (here == null) return;
    _jumps++;
    moveTo(here);
  });

  /// True once it is saved.
  Future<bool> save() async {
    if (!canSave) return false;
    _saving = true;
    notifyListeners();
    await runAction(() => _repository.save(householdId, _draft));
    _saving = false;
    notifyListeners();
    return actionFailure == null;
  }

  Future<bool> delete() async {
    await runAction(() => _repository.delete(householdId, _draft.id));
    return actionFailure == null;
  }

  void _change(FamilyPlace next) {
    _draft = next;
    notifyListeners();
  }
}
