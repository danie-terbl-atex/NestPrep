import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/vault_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/household_clock.dart';
import '../../household/model/household_view.dart';
import '../model/vault_view.dart';
import '../state/vault_view_log_controller.dart';
import 'vault_view_row.dart';

/// Who opened what in the vaults, newest first (documents ADR-0003). Every
/// line was written by the server in the same step that let the bytes be read,
/// so this is a record rather than a courtesy — and nothing here can edit it.
/// An admin sees every vault's; anybody else sees who opened their own.
class VaultViewLogScreen extends StatelessWidget {
  const VaultViewLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VaultViewLogController>();
    return NestScaffold(
      title: VaultCopy.logTitle,
      leading: context.canPop()
          ? NestIconButton(
              icon: LucideIcons.arrowLeft,
              label: AppCopy.back,
              variant: NestIconButtonVariant.plain,
              onPressed: context.pop,
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            VaultCopy.logBody,
            style: NestTheme.of(context).text.bodySecondary,
          ),
          const SizedBox(height: NestSpace.lg),
          Expanded(
            child: NestAsyncView<List<VaultView>>(
              state: controller.log,
              isEmpty: (views) => views.isEmpty,
              onRetry: controller.retry,
              emptyBuilder: (_) => const NestEmptyView(
                title: VaultCopy.logEmptyTitle,
                message: VaultCopy.logEmptyBody,
                icon: LucideIcons.history,
              ),
              dataBuilder: (context, views) => _ViewList(views: views),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewList extends StatelessWidget {
  const _ViewList({required this.views});

  final List<VaultView> views;

  @override
  Widget build(BuildContext context) {
    final view = context.read<HouseholdView>();
    final clock = context.read<HouseholdClock>();
    final today = clock.today;
    // Built lazily: a busy household's log is a hundred lines (`FE-11`).
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      itemCount: views.length,
      itemBuilder: (context, index) {
        final entry = views[index];
        final viewerId = entry.viewerMemberId;
        final at = entry.viewedAt;
        return Padding(
          key: ValueKey(entry.id),
          padding: const EdgeInsets.only(bottom: NestSpace.xs),
          child: VaultViewRow(
            documentName: entry.documentName,
            viewer: viewerId == null ? null : view.memberById(viewerId),
            vaultOwner: view.memberById(entry.ownerMemberId),
            isThroughSharedLink: entry.isThroughSharedLink,
            when: at == null
                ? AppCopy.timeJustNow
                : NestDates.moment(
                    clock.dateOf(at),
                    today,
                    clock.minutesOfDay(at),
                  ),
          ),
        );
      },
    );
  }
}
