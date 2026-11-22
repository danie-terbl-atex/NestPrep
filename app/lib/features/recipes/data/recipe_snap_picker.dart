import '../../../shared/failure/app_failure.dart';
import '../../list_scan/data/list_photo_picker.dart';
import '../model/recipe_snap.dart';

/// What one visit to the camera or the photos brought back: the photos that
/// could be read, and why any other could not.
final class RecipeSnapPick {
  const RecipeSnapPick({this.snaps = const [], this.problem});

  final List<RecipeSnap> snaps;
  final AppFailure? problem;
}

abstract interface class RecipeSnapPicker {
  /// At most [photoRoom] photos of [partRoom] parts between them; none when
  /// the person backed out. Throws `ListScanFailure(pickerUnavailable)` when
  /// nothing would open.
  Future<RecipeSnapPick> pick(
    ListPhotoSource source, {
    required int photoRoom,
    required int partRoom,
  });
}
