import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../model/deletion_preview.dart';
import '../state/account_deletion_controller.dart';
import 'account_export_screen.dart';
import 'deletion_confirm.dart';
import 'fact_list.dart';
import 'household_outcome_card.dart';

/// Delete my account (accounts ADR-0006; both stores require it in the app).
///
/// Read first, then confirm: what happens to each household the person is in
/// — leave, hand over, or end — what is deleted and what stays, a warning when
/// a store subscription would keep billing, a way to download a copy first,
/// and only then the typed confirmation and the one button. Loading, a failed
/// read with its retry, and the preview itself are the async surface
/// (`FE-08`); the preview is never "empty" — no households is a sentence.
class DeleteAccountScreen extends StatelessWidget {
  const DeleteAccountScreen({super.key});

  static const path = '/account/delete';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AccountDeletionController>();
    return NestScaffold(
      title: AccountDataCopy.deleteTitle,
      leading: backLeading(context),
      body: NestAsyncView<DeletionPreview>(
        state: controller.preview,
        isEmpty: (_) => false,
        emptyBuilder: (_) => const SizedBox.shrink(),
        onRetry: controller.load,
        dataBuilder: (context, preview) =>
            _ThePlan(preview: preview, controller: controller),
      ),
    );
  }
}

class _ThePlan extends StatelessWidget {
  const _ThePlan({required this.preview, required this.controller});

  final DeletionPreview preview;
  final AccountDeletionController controller;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final renewing = preview.renewingSubscriptions;
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        Text(AccountDataCopy.deleteLead, style: nest.text.body),
        const SizedBox(height: NestSpace.xl),
        const NestSectionHeader(title: AccountDataCopy.deleteHouseholdsTitle),
        const SizedBox(height: NestSpace.sm),
        if (preview.households.isEmpty)
          Text(AccountDataCopy.deleteNoHouseholds, style: nest.text.body),
        for (final (index, household) in preview.households.indexed) ...[
          NestRiseIn(
            index: index.clamp(0, 3),
            child: HouseholdOutcomeCard(
              key: ValueKey(household.householdId),
              household: household,
            ),
          ),
          const SizedBox(height: NestSpace.md),
        ],
        if (renewing > 0) ...[
          NestBanner(
            message: AccountDataCopy.renewingSubscriptions(renewing),
            tone: NestBannerTone.warning,
          ),
          const SizedBox(height: NestSpace.md),
        ],
        const SizedBox(height: NestSpace.md),
        const NestCard(
          variant: NestCardVariant.tinted,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FactList(
                title: AccountDataCopy.deleteGoesTitle,
                facts: AccountDataCopy.deleteGoes,
                icon: LucideIcons.circleMinus,
              ),
              SizedBox(height: NestSpace.md),
              FactList(
                title: AccountDataCopy.deleteStaysTitle,
                facts: AccountDataCopy.deleteStays,
              ),
            ],
          ),
        ),
        const SizedBox(height: NestSpace.lg),
        NestButton(
          label: AccountDataCopy.deleteKeepInstead,
          variant: NestButtonVariant.outline,
          icon: LucideIcons.download,
          onPressed: () => context.push(AccountExportScreen.path),
        ),
        const SizedBox(height: NestSpace.xxl),
        DeletionConfirm(
          canDelete: controller.canDelete,
          isDeleting: controller.isDeleting,
          failure: controller.deleteFailure,
          onTyped: controller.typeConfirmation,
          onDelete: controller.delete,
        ),
      ],
    );
  }
}
