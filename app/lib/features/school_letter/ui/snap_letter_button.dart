import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/calendar_v2_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/state/household_entitlement.dart';
import '../../subscriptions/ui/premium_gate.dart';

/// The way into snapping a school letter, beside the calendar's quick add
/// (calendar ADR-0005). A free household sees it with a lock and meets the
/// paywall on this feature; the route and the server check Premium again
/// (subscriptions ADR-0009).
class SnapLetterButton extends StatelessWidget {
  const SnapLetterButton({required this.householdId, super.key});

  final String householdId;

  @override
  Widget build(BuildContext context) {
    final button = NestIconButton(
      key: const ValueKey('snap-letter-open'),
      icon: LucideIcons.scanText,
      label: SchoolLetterCopy.openFromWeek,
      onPressed: () => _open(context),
    );
    if (context.watch<HouseholdEntitlement>().isPremium) return button;
    final colors = NestTheme.of(context).colors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
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
                  key: const ValueKey('snap-letter-lock'),
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

  Future<void> _open(BuildContext context) async {
    if (!await ensurePremium(context, feature: PremiumFeature.schoolLetter)) {
      return;
    }
    if (!context.mounted) return;
    await context.push(CalendarV2Route.letterPathFor(householdId));
  }
}
