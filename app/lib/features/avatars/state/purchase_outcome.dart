import 'package:flutter/foundation.dart';

import '../model/avatar_catalogue.g.dart';
import '../model/avatar_purchase.dart';

@immutable
final class PurchaseOutcome {
  const PurchaseOutcome({
    required this.accessory,
    required this.isOwned,
    this.reason,
    this.isTooSlow = false,
  });

  final AvatarAccessory accessory;
  final bool isOwned;
  final PurchaseRefusal? reason;
  final bool isTooSlow;
}
