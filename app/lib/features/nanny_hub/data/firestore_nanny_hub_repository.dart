import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/care_routine.dart';
import '../model/checklist_item.dart';
import '../model/child_card.dart';
import '../model/contact_kind.dart';
import '../model/emergency_contact.dart';
import '../model/guide_spot.dart';
import '../model/home_sheet.dart';
import '../model/house_rule.dart';
import '../model/nanny_limits.dart';
import '../model/shift_checklist.dart';
import '../model/shift_moment.dart';
import 'nanny_hub_repository.dart';
import 'nanny_paths.dart';

final class FirestoreNannyHubRepository implements NannyHubRepository {
  FirestoreNannyHubRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _raw(
    String householdId,
    String path,
  ) => _firestore
      .collection(NannyPaths.households)
      .doc(householdId)
      .collection(path);

  CollectionReference<T> _typed<T>(
    String householdId,
    String path,
    T Function(Map<String, Object?> json) fromJson,
  ) => typedCollection(
    _raw(householdId, path),
    fromJson: fromJson,
    // The app writes these through the maps below, never a whole model.
    toJson: (_) => throw UnsupportedError('written field by field'),
  );

  /// Every read here is bounded where it is built, beside its `.limit`
  /// (`BE-08`); this only unwraps the documents and translates a failure.
  Stream<List<T>> _list<T>(Stream<QuerySnapshot<T>> snapshots) => snapshots
      .map((snapshot) => [for (final doc in snapshot.docs) doc.data()])
      .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<List<ChildCard>> watchCards(String householdId) => _list(
    _typed(
      householdId,
      NannyPaths.cards,
      ChildCard.fromJson,
    ).limit(NannyLimits.cardListen).snapshots(),
  );

  @override
  Stream<List<EmergencyContact>> watchContacts(String householdId) => _list(
    _typed(
      householdId,
      NannyPaths.contacts,
      EmergencyContact.fromJson,
    ).limit(NannyLimits.contactListen).snapshots(),
  );

  @override
  Stream<HomeSheet> watchSheet(String householdId) =>
      _typed(householdId, NannyPaths.home, HomeSheet.fromJson)
          .doc(HomeSheet.documentId)
          .snapshots()
          .map((snapshot) => snapshot.data() ?? HomeSheet.empty)
          .handleError((Object error) => throw failureFromFirebase(error));

  @override
  Stream<List<GuideSpot>> watchGuide(String householdId) => _list(
    _typed(
      householdId,
      NannyPaths.guide,
      GuideSpot.fromJson,
    ).orderBy('createdAt').limit(NannyLimits.guideListen).snapshots(),
  );

  @override
  Stream<List<HouseRule>> watchRules(String householdId) => _list(
    _typed(
      householdId,
      NannyPaths.rules,
      HouseRule.fromJson,
    ).orderBy('createdAt').limit(NannyLimits.ruleListen).snapshots(),
  );

  @override
  Stream<List<ShiftChecklist>> watchChecklists(String householdId) => _list(
    _typed(
      householdId,
      NannyPaths.checklists,
      ShiftChecklist.fromJson,
    ).limit(ShiftMoment.values.length).snapshots(),
  );

  @override
  Future<void> saveRoutines(CardWrite write, List<CareRoutine> routines) =>
      _mergeCard(write, {
        'routines': [for (final routine in routines) routine.toJson()],
      });

  @override
  Future<void> saveComfortItems(CardWrite write, List<String> comfortItems) =>
      _mergeCard(write, {'comfortItems': comfortItems});

  @override
  Future<void> saveCareNotes(
    CardWrite write, {
    required String? settling,
    required String? goodToKnow,
  }) => _mergeCard(write, {'settling': settling, 'goodToKnow': goodToKnow});

  @override
  Future<void> saveCardPhoto(CardWrite write, String? photoId) =>
      _mergeCard(write, {'photoId': photoId});

  /// A card is created by its first section, so every write is a merge that
  /// names who made it and lets the server say when.
  Future<void> _mergeCard(CardWrite write, Map<String, Object?> fields) =>
      _guarded(
        () => _raw(write.householdId, NannyPaths.cards).doc(write.childId).set({
          ...fields,
          'updatedBy': write.memberId,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
      );

  @override
  Future<void> addContact(
    AuthoredBy by, {
    required String name,
    required ContactKind kind,
    required String phone,
    String? note,
  }) => _guarded(
    () => _raw(by.householdId, NannyPaths.contacts).add({
      ..._contactFields(name: name, kind: kind, phone: phone, note: note),
      'createdBy': by.memberId,
      'createdAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> updateContact(
    String householdId,
    String contactId, {
    required String name,
    required ContactKind kind,
    required String phone,
    String? note,
  }) => _guarded(
    () => _raw(householdId, NannyPaths.contacts)
        .doc(contactId)
        .update(
          _contactFields(name: name, kind: kind, phone: phone, note: note),
        ),
  );

  static Map<String, Object?> _contactFields({
    required String name,
    required ContactKind kind,
    required String phone,
    String? note,
  }) => {'name': name, 'kind': kind.name, 'phone': phone, 'note': note};

  @override
  Future<void> removeContact(String householdId, String contactId) =>
      _delete(householdId, NannyPaths.contacts, contactId);

  @override
  Future<void> saveSheet(AuthoredBy by, HomeSheet sheet) => _guarded(
    () => _raw(by.householdId, NannyPaths.home).doc(HomeSheet.documentId).set({
      'address': sheet.address,
      'medicalAidScheme': sheet.medicalAidScheme,
      'medicalAidPlan': sheet.medicalAidPlan,
      'medicalAidNumber': sheet.medicalAidNumber,
      'updatedBy': by.memberId,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> addGuideSpot(
    AuthoredBy by, {
    required String title,
    String? note,
    String? photoId,
  }) => _guarded(
    () => _raw(by.householdId, NannyPaths.guide).add({
      'title': title,
      'note': note,
      'photoId': photoId,
      'createdBy': by.memberId,
      'createdAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> updateGuideSpot(
    String householdId,
    String spotId, {
    required String title,
    String? note,
    String? photoId,
  }) => _guarded(
    () => _raw(
      householdId,
      NannyPaths.guide,
    ).doc(spotId).update({'title': title, 'note': note, 'photoId': photoId}),
  );

  @override
  Future<void> removeGuideSpot(String householdId, String spotId) =>
      _delete(householdId, NannyPaths.guide, spotId);

  @override
  Future<void> addRule(AuthoredBy by, String text) => _guarded(
    () => _raw(by.householdId, NannyPaths.rules).add({
      'text': text,
      'createdBy': by.memberId,
      'createdAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> updateRule(String householdId, String ruleId, String text) =>
      _guarded(
        () => _raw(
          householdId,
          NannyPaths.rules,
        ).doc(ruleId).update({'text': text}),
      );

  @override
  Future<void> removeRule(String householdId, String ruleId) =>
      _delete(householdId, NannyPaths.rules, ruleId);

  @override
  Future<void> saveChecklist(
    AuthoredBy by,
    ShiftMoment moment,
    List<ChecklistItem> items,
  ) => _guarded(
    () => _raw(by.householdId, NannyPaths.checklists).doc(moment.name).set({
      'items': [for (final item in items) item.toJson()],
      'updatedBy': by.memberId,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  String newItemId(String householdId) =>
      _raw(householdId, NannyPaths.checklists).doc().id;

  Future<void> _delete(String householdId, String path, String id) =>
      _guarded(() => _raw(householdId, path).doc(id).delete());

  Future<void> _guarded(Future<Object?> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
