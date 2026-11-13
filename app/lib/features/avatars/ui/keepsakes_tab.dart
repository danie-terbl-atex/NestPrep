import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/avatar_keepsake.dart';
import '../model/avatar_studio.dart';
import '../state/avatar_keepsakes_controller.dart';
import 'keepsake_card.dart';

class KeepsakesTab extends StatelessWidget {
  const KeepsakesTab({
    required this.studio,
    required this.isSelf,
    required this.onUse,
    this.onMake,
    super.key,
  });

  final AvatarStudio studio;
  final bool isSelf;
  final ValueChanged<String> onUse;
  final VoidCallback? onMake;

  Future<void> _confirmDelete(
    BuildContext context,
    AvatarKeepsakesController controller,
    AvatarKeepsake keepsake,
  ) async {
    final confirmed = await showNestConfirm(
      context: context,
      title: AvatarCreationCopy.deleteConfirm,
      message: AvatarCreationCopy.deleteBody,
      confirmLabel: AvatarCreationCopy.delete,
      cancelLabel: AvatarCreationCopy.keepIt,
      isDangerous: true,
    );
    if (confirmed == true) await controller.delete(keepsake);
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<AvatarKeepsakesController>();
    final failure = controller.actionFailure;
    final onMake = this.onMake;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isSelf
              ? AvatarCreationCopy.yourShelf
              : AvatarCreationCopy.shelfOf(studio.member.displayName),
          style: nest.text.title,
        ),
        const SizedBox(height: NestSpace.xs),
        Text(AvatarCreationCopy.shelfBody, style: nest.text.bodySecondary),
        const SizedBox(height: NestSpace.lg),
        if (failure != null) ...[
          NestBanner(
            message: AppCopy.failure(failure),
            tone: NestBannerTone.danger,
            actionLabel: AppCopy.back,
            onAction: controller.dismissActionFailure,
          ),
          const SizedBox(height: NestSpace.lg),
        ],
        switch (controller.keepsakes) {
          AsyncLoading() => const NestLoadingView(rows: 2),
          AsyncFailure(:final failure) => NestErrorView(
            message: AppCopy.failure(failure),
            retryLabel: AppCopy.retry,
            onRetry: controller.retry,
          ),
          AsyncData(value: final shelf) when shelf.isEmpty => NestCard(
            variant: NestCardVariant.flat,
            child: Column(
              children: [
                const NestIconTile(
                  icon: LucideIcons.images,
                  tint: NestTileTint.lilac,
                  size: NestSize.avatarLarge,
                ),
                const SizedBox(height: NestSpace.md),
                Text(
                  AvatarCreationCopy.emptyTitle,
                  style: nest.text.title,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: NestSpace.xs),
                Text(
                  AvatarCreationCopy.emptyBody,
                  style: nest.text.bodySecondary,
                  textAlign: TextAlign.center,
                ),
                if (onMake != null) ...[
                  const SizedBox(height: NestSpace.lg),
                  NestButton(
                    label: AvatarCreationCopy.emptyAction,
                    icon: LucideIcons.sparkles,
                    isExpanded: false,
                    onPressed: onMake,
                  ),
                ],
              ],
            ),
          ),
          AsyncData(value: final shelf) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final keepsake in shelf)
                Padding(
                  padding: const EdgeInsets.only(bottom: NestSpace.md),
                  child: KeepsakeCard(
                    key: ValueKey('keepsake-${keepsake.id}'),
                    keepsake: keepsake,
                    householdId: controller.householdId,
                    isWorn: studio.wears(keepsake.imageHash),
                    isDeleting: controller.isDeleting(keepsake.id),
                    onUse: keepsake.isPortrait
                        ? null
                        : () => onUse(keepsake.imageHash),
                    onDelete: () =>
                        _confirmDelete(context, controller, keepsake),
                  ),
                ),
            ],
          ),
        },
      ],
    );
  }
}
