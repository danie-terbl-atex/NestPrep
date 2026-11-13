import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/avatar_buddy.dart';
import '../model/avatar_choice.dart';
import '../model/avatar_creation.dart';
import '../model/avatar_keepsake.dart';
import '../model/avatar_purchase.dart';
import '../model/member_avatar_record.dart';
import 'avatar_repository.dart';

final class FirestoreAvatarRepository implements AvatarRepository {
  FirestoreAvatarRepository(this._firestore);

  static const avatarsPath = 'memberAvatars';
  static const purchasesPath = 'avatarPurchases';
  static const shopField = 'avatarShop';
  static const creationsPath = 'avatarCreations';
  static const keepsakesPath = 'avatarKeepsakes';
  static const keepsakeDeletesPath = 'avatarKeepsakeDeletes';
  static const creationsField = 'avatarCreationsOn';
  static const recentCreations = 5;
  static const shelfLimit = 200;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _household(String householdId) =>
      _firestore.collection('households').doc(householdId);

  CollectionReference<Map<String, dynamic>> _avatars(String householdId) =>
      _household(householdId).collection(avatarsPath);

  CollectionReference<AvatarPurchase> _purchases(String householdId) =>
      typedCollection(
        _household(householdId).collection(purchasesPath),
        fromJson: AvatarPurchase.fromJson,
        toJson: (purchase) => purchase.toJson(),
      );

  @override
  Stream<MemberAvatarRecord> watch(String householdId, String memberId) =>
      _avatars(householdId)
          .doc(memberId)
          .snapshots()
          .map(
            (snapshot) => switch (snapshot.data()) {
              final data? => MemberAvatarRecord.fromFirestore(data),
              null => MemberAvatarRecord.none,
            },
          )
          .handleError(_failed);

  @override
  Future<void> choose({
    required String householdId,
    required String memberId,
    required AvatarChoice choice,
    required String byMemberId,
  }) => _guarded(
    () => _avatars(householdId).doc(memberId).set({
      'choice': choice.toFirestore(),
      'updatedBy': byMemberId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(mergeFields: ['choice', 'updatedBy', 'updatedAt'])),
  );

  @override
  Future<void> offerPhoto({
    required String householdId,
    required String memberId,
    required String hash,
    required AvatarChoice choice,
    required String byMemberId,
  }) => _guarded(
    () => _avatars(householdId).doc(memberId).set(
      {
        'choice': choice.toFirestore(),
        'pendingPhoto': hash,
        'updatedBy': byMemberId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(
        mergeFields: ['choice', 'pendingPhoto', 'updatedBy', 'updatedAt'],
      ),
    ),
  );

  @override
  Future<String> buy({
    required String householdId,
    required String memberId,
    required String accessoryId,
    required String byMemberId,
  }) async {
    final document = _household(householdId).collection(purchasesPath).doc();
    await _guarded(
      () => document.set({
        'memberId': memberId,
        'accessoryId': accessoryId,
        'requestedBy': byMemberId,
        'requestedAt': FieldValue.serverTimestamp(),
      }),
    );
    return document.id;
  }

  @override
  Stream<AvatarPurchase?> watchPurchase(
    String householdId,
    String purchaseId,
  ) =>
      _purchases(householdId)
          .doc(purchaseId)
          .snapshots()
          .map((snapshot) => snapshot.data())
          .handleError(_failed);

  @override
  Future<void> setShop({required String householdId, required bool isOpen}) =>
      _guarded(() => _household(householdId).update({shopField: isOpen}));

  @override
  Future<void> setCreations({
    required String householdId,
    required bool isOn,
  }) => _guarded(() => _household(householdId).update({creationsField: isOn}));

  @override
  String newCreationId(String householdId) =>
      _household(householdId).collection(creationsPath).doc().id;

  @override
  Future<void> requestCreation({
    required String householdId,
    required String creationId,
    required String memberId,
    required CreationRecipe recipe,
    required String byMemberId,
    CreationStyle? style,
    AvatarBuddy? buddy,
    String? extra,
    String? inboxId,
  }) => _guarded(
    () =>
        _household(householdId).collection(creationsPath).doc(creationId).set({
          'memberId': memberId,
          'recipe': recipe.name,
          'style': ?style?.name,
          'buddy': ?buddy?.toFirestore(),
          'extra': ?extra,
          'inboxId': ?inboxId,
          'requestedBy': byMemberId,
          'requestedAt': FieldValue.serverTimestamp(),
        }),
  );

  @override
  Stream<AvatarCreation?> watchCreation(
    String householdId,
    String creationId,
  ) =>
      _household(householdId)
          .collection(creationsPath)
          .doc(creationId)
          .snapshots()
          .map(
            (snapshot) => switch (snapshot.data()) {
              final data? => AvatarCreation.fromFirestore(
                snapshot.id,
                _withDates(data, 'requestedAt'),
              ),
              null => null,
            },
          )
          .handleError(_failed);

  @override
  Stream<List<AvatarCreation>> watchRecentCreations(String householdId) =>
      _household(householdId)
          .collection(creationsPath)
          .orderBy('requestedAt', descending: true)
          .limit(recentCreations)
          .snapshots()
          .map(
            (snapshot) => [
              for (final document in snapshot.docs)
                ?AvatarCreation.fromFirestore(
                  document.id,
                  _withDates(document.data(), 'requestedAt'),
                ),
            ],
          )
          .handleError(_failed);

  @override
  Stream<List<AvatarKeepsake>> watchKeepsakes(
    String householdId,
    String memberId,
  ) =>
      _household(householdId)
          .collection(keepsakesPath)
          .where('memberId', isEqualTo: memberId)
          .limit(shelfLimit)
          .snapshots()
          .map(
            (snapshot) => [
              for (final document in snapshot.docs)
                ?AvatarKeepsake.fromFirestore(
                  document.id,
                  _withDates(document.data(), 'createdAt'),
                ),
            ]..sort(AvatarKeepsake.newestFirst),
          )
          .handleError(_failed);

  @override
  Future<void> deleteKeepsake({
    required String householdId,
    required String keepsakeId,
    required String byMemberId,
  }) => _guarded(
    () => _household(householdId)
        .collection(keepsakeDeletesPath)
        .doc(keepsakeId)
        .set({
          'requestedBy': byMemberId,
          'requestedAt': FieldValue.serverTimestamp(),
        }),
  );

  static Map<String, Object?> _withDates(
    Map<String, Object?> data,
    String field,
  ) => {
    ...data,
    field: switch (data[field]) {
      final Timestamp at => at.toDate(),
      _ => null,
    },
  };

  static Never _failed(Object error) => throw failureFromFirebase(error);

  Future<void> _guarded(Future<void> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
