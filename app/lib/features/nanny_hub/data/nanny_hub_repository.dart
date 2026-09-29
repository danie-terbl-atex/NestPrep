import '../model/care_routine.dart';
import '../model/checklist_item.dart';
import '../model/child_card.dart';
import '../model/contact_kind.dart';
import '../model/emergency_contact.dart';
import '../model/guide_spot.dart';
import '../model/home_sheet.dart';
import '../model/house_rule.dart';
import '../model/shift_checklist.dart';
import '../model/shift_moment.dart';

/// What parents author for a carer, as Firestore holds it (nanny-hub
/// ADR-0003). Every read is bounded (`BE-08`); every write names the member
/// making it, which the rules check (`BE-03`).
///
/// A card is written a section at a time as a merge, so two parents editing
/// the routine and the comfort items at once never overwrite each other.
abstract interface class NannyHubRepository {
  Stream<List<ChildCard>> watchCards(String householdId);
  Stream<List<EmergencyContact>> watchContacts(String householdId);

  /// `HomeSheet.empty` until somebody fills it in.
  Stream<HomeSheet> watchSheet(String householdId);
  Stream<List<GuideSpot>> watchGuide(String householdId);
  Stream<List<HouseRule>> watchRules(String householdId);
  Stream<List<ShiftChecklist>> watchChecklists(String householdId);

  Future<void> saveRoutines(CardWrite write, List<CareRoutine> routines);
  Future<void> saveComfortItems(CardWrite write, List<String> comfortItems);

  /// How to settle them, and anything else worth knowing. Blank is null.
  Future<void> saveCareNotes(
    CardWrite write, {
    required String? settling,
    required String? goodToKnow,
  });

  Future<void> saveCardPhoto(CardWrite write, String? photoId);

  Future<void> addContact(
    AuthoredBy by, {
    required String name,
    required ContactKind kind,
    required String phone,
    String? note,
  });

  Future<void> updateContact(
    String householdId,
    String contactId, {
    required String name,
    required ContactKind kind,
    required String phone,
    String? note,
  });

  Future<void> removeContact(String householdId, String contactId);

  Future<void> saveSheet(AuthoredBy by, HomeSheet sheet);

  Future<void> addGuideSpot(
    AuthoredBy by, {
    required String title,
    String? note,
    String? photoId,
  });

  Future<void> updateGuideSpot(
    String householdId,
    String spotId, {
    required String title,
    String? note,
    String? photoId,
  });

  Future<void> removeGuideSpot(String householdId, String spotId);

  Future<void> addRule(AuthoredBy by, String text);
  Future<void> updateRule(String householdId, String ruleId, String text);
  Future<void> removeRule(String householdId, String ruleId);

  Future<void> saveChecklist(
    AuthoredBy by,
    ShiftMoment moment,
    List<ChecklistItem> items,
  );

  /// A new id for a checklist item, unique enough to key a tick.
  String newItemId(String householdId);
}

/// Who is writing, in which household — what every authored record carries.
typedef AuthoredBy = ({String householdId, String memberId});

/// One section of one child's card, by one member.
typedef CardWrite = ({String householdId, String childId, String memberId});
