import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/avatar_copy.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/ui/premium_area.dart';

class StudioLockedTab extends StatelessWidget {
  const StudioLockedTab({
    required this.feature,
    required this.canBuy,
    super.key,
  });

  final PremiumFeature feature;
  final bool canBuy;

  @override
  Widget build(BuildContext context) => canBuy
      ? PremiumLockedView(feature: feature)
      : NestEmptyView(
          icon: LucideIcons.lock,
          title: SubscriptionCopy.headline(feature),
          message: AvatarCopy.premiumAskParent,
        );
}
