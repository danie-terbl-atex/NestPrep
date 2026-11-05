part of 'app_failure.dart';

// ---- snap a shopping list (list-scan ADR-0001) ----

/// Why a shopping list photo could not be read or its lines added. The first
/// four are the server's `LIST_SCAN_REFUSALS`, which
/// `list_scan_contract_test.dart` reads; the rest are the phone's.
enum ListScanProblem {
  /// The `snapShoppingList` switch is off.
  listScanOff,

  /// The caller may not add to the household's grocery list.
  groceriesNotShared,

  listPhotoTooLarge,

  /// Not a photo NestPrep can read.
  listPhotoNotSupported,

  /// The camera or the photo library would not open.
  pickerUnavailable,
}

final class ListScanFailure extends AppFailure {
  const ListScanFailure(this.problem);

  final ListScanProblem problem;
}
