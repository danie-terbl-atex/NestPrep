import '../model/feedback_draft.dart';

abstract interface class FeedbackRepository {
  /// [FeedbackDelivery.queued] when the server has not answered in time: the
  /// entry is in the SDK's queue and goes when the phone is back online.
  Future<FeedbackDelivery> send({
    required String uid,
    required FeedbackDraft draft,
  });
}
