import 'package:nestprep/features/product_analytics/data/paywall_open_recorder.dart';
import 'package:nestprep/features/subscriptions/model/premium_feature.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// Records every paywall opening the app would send (product-analytics
/// ADR-0002), or fails the way an offline phone does.
final class FakePaywallOpenRecorder implements PaywallOpenRecorder {
  final opened = <({String householdId, PremiumFeature trigger})>[];

  /// Thrown by every call while set.
  AppFailure? failWith;

  @override
  Future<void> recordPaywallOpened({
    required String householdId,
    required PremiumFeature trigger,
  }) async {
    final failure = failWith;
    if (failure != null) throw failure;
    opened.add((householdId: householdId, trigger: trigger));
  }
}
