import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../state/account_export_controller.dart';
import 'export_ready_card.dart';
import 'fact_list.dart';

/// Download my data (accounts ADR-0006 — POPIA's right of access): what the
/// file holds, then one button that gathers it, and once it is on the phone,
/// the share sheet to save or send it.
///
/// The four states are the controller's: nothing asked yet, gathering, a
/// failure with its retry, and the file ready (`FE-08`). What the file holds
/// stays on screen through all of them, so nobody presses a button without
/// knowing what it makes.
class AccountExportScreen extends StatelessWidget {
  const AccountExportScreen({super.key});

  static const path = '/account/data';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AccountExportController>();
    final nest = NestTheme.of(context);
    return NestScaffold(
      title: AccountDataCopy.exportTitle,
      leading: backLeading(context),
      body: ListView(
        padding: const EdgeInsets.only(bottom: NestSpace.huge),
        children: [
          Text(AccountDataCopy.exportLead, style: nest.text.body),
          const SizedBox(height: NestSpace.xl),
          NestRiseIn(
            child: NestCard(
              variant: NestCardVariant.tinted,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FactList(
                    title: AccountDataCopy.exportIncludesTitle,
                    facts: AccountDataCopy.exportIncludes,
                  ),
                  Text(
                    AccountDataCopy.exportFilesNote,
                    style: nest.text.bodySecondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: NestSpace.xl),
          _ExportAction(controller: controller),
          const SizedBox(height: NestSpace.lg),
          Text(
            AccountDataCopy.exportPrivacyNote,
            style: nest.text.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ExportAction extends StatelessWidget {
  const _ExportAction({required this.controller});

  final AccountExportController controller;

  @override
  Widget build(BuildContext context) {
    final action = switch (controller.export) {
      AsyncData(:final value?) => ExportReadyCard(
        key: const ValueKey('ready'),
        fileCount: value.export.fileCount,
        isSharing: controller.isSharing,
        shareFailure: controller.shareFailure,
        onShare: controller.share,
        onPrepareAgain: controller.prepare,
      ),
      AsyncFailure(:final failure) => Column(
        key: const ValueKey('failure'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NestBanner(
            message: AppCopy.failure(failure),
            tone: NestBannerTone.danger,
          ),
          const SizedBox(height: NestSpace.lg),
          NestButton(
            label: AppCopy.retry,
            icon: Icons.refresh,
            onPressed: controller.prepare,
          ),
        ],
      ),
      _ => NestButton(
        key: const ValueKey('prepare'),
        label: controller.isPreparing
            ? AccountDataCopy.exportPreparing
            : AccountDataCopy.exportPrepare,
        icon: Icons.download_outlined,
        isLoading: controller.isPreparing,
        onPressed: controller.isPreparing ? null : controller.prepare,
      ),
    };
    return AnimatedSwitcher(
      duration: NestMotion.of(context).standard,
      child: action,
    );
  }
}
