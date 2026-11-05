import '../model/list_photo.dart';
import '../model/list_reading.dart';

/// Reads a shopping list photo into proposed lines (list-scan ADR-0001).
abstract interface class ListScanReader {
  Future<ListReading> read({
    required String householdId,
    required ListPhoto photo,
  });
}
