import '../../features/home_care/model/product_kind.dart';
import '../../features/home_care/model/room_kind.dart';

/// Every word the rooms and product library say (`FE-19`), reached through
/// `home_care_copy.dart` (home-care ADR-0001, ADR-0002).
abstract final class HomeCareLibraryCopy {
  static const rooms = 'Rooms';
  static const addRoom = 'Add a room';
  static const editRoom = 'Change the room';
  static const roomName = 'Name';
  static const roomNameHint = 'Like “Lily’s room”';
  static const roomKind = 'Kind of room';
  static const deleteRoom = 'Delete the room';
  static const deleteRoomConfirm = 'Delete this room?';
  static const deleteRoomBody =
      'Jobs tagged with it stay, and say the room was removed.';
  static const roomsEmptyTitle = 'No rooms yet';
  static const roomsEmptyBody =
      'Add the rooms of your home, so every job says where.';
  static const roomsEmptyHelperBody = 'A parent adds the rooms of the home.';
  static const addUsualRooms = 'Add the usual rooms';
  static const noRoomsYet =
      'No rooms yet. Add them from Rooms on the Home care screen.';

  static String openJobs(int count) => switch (count) {
    0 => 'Nothing to clean',
    1 => '1 open job',
    _ => '$count open jobs',
  };

  /// What most homes have, added in one tap from the empty rooms list.
  static const usualRooms = [
    (name: 'Kitchen', kind: RoomKind.kitchen),
    (name: 'Lounge', kind: RoomKind.lounge),
    (name: 'Main bedroom', kind: RoomKind.bedroom),
    (name: 'Bathroom', kind: RoomKind.bathroom),
    (name: 'Laundry', kind: RoomKind.laundry),
    (name: 'Outside', kind: RoomKind.outside),
  ];

  static String roomKindName(RoomKind kind) => switch (kind) {
    RoomKind.kitchen => 'Kitchen',
    RoomKind.lounge => 'Lounge',
    RoomKind.dining => 'Dining room',
    RoomKind.bedroom => 'Bedroom',
    RoomKind.kidsRoom => 'Children’s room',
    RoomKind.bathroom => 'Bathroom',
    RoomKind.laundry => 'Laundry',
    RoomKind.office => 'Study',
    RoomKind.outside => 'Outside',
    RoomKind.garage => 'Garage',
    RoomKind.other => 'Other',
  };

  static const products = 'Products';
  static const productsSubtitle = 'What you clean with, and how to use it';
  static const addProduct = 'Add a product';
  static const editProduct = 'Change the product';
  static const productName = 'Name';
  static const productNameHint = 'What the household calls it, like “Jik”';
  static const productKind = 'What kind of product it is';
  static const whereKept = 'Where it is kept';
  static const whereKeptHint = 'Like “Under the kitchen sink”';
  static const productNote = 'Anything else';
  static const deleteProduct = 'Delete the product';
  static const deleteProductConfirm = 'Delete this product?';
  static const deleteProductBody = 'Jobs that use it will stop listing it.';
  static const productsEmptyTitle = 'No products yet';
  static const productsEmptyBody =
      'Add what you clean with, so each job can say what to use — and what '
      'never to mix.';
  static const productsEmptyHelperBody =
      'A parent adds the household’s cleaning products.';
  static const noProductsYet =
      'No products yet. Add them from Products on the Home care screen.';
  static String kindAndPlace(String kind, String place) => '$kind · $place';
  static const placeUnknown = 'Where it is kept is not written down';

  static String productKindName(ProductKind kind) => switch (kind) {
    ProductKind.bleach => 'Chlorine bleach',
    ProductKind.ammonia => 'Ammonia-based',
    ProductKind.acidic => 'Acidic',
    ProductKind.alcohol => 'Alcohol-based',
    ProductKind.peroxide => 'Hydrogen peroxide',
    ProductKind.ovenCleaner => 'Oven cleaner',
    ProductKind.drainCleaner => 'Drain cleaner',
    ProductKind.disinfectant => 'Disinfectant',
    ProductKind.allPurpose => 'All-purpose cleaner',
    ProductKind.dishSoap => 'Dish soap',
    ProductKind.bicarbonate => 'Bicarbonate of soda',
    ProductKind.polish => 'Polish or aerosol',
    ProductKind.floorCleaner => 'Floor cleaner',
    ProductKind.other => 'Something else',
  };

  /// What each kind covers, under the picker — the kind is what the safety
  /// warnings are read from, so it is worth a line of help.
  static String productKindExamples(ProductKind kind) => switch (kind) {
    ProductKind.bleach =>
      'Like Jik or thick bleach — sodium hypochlorite on the label.',
    ProductKind.ammonia =>
      'Some glass and window cleaners — ammonia on the label.',
    ProductKind.acidic =>
      'Vinegar, limescale and kettle descalers, many toilet cleaners.',
    ProductKind.alcohol =>
      'Surgical or methylated spirits, rubbing alcohol, some wipes.',
    ProductKind.peroxide =>
      'Hydrogen peroxide, and oxygen bleach like stain-remover powders.',
    ProductKind.ovenCleaner => 'Oven and grill cleaners — most are caustic.',
    ProductKind.drainCleaner => 'Drain unblockers: gels, liquids, crystals.',
    ProductKind.disinfectant =>
      'Pine gels and antiseptic liquids that are not bleach.',
    ProductKind.allPurpose => 'Everyday spray and cream cleaners.',
    ProductKind.dishSoap => 'Washing-up liquid.',
    ProductKind.bicarbonate => 'Baking soda.',
    ProductKind.polish => 'Furniture polish, and anything in a spray can.',
    ProductKind.floorCleaner => 'Floor washes and tile cleaners.',
    ProductKind.other => 'Anything else — read its label for how to use it.',
  };
}
