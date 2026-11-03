import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../app/app_version.dart';
import '../../../shared/failure/firebase_failure_mapper.dart';
import '../model/feedback_draft.dart';
import 'feedback_repository.dart';

final class FirestoreFeedbackRepository implements FeedbackRepository {
  FirestoreFeedbackRepository(
    this._firestore, {
    this.acknowledgement = const Duration(seconds: 8),
  });

  static const feedbackPath = 'feedback';

  final FirebaseFirestore _firestore;
  final Duration acknowledgement;

  @override
  Future<FeedbackDelivery> send({
    required String uid,
    required FeedbackDraft draft,
  }) async {
    final write = _firestore.collection(feedbackPath).doc().set({
      'uid': uid,
      'kind': draft.kind.name,
      'message': draft.message.trim(),
      'area': draft.area?.name,
      'screen': draft.screen,
      'householdId': draft.householdId,
      'mayContact': draft.mayContact,
      'appVersion': AppVersion.name,
      'appBuild': AppVersion.build,
      'platform': _platform,
      'createdAt': FieldValue.serverTimestamp(),
    });
    try {
      await write.timeout(acknowledgement);
      return FeedbackDelivery.delivered;
    } on TimeoutException {
      return FeedbackDelivery.queued;
    } catch (error) {
      throw failureFromFirebase(error);
    }
  }

  static String get _platform => switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    _ => 'other',
  };
}
