import '../../subscriptions/model/premium_feature.dart';

/// One trigger's week: how many families met the paywall on it, and how many
/// bought after it (product-analytics ADR-0002).
final class TriggerConversion {
  const TriggerConversion({
    required this.feature,
    required this.families,
    required this.conversions,
  });

  final PremiumFeature feature;
  final int families;
  final int conversions;

  /// A whole percentage, or null when nobody met this paywall — a purchase
  /// through it counted anyway, from a phone that could not say it opened.
  int? get ratePercent =>
      families == 0 ? null : (conversions * 100 / families).round();
}
