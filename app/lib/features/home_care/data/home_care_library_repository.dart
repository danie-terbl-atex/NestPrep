import '../model/home_care_product.dart';
import '../model/home_care_room.dart';
import '../model/room_kind.dart';
import '../model/stock_level.dart';

/// The household's rooms and its product library (home-care ADR-0001,
/// ADR-0002). Everybody who sees home care reads both; only `edit` writes.
abstract interface class HomeCareLibraryRepository {
  /// Bounds on the two reads (`BE-08`): more rooms than a house has, more
  /// products than a cupboard holds.
  static const roomLimit = 60;
  static const productLimit = 120;

  Stream<List<HomeCareRoom>> watchRooms(String householdId);

  Stream<List<HomeCareProduct>> watchProducts(String householdId);

  /// Adds a room, or renames one when [roomId] is given.
  Future<void> saveRoom({
    required String householdId,
    String? roomId,
    required String name,
    required RoomKind kind,
    required String createdBy,
  });

  /// Adds several rooms in one write — the household's usual rooms, from the
  /// empty state.
  Future<void> addRooms({
    required String householdId,
    required List<({String name, RoomKind kind})> rooms,
    required String createdBy,
  });

  Future<void> deleteRoom({
    required String householdId,
    required String roomId,
  });

  /// Adds a product, or changes one when its id is not empty.
  Future<void> saveProduct({
    required String householdId,
    required HomeCareProduct product,
  });

  Future<void> deleteProduct({
    required String householdId,
    required String productId,
  });

  /// Marks how much of a product is left, in [by]'s name — the one write
  /// anybody who sees home care makes to the library. A level crossing into
  /// low puts it on the grocery list, by the server (home-care ADR-0005).
  Future<void> setStock({
    required String householdId,
    required String productId,
    required StockLevel level,
    required String by,
  });
}
