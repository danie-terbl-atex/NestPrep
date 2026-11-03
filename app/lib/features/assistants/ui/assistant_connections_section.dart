import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../household/model/household_view.dart';
import '../model/assistant_connection.dart';
import '../state/connected_assistants_controller.dart';
import 'assistant_connection_card.dart';

/// The connections this member may see, in all four of their states
/// (`FE-08`). Only this part swaps: the switch and the way to connect sit
/// outside it, so a household with nothing connected still has both.
class AssistantConnectionsSection extends StatelessWidget {
  const AssistantConnectionsSection({required this.onDisconnect, super.key});

  /// Asks before disconnecting; the screen owns the confirmation.
  final ValueChanged<AssistantConnection> onDisconnect;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ConnectedAssistantsController>();
    final view = context.read<HouseholdView>();
    final nest = NestTheme.of(context);
    return switch (controller.connections) {
      AsyncLoading() => const Column(
        children: [
          NestSkeleton(height: NestSize.controlLarge * 2),
          SizedBox(height: NestSpace.sm),
          NestSkeleton(height: NestSize.controlLarge * 2),
        ],
      ),
      AsyncFailure(:final failure) => NestErrorView(
        message: AppCopy.failure(failure),
        retryLabel: AppCopy.retry,
        onRetry: controller.retry,
      ),
      AsyncData(value: final connections) when connections.isEmpty => NestCard(
        variant: NestCardVariant.flat,
        padding: const EdgeInsets.all(NestSpace.lg),
        child: Row(
          children: [
            const NestIconTile(
              icon: LucideIcons.bot,
              tint: NestTileTint.lilac,
              size: NestSize.avatarMedium,
              iconSize: NestSize.iconMedium,
            ),
            const SizedBox(width: NestSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AssistantsCopy.emptyTitle, style: nest.text.bodyStrong),
                  const SizedBox(height: NestSpace.xxs),
                  Text(
                    controller.isFamily
                        ? AssistantsCopy.emptyBody
                        : AssistantsCopy.emptyBodyForOthers,
                    style: nest.text.caption.copyWith(
                      color: nest.colors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      AsyncData(value: final connections) => Column(
        children: [
          for (final connection in connections)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.sm),
              child: AssistantConnectionCard(
                key: ValueKey(connection.id),
                connection: connection,
                owner: view.memberById(connection.memberId),
                householdName: view.household.name,
                onDisconnect: () => onDisconnect(connection),
              ),
            ),
        ],
      ),
    };
  }
}
