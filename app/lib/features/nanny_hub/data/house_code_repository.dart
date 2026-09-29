import '../model/house_code.dart';
import 'nanny_hub_repository.dart';

/// The house codes as Firestore holds them (nanny-hub ADR-0006). They are
/// **fetched from the server, never listened to**: nothing keeps them on a
/// screen once the shift's window closes, and a read the rules refuse is the
/// answer "not now" rather than a stale copy.
abstract interface class HouseCodeRepository {
  /// Every code, as the server has them now. Refused outside a booked shift
  /// for anybody but family.
  Future<List<HouseCode>> fetch(String householdId);

  Future<void> add(AuthoredBy by, HouseCodeDraft draft);

  Future<void> update(String householdId, String codeId, HouseCodeDraft draft);

  Future<void> remove(String householdId, String codeId);
}

/// A code as a parent typed it, tidied.
typedef HouseCodeDraft = ({String label, String value, String? note});
