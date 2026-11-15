import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/assistants_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/assistants_copy.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../../subscriptions/state/household_entitlement.dart';

/// The way to *Connected assistants* from More (assistants ADR-0001), while
/// the `assistants` switch is on.
class AssistantsLink extends StatelessWidget {
  const AssistantsLink({required this.householdId, super.key});

  final String householdId;

  @override
  Widget build(BuildContext context) {
    final isLocked =
        !(context.watch<HouseholdEntitlement?>()?.isPremium ?? true);
    return NestCard(
      variant: NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: NestListRow(
        title: AssistantsCopy.title,
        subtitle: AssistantsCopy.openFromMoreBody,
        leading: const NestIconTile(
          icon: LucideIcons.bot,
          tint: NestTileTint.lilac,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLocked) ...[
              Icon(
                LucideIcons.lock,
                size: NestSize.iconSmall,
                color: NestTheme.of(context).colors.inkSecondary,
                semanticLabel: SubscriptionCopy.lockedHint,
              ),
              const SizedBox(width: NestSpace.sm),
            ],
            const Icon(LucideIcons.chevronRight),
          ],
        ),
        // Pushed, so back lands on More (`FE-17`).
        onTap: () => context.push(AssistantsRoute.pathFor(householdId)),
      ),
    );
  }
}
