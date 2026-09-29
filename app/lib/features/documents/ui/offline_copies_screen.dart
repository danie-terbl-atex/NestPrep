import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/vault_copy.dart';
import '../../../shared/format/byte_size.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/household_clock.dart';
import '../../../shared/ui/back_leading.dart';
import '../../household/model/household_view.dart';
import '../model/offline_shelf.dart';
import '../state/offline_copies_controller.dart';
import 'document_row.dart';
import 'offline_copy_sheet.dart';

/// What this phone keeps for when there is no signal (documents ADR-0007):
/// each copy, how much room they take together, and the way to remove them.
/// Behind the vaults' lock, like everything it holds.
class OfflineCopiesScreen extends StatelessWidget {
  const OfflineCopiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OfflineCopiesController>();
    final failure = controller.actionFailure;
    return NestScaffold(
      title: OfflineCopiesCopy.title,
      leading: backLeading(context),
      trailing: [
        NestIconButton(
          icon: Icons.lock_outline,
          label: VaultCopy.lockNow,
          onPressed: controller.lock.lock,
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            OfflineCopiesCopy.body,
            style: NestTheme.of(context).text.bodySecondary,
          ),
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
          Expanded(
            child: NestAsyncView<OfflineShelf>(
              state: controller.shelf,
              isEmpty: (shelf) => shelf.isEmpty,
              onRetry: controller.retry,
              emptyBuilder: (_) => const NestEmptyView(
                title: OfflineCopiesCopy.emptyTitle,
                message: OfflineCopiesCopy.emptyBody,
                icon: Icons.offline_pin_outlined,
              ),
              dataBuilder: (context, shelf) => _CopyList(shelf: shelf),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyList extends StatelessWidget {
  const _CopyList({required this.shelf});

  final OfflineShelf shelf;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<OfflineCopiesController>();
    final clock = context.read<HouseholdClock>();
    final view = context.read<HouseholdView>();
    final today = clock.today;
    final nest = NestTheme.of(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        NestCard(
          variant: NestCardVariant.tinted,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                OfflineCopiesCopy.usage(
                  shelf.copies.length,
                  NestBytes.format(shelf.totalBytes),
                  OfflineShelf.maxCopies,
                ),
                style: nest.text.bodyStrong,
              ),
              if (controller.hasChecked) ...[
                const SizedBox(height: NestSpace.xs),
                Text(OfflineCopiesCopy.checked, style: nest.text.caption),
              ],
            ],
          ),
        ),
        const SizedBox(height: NestSpace.lg),
        for (final (index, copy) in shelf.copies.indexed)
          Padding(
            key: ValueKey(copy.key),
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: NestRiseIn(
              index: index,
              child: DocumentRow(
                name: copy.name,
                sizeBytes: copy.sizeBytes,
                isImage: copy.isImage,
                today: today,
                isKeptOffline: true,
                byline: [
                  switch (copy.ownerMemberId) {
                    null => OfflineCopiesCopy.household,
                    final owner => VaultCopy.vaultOf(
                      view.memberById(owner)?.displayName ?? '',
                    ),
                  },
                  OfflineCopiesCopy.savedOn(
                    NestDates.relative(clock.dateOf(copy.savedAt), today),
                  ),
                ].join(' · '),
                onOpen: () =>
                    showOfflineCopySheet(context: context, copy: copy),
              ),
            ),
          ),
        const SizedBox(height: NestSpace.lg),
        NestButton(
          label: OfflineCopiesCopy.removeAll,
          icon: Icons.delete_sweep_outlined,
          variant: NestButtonVariant.outline,
          onPressed: () => _removeAll(context, controller),
        ),
      ],
    );
  }

  Future<void> _removeAll(
    BuildContext context,
    OfflineCopiesController controller,
  ) async {
    final confirmed = await showNestConfirm(
      context: context,
      title: OfflineCopiesCopy.removeAllTitle,
      message: OfflineCopiesCopy.removeAllBody,
      confirmLabel: OfflineCopiesCopy.removeAll,
      cancelLabel: AppCopy.householdCancel,
      isDangerous: true,
    );
    if (confirmed == true) await controller.removeAll();
  }
}
