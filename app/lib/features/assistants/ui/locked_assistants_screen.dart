import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/state/household_entitlement.dart';
import '../../subscriptions/ui/premium_area.dart';
import '../state/connected_assistants_controller.dart';
import 'assistant_connections_section.dart';

/// *Connected assistants* is Premium (subscriptions ADR-0008): [child] for a
/// household that has it, [LockedAssistantsScreen] for one that does not.
class AssistantsPremiumArea extends StatelessWidget {
  const AssistantsPremiumArea({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final entitlement = context.watch<HouseholdEntitlement>();
    if (entitlement.isPremium) return child;
    return LockedAssistantsScreen(
      isLoading: entitlement.entitlement is AsyncLoading,
    );
  }
}

/// The locked place, which still lists what is connected: every assistant is
/// refused on the server without Premium, and disconnecting one stays the
/// member's to do.
class LockedAssistantsScreen extends StatelessWidget {
  const LockedAssistantsScreen({required this.isLoading, super.key});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<ConnectedAssistantsController>();
    final failure = controller.actionFailure;
    final hasConnections = switch (controller.connections) {
      AsyncData(:final value) => value.isNotEmpty,
      _ => false,
    };
    return NestScaffold(
      title: AssistantsCopy.title,
      leading: backLeading(context),
      body: isLoading
          ? const NestLoadingView()
          : ListView(
              padding: const EdgeInsets.only(bottom: NestSpace.huge),
              children: [
                if (failure != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: NestSpace.md),
                    child: NestBanner(
                      message: AppCopy.failure(failure),
                      tone: NestBannerTone.danger,
                      actionLabel: AppCopy.back,
                      onAction: controller.dismissActionFailure,
                    ),
                  ),
                const PremiumLockedView(feature: PremiumFeature.assistants),
                if (hasConnections) ...[
                  const NestSectionHeader(
                    title: AssistantsCopy.sectionConnected,
                  ),
                  const SizedBox(height: NestSpace.xs),
                  Text(
                    AssistantsCopy.lockedConnectionsBody,
                    style: nest.text.caption.copyWith(
                      color: nest.colors.inkSecondary,
                    ),
                  ),
                  const SizedBox(height: NestSpace.sm),
                  AssistantConnectionsSection(
                    onDisconnect: (connection) =>
                        confirmDisconnect(context, controller, connection),
                  ),
                ],
              ],
            ),
    );
  }
}
