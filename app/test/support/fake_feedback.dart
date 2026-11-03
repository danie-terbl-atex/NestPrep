import 'dart:async';

import 'package:nestprep/features/feedback/data/feedback_repository.dart';
import 'package:nestprep/features/feedback/model/feedback_draft.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

final class FakeFeedbackRepository implements FeedbackRepository {
  final sent = <({String uid, FeedbackDraft draft})>[];
  FeedbackDelivery delivery = FeedbackDelivery.delivered;
  AppFailure? refuseWith;
  Completer<void>? gate;

  @override
  Future<FeedbackDelivery> send({
    required String uid,
    required FeedbackDraft draft,
  }) async {
    await gate?.future;
    final refusal = refuseWith;
    if (refusal != null) throw refusal;
    sent.add((uid: uid, draft: draft));
    return delivery;
  }
}
