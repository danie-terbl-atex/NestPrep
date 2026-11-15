import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/state/household_entitlement.dart';
import '../../subscriptions/ui/premium_gate.dart';

/// Whether the shops are open to this household (subscriptions ADR-0008):
/// they are Premium, and the plain grocery list is not. A place with no
/// entitlement above it is locked.
///
/// [listen] false for an event handler, which must not subscribe.
bool shopsUnlocked(BuildContext context, {bool listen = true}) =>
    Provider.of<HouseholdEntitlement?>(context, listen: listen)?.isPremium ??
    false;

/// The one call a shop control makes before it does anything: true for a
/// Premium household, or once the paywall this opens on the shops was bought
/// from.
Future<bool> ensureShops(BuildContext context) =>
    ensurePremium(context, feature: PremiumFeature.shops);

/// [child] with a small lock on its corner while [isLocked], so a shop
/// control a free household sees says it is Premium before the tap. The lock
/// takes no taps of its own.
class ShopLockBadge extends StatelessWidget {
  const ShopLockBadge({required this.isLocked, required this.child, super.key});

  final bool isLocked;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isLocked) return child;
    final colors = NestTheme.of(context).colors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        PositionedDirectional(
          top: 0,
          end: 0,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(NestSpace.xxs),
                child: Icon(
                  LucideIcons.lock,
                  size: NestSize.iconBadge,
                  color: colors.inkSecondary,
                  semanticLabel: SubscriptionCopy.lockedHint,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
