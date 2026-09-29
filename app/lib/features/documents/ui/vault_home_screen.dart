import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/documents_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/vault_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../model/document_entry.dart';
import '../model/document_search.dart';
import '../model/expiry_schedule.dart';
import '../model/vault_shelf.dart';
import '../state/vault_controller.dart';
import 'expiring_soon_card.dart';
import 'vault_document_sheet.dart';
import 'vault_person_tile.dart';

/// The personal vaults, one folder per person this viewer may open, with what
/// needs renewing across all of them at the top (documents ADR-0002).
class VaultHomeScreen extends StatelessWidget {
  const VaultHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VaultController>();
    final householdId = controller.householdId;
    return NestScaffold(
      title: VaultCopy.homeTitle,
      leading: context.canPop()
          ? NestIconButton(
              icon: Icons.arrow_back,
              label: AppCopy.back,
              variant: NestIconButtonVariant.plain,
              onPressed: context.pop,
            )
          : null,
      trailing: [
        NestIconButton(
          icon: Icons.search,
          label: VaultCopy.searchTitle,
          onPressed: () =>
              context.push(DocumentsRoute.searchPathFor(householdId)),
        ),
        NestIconButton(
          icon: Icons.history,
          label: VaultCopy.viewLog,
          onPressed: () =>
              context.push(DocumentsRoute.vaultLogPathFor(householdId)),
        ),
        NestIconButton(
          icon: Icons.lock_outline,
          label: VaultCopy.lockNow,
          onPressed: controller.lock.lock,
        ),
      ],
      body: NestAsyncView<VaultShelf>(
        state: controller.shelf,
        isEmpty: (shelf) => shelf.isEmpty,
        onRetry: controller.retry,
        emptyBuilder: (_) => const NestEmptyView(
          title: VaultCopy.homeEmptyTitle,
          message: VaultCopy.homeEmptyBody,
          icon: Icons.lock_person_outlined,
        ),
        dataBuilder: (context, shelf) => _VaultList(shelf: shelf),
      ),
    );
  }
}

class _VaultList extends StatelessWidget {
  const _VaultList({required this.shelf});

  final VaultShelf shelf;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<VaultController>();
    final today = context.read<HouseholdClock>().today;
    final householdId = controller.householdId;
    final names = {
      for (final owner in shelf.owners) owner.id: owner.displayName,
    };
    final soon = expiringSoon(
      shelf.everyDocument.map(VaultEntry.new),
      today: today,
    );
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        if (soon.isNotEmpty) ...[
          NestRiseIn(
            child: ExpiringSoonCard(
              entries: soon,
              today: today,
              ownerNames: names,
              onOpen: (entry) {
                if (entry is VaultEntry) {
                  showVaultDocumentSheet(
                    context: context,
                    document: entry.document,
                  );
                }
              },
              onSeeAll: () => context.push(
                DocumentsRoute.searchPathFor(householdId, expiringSoon: true),
              ),
            ),
          ),
          const SizedBox(height: NestSpace.xl),
        ],
        const NestSectionHeader(title: VaultCopy.peopleSection),
        const SizedBox(height: NestSpace.sm),
        for (final (index, owner) in shelf.owners.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: NestRiseIn(
              index: index + 1,
              child: VaultPersonTile(
                key: ValueKey(owner.id),
                member: owner,
                count: shelf.documentsOf(owner.id).length,
                needsAttention: shelf
                    .documentsOf(owner.id)
                    .where(
                      (document) => ExpirySchedule.statusOf(
                        document.expiresOn,
                        today,
                      ).needsAttention,
                    )
                    .length,
                sharedWith: shelf.canManage(owner.id)
                    ? shelf.grantsOf(owner.id).length
                    : null,
                onOpen: () => context.push(
                  DocumentsRoute.vaultPersonPathFor(householdId, owner.id),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
