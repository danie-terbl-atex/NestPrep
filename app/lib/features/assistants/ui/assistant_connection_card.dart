import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../household/model/member.dart';
import '../model/assistant_activity.dart';
import '../model/assistant_connection.dart';
import '../state/connected_assistants_controller.dart';

/// One connected assistant (assistants ADR-0003): which one, whose it is and
/// in which household, what it may do in plain words, when it was connected
/// and last used, and what it changed lately. The member who connected it
/// and family get *Disconnect*, which is what the rules allow.
class AssistantConnectionCard extends StatelessWidget {
  const AssistantConnectionCard({
    required this.connection,
    required this.owner,
    required this.householdName,
    required this.onDisconnect,
    super.key,
  });

  final AssistantConnection connection;

  /// Null when the profile has since been removed from the household.
  final Member? owner;
  final String householdName;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<ConnectedAssistantsController>();
    final isBusy = controller.isBusy(connection);
    final recent = controller.recentActivityOf(connection);
    final caption = nest.text.caption.copyWith(color: nest.colors.inkSecondary);
    final created = connection.createdAt;
    final usage = [
      if (created != null)
        AssistantsCopy.connectedOn(
          NestDates.full(controller.dayOf(created), controller.today),
        ),
      _lastUsed(controller),
    ].join(' · ');

    return NestCard(
      variant: NestCardVariant.flat,
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    Text(
                      nameOf(connection),
                      style: nest.text.bodyStrong.copyWith(
                        color: nest.colors.ink,
                      ),
                    ),
                    Text(
                      controller.isOwn(connection)
                          ? AssistantsCopy.connectedByYou
                          : AssistantsCopy.connectedBy(
                              owner?.displayName ?? AssistantsCopy.formerMember,
                            ),
                      style: caption,
                    ),
                    Text(
                      AssistantsCopy.inHousehold(householdName),
                      style: nest.text.caption.copyWith(
                        color: nest.colors.inkTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: NestSpace.md),
          Text(
            AssistantsCopy.mayDo,
            style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.xs),
          Wrap(
            spacing: NestSpace.xs,
            runSpacing: NestSpace.xs,
            children: [
              for (final scope in connection.grantedScopes)
                NestTag(label: AssistantsCopy.scope(scope)),
            ],
          ),
          const SizedBox(height: NestSpace.md),
          Text(usage, style: caption),
          const SizedBox(height: NestSpace.md),
          Text(
            AssistantsCopy.recently,
            style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.xs),
          if (recent.isEmpty)
            Text(AssistantsCopy.nothingYet, style: caption)
          else
            for (final activity in recent)
              Text(
                '${AssistantsCopy.activity(activity.tool)} · '
                '${_when(controller, activity)}',
                style: caption,
              ),
          if (controller.canDisconnect(connection)) ...[
            const SizedBox(height: NestSpace.md),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: NestButton(
                label: AssistantsCopy.disconnect,
                icon: LucideIcons.unlink,
                variant: NestButtonVariant.ghost,
                size: NestButtonSize.small,
                isExpanded: false,
                isLoading: isBusy,
                onPressed: isBusy ? null : onDisconnect,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// What the assistant calls itself, or which one it is.
  static String nameOf(AssistantConnection connection) =>
      connection.clientName.isEmpty
      ? AssistantsCopy.assistantName(connection.via)
      : connection.clientName;

  String _lastUsed(ConnectedAssistantsController controller) {
    final used = connection.lastUsedAt;
    if (used == null) return AssistantsCopy.notUsedYet;
    final age = controller.since(used);
    if (age < const Duration(minutes: 1)) return AssistantsCopy.usedJustNow;
    if (age < const Duration(days: 1)) {
      return AssistantsCopy.lastUsed(NestDates.ago(age));
    }
    return AssistantsCopy.lastUsed(
      NestDates.full(controller.dayOf(used), controller.today),
    );
  }

  static String _when(
    ConnectedAssistantsController controller,
    AssistantActivity activity,
  ) {
    final at = activity.at;
    if (at == null) return AppCopy.timeJustNow;
    final age = controller.since(at);
    return age < const Duration(days: 1)
        ? NestDates.ago(age)
        : NestDates.full(controller.dayOf(at), controller.today);
  }
}
