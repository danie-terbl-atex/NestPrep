import 'dart:async';

import 'package:nestprep/features/nanny_hub/data/nanny_hub_repository.dart';
import 'package:nestprep/features/nanny_hub/model/care_routine.dart';
import 'package:nestprep/features/nanny_hub/model/checklist_item.dart';
import 'package:nestprep/features/nanny_hub/model/child_card.dart';
import 'package:nestprep/features/nanny_hub/model/contact_kind.dart';
import 'package:nestprep/features/nanny_hub/model/emergency_contact.dart';
import 'package:nestprep/features/nanny_hub/model/guide_spot.dart';
import 'package:nestprep/features/nanny_hub/model/home_sheet.dart';
import 'package:nestprep/features/nanny_hub/model/house_rule.dart';
import 'package:nestprep/features/nanny_hub/model/shift_checklist.dart';
import 'package:nestprep/features/nanny_hub/model/shift_moment.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

export 'fake_nanny_photos.dart';
export 'fake_nanny_shifts.dart';

/// The hub's authored records driven by hand: six live reads a test makes
/// arrive when it chooses, and a record of every write, so a test asserts
/// what a person's tap asked the backend to do (`FE-20`).
final class FakeNannyHubRepository implements NannyHubRepository {
  final cards = StreamController<List<ChildCard>>.broadcast();
  final contacts = StreamController<List<EmergencyContact>>.broadcast();
  final sheet = StreamController<HomeSheet>.broadcast();
  final guide = StreamController<List<GuideSpot>>.broadcast();
  final rules = StreamController<List<HouseRule>>.broadcast();
  final checklists = StreamController<List<ShiftChecklist>>.broadcast();

  /// Set to make the next writes fail the way a rules denial does.
  AppFailure? failWritesWith;

  /// Every write, in order, as `(method, arguments)`.
  final writes = <(String, Map<String, Object?>)>[];
  var _nextId = 0;

  /// Every authored read answers, with [cardList] and so on or nothing.
  void emitAll({
    List<ChildCard> cardList = const [],
    List<EmergencyContact> contactList = const [],
    HomeSheet home = HomeSheet.empty,
    List<GuideSpot> spots = const [],
    List<HouseRule> ruleList = const [],
    List<ShiftChecklist> lists = const [],
  }) {
    cards.add(cardList);
    contacts.add(contactList);
    sheet.add(home);
    guide.add(spots);
    rules.add(ruleList);
    checklists.add(lists);
  }

  Future<void> close() async {
    for (final controller in <StreamController<Object?>>[
      cards,
      contacts,
      sheet,
      guide,
      rules,
      checklists,
    ]) {
      await controller.close();
    }
  }

  Future<void> _record(String method, Map<String, Object?> arguments) async {
    final failure = failWritesWith;
    if (failure != null) throw failure;
    writes.add((method, arguments));
  }

  @override
  Stream<List<ChildCard>> watchCards(String householdId) => cards.stream;
  @override
  Stream<List<EmergencyContact>> watchContacts(String householdId) =>
      contacts.stream;
  @override
  Stream<HomeSheet> watchSheet(String householdId) => sheet.stream;
  @override
  Stream<List<GuideSpot>> watchGuide(String householdId) => guide.stream;
  @override
  Stream<List<HouseRule>> watchRules(String householdId) => rules.stream;
  @override
  Stream<List<ShiftChecklist>> watchChecklists(String householdId) =>
      checklists.stream;

  @override
  Future<void> saveRoutines(CardWrite write, List<CareRoutine> routines) =>
      _record('saveRoutines', {'write': write, 'routines': routines});
  @override
  Future<void> saveComfortItems(CardWrite write, List<String> comfortItems) =>
      _record('saveComfortItems', {'write': write, 'items': comfortItems});
  @override
  Future<void> saveCareNotes(
    CardWrite write, {
    required String? settling,
    required String? goodToKnow,
  }) => _record('saveCareNotes', {
    'write': write,
    'settling': settling,
    'goodToKnow': goodToKnow,
  });
  @override
  Future<void> saveCardPhoto(CardWrite write, String? photoId) =>
      _record('saveCardPhoto', {'write': write, 'photoId': photoId});
  @override
  Future<void> addContact(
    AuthoredBy by, {
    required String name,
    required ContactKind kind,
    required String phone,
    String? note,
  }) => _record('addContact', {
    'by': by,
    'name': name,
    'kind': kind,
    'phone': phone,
    'note': note,
  });
  @override
  Future<void> updateContact(
    String householdId,
    String contactId, {
    required String name,
    required ContactKind kind,
    required String phone,
    String? note,
  }) => _record('updateContact', {
    'contactId': contactId,
    'name': name,
    'kind': kind,
    'phone': phone,
    'note': note,
  });
  @override
  Future<void> removeContact(String householdId, String contactId) =>
      _record('removeContact', {'contactId': contactId});
  @override
  Future<void> saveSheet(AuthoredBy by, HomeSheet sheet) =>
      _record('saveSheet', {'by': by, 'sheet': sheet});
  @override
  Future<void> addGuideSpot(
    AuthoredBy by, {
    required String title,
    String? note,
    String? photoId,
  }) => _record('addGuideSpot', {
    'by': by,
    'title': title,
    'note': note,
    'photoId': photoId,
  });
  @override
  Future<void> updateGuideSpot(
    String householdId,
    String spotId, {
    required String title,
    String? note,
    String? photoId,
  }) => _record('updateGuideSpot', {
    'spotId': spotId,
    'title': title,
    'note': note,
    'photoId': photoId,
  });
  @override
  Future<void> removeGuideSpot(String householdId, String spotId) =>
      _record('removeGuideSpot', {'spotId': spotId});
  @override
  Future<void> addRule(AuthoredBy by, String text) =>
      _record('addRule', {'by': by, 'text': text});
  @override
  Future<void> updateRule(String householdId, String ruleId, String text) =>
      _record('updateRule', {'ruleId': ruleId, 'text': text});
  @override
  Future<void> removeRule(String householdId, String ruleId) =>
      _record('removeRule', {'ruleId': ruleId});
  @override
  Future<void> saveChecklist(
    AuthoredBy by,
    ShiftMoment moment,
    List<ChecklistItem> items,
  ) => _record('saveChecklist', {'by': by, 'moment': moment, 'items': items});
  @override
  String newItemId(String householdId) => 'item-${_nextId++}';
}
