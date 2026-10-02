import 'package:flutter/foundation.dart';

/// A Sixty60 store that serves a place, as `store-contexts` answered it. A
/// search sends these back as its `userContext`, so a price and a stock level
/// are the ones that store would deliver.
@immutable
final class CheckersStore {
  const CheckersStore({
    required this.storeId,
    required this.serviceOptionIds,
    this.hasCapacity = const [],
    this.brandPriority,
  });

  final String storeId;
  final List<String> serviceOptionIds;
  final List<String> hasCapacity;
  final int? brandPriority;

  /// The one-hour delivery the matches are for.
  static const sixtyMinuteDelivery = 'sixty-min-delivery';

  bool get deliversInSixtyMinutes =>
      serviceOptionIds.contains(sixtyMinuteDelivery);
}
