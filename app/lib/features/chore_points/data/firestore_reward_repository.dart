import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/failure/firebase_failure_mapper.dart';
import '../../../shared/firestore/typed_collection.dart';
import '../model/reward.dart';
import '../model/reward_request.dart';
import 'reward_repository.dart';

final class FirestoreRewardRepository implements RewardRepository {
  FirestoreRewardRepository(this._firestore);

  static const rewardsPath = 'rewards';
  static const requestsPath = 'rewardRequests';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _raw(
    String householdId,
    String path,
  ) => _firestore.collection('households').doc(householdId).collection(path);

  CollectionReference<Reward> _rewards(String householdId) => typedCollection(
    _raw(householdId, rewardsPath),
    fromJson: Reward.fromJson,
    toJson: (reward) => reward.toJson(),
  );

  CollectionReference<RewardRequest> _requests(String householdId) =>
      typedCollection(
        _raw(householdId, requestsPath),
        fromJson: RewardRequest.fromJson,
        toJson: (request) => request.toJson(),
      );

  @override
  Stream<List<Reward>> watchRewards(String householdId) => _rewards(householdId)
      .orderBy('cost')
      .limit(RewardRepository.shelfLimit)
      .snapshots()
      .map(_docs)
      .handleError(_failed);

  @override
  Stream<List<RewardRequest>> watchWaitingRequests(String householdId) =>
      _requests(householdId)
          .where('status', isEqualTo: RequestStatus.waiting.name)
          .limit(RewardRepository.shelfLimit)
          .snapshots()
          .map(_docs)
          .handleError(_failed);

  @override
  Stream<List<RewardRequest>> watchRequestsFor(
    String householdId,
    String memberId,
  ) => _requests(householdId)
      .where('memberId', isEqualTo: memberId)
      .orderBy('requestedAt', descending: true)
      .limit(RewardRepository.requestLimit)
      .snapshots()
      .map(_docs)
      .handleError(_failed);

  @override
  Future<void> saveReward({
    required String householdId,
    String? rewardId,
    required String title,
    required int cost,
    required RewardIcon icon,
    required String createdBy,
  }) {
    final rewards = _rewards(householdId);
    if (rewardId == null) {
      final document = rewards.doc();
      return _guarded(
        () => document.set(
          Reward(
            id: document.id,
            title: title,
            cost: cost,
            icon: icon,
            createdBy: createdBy,
          ),
        ),
      );
    }
    // An edit never rewrites who made it or when (the rules refuse that too).
    return _guarded(
      () => rewards.doc(rewardId).update({
        'title': title,
        'cost': cost,
        'icon': icon.name,
      }),
    );
  }

  @override
  Future<void> deleteReward({
    required String householdId,
    required String rewardId,
  }) => _guarded(() => _rewards(householdId).doc(rewardId).delete());

  @override
  Future<void> requestReward({
    required String householdId,
    required String rewardId,
    required String memberId,
    required String requestedBy,
  }) {
    final document = _requests(householdId).doc();
    return _guarded(
      () => document.set(
        RewardRequest(
          id: document.id,
          rewardId: rewardId,
          memberId: memberId,
          requestedBy: requestedBy,
        ),
      ),
    );
  }

  static List<T> _docs<T>(QuerySnapshot<T> snapshot) => [
    for (final doc in snapshot.docs) doc.data(),
  ];

  static Never _failed(Object error) => throw failureFromFirebase(error);

  Future<void> _guarded(Future<void> Function() write) async {
    try {
      await write();
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }
}
