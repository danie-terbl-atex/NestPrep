import '../data/home_care_library_repository.dart';
import '../model/home_care_product.dart';
import '../model/room_kind.dart';

/// The writes a manager makes to the rooms and the product library, each
/// through the controller's runner so a refusal reaches the screen's banner
/// (`FE-09`).
final class HomeCareLibraryEdits {
  HomeCareLibraryEdits({
    required HomeCareLibraryRepository libraryRepository,
    required this.householdId,
    required this._memberId,
    required Future<void> Function(Future<void> Function()) runAction,
  }) : _library = libraryRepository,
       _run = runAction;

  final HomeCareLibraryRepository _library;
  final String householdId;
  final String Function() _memberId;
  final Future<void> Function(Future<void> Function()) _run;

  /// The rooms most homes have, offered from the empty rooms list so a new
  /// household is one tap from a job. The names are the copy's.
  Future<void> addRooms(List<({String name, RoomKind kind})> rooms) => _run(
    () => _library.addRooms(
      householdId: householdId,
      rooms: rooms,
      createdBy: _memberId(),
    ),
  );

  Future<void> saveRoom({
    String? roomId,
    required String name,
    required RoomKind kind,
  }) => _run(
    () => _library.saveRoom(
      householdId: householdId,
      roomId: roomId,
      name: name.trim(),
      kind: kind,
      createdBy: _memberId(),
    ),
  );

  Future<void> deleteRoom(String roomId) =>
      _run(() => _library.deleteRoom(householdId: householdId, roomId: roomId));

  /// Adds a product (an empty id) or changes one, stamped with the viewer.
  Future<void> saveProduct(HomeCareProduct product) => _run(
    () => _library.saveProduct(
      householdId: householdId,
      product: product.id.isEmpty
          ? product.copyWith(createdBy: _memberId())
          : product,
    ),
  );

  Future<void> deleteProduct(String productId) => _run(
    () =>
        _library.deleteProduct(householdId: householdId, productId: productId),
  );
}
