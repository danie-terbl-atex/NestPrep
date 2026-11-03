import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../model/assistant_connection.dart';
import '../state/connected_assistants_controller.dart';
import 'assistant_connection_card.dart';
import 'assistant_connections_section.dart';
import 'assistants_how_to_connect.dart';
import 'assistants_switch_card.dart';

/// *Connected assistants* (assistants ADR-0001, ADR-0003): the assistants
/// working in this household as its members, what each may do and has done,
/// a way to disconnect each, the household's own switch for family, and how
/// to connect one. Reached from More; it pushes, so back returns there
/// (`FE-17`).
class ConnectedAssistantsScreen extends StatelessWidget {
  const ConnectedAssistantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ConnectedAssistantsController>();
    final failure = controller.actionFailure;
    return NestScaffold(
      title: AssistantsCopy.title,
      subtitle: AssistantsCopy.subtitle,
      leading: context.canPop()
          ? NestIconButton(
              icon: LucideIcons.arrowLeft,
              label: AppCopy.back,
              variant: NestIconButtonVariant.plain,
              onPressed: context.pop,
            )
          : null,
      trailing: const [AccountMenuButton()],
      body: ListView(
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
          if (controller.isFamily) ...[
            const NestSectionHeader(title: AssistantsCopy.sectionHousehold),
            const SizedBox(height: NestSpace.sm),
            NestRiseIn(
              child: AssistantsSwitchCard(
                allowed: controller.allowed,
                isBusy: controller.isSwitching,
                onChanged: controller.setAllowed,
              ),
            ),
            const SizedBox(height: NestSpace.xxl),
          ],
          const NestSectionHeader(title: AssistantsCopy.sectionConnected),
          const SizedBox(height: NestSpace.sm),
          NestRiseIn(
            index: 1,
            child: AssistantConnectionsSection(
              onDisconnect: (connection) =>
                  _disconnect(context, controller, connection),
            ),
          ),
          // Connecting is for family in v1 (assistants ADR-0003); the
          // consent page refuses anybody else.
          if (controller.isFamily) ...[
            const SizedBox(height: NestSpace.xxl),
            const NestSectionHeader(title: AssistantsCopy.sectionConnect),
            const SizedBox(height: NestSpace.sm),
            const NestRiseIn(index: 2, child: AssistantsHowToConnect()),
          ],
        ],
      ),
    );
  }

  Future<void> _disconnect(
    BuildContext context,
    ConnectedAssistantsController controller,
    AssistantConnection connection,
  ) async {
    final confirmed = await showNestConfirm(
      context: context,
      title: AssistantsCopy.disconnectConfirm,
      message: AssistantsCopy.disconnectBody(
        AssistantConnectionCard.nameOf(connection),
      ),
      confirmLabel: AssistantsCopy.disconnect,
      cancelLabel: AppCopy.householdCancel,
      isDangerous: true,
    );
    if (confirmed != true) return;
    await controller.disconnect(connection);
  }
}
