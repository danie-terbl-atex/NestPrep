import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/family_roster.dart';
import '../state/family_controller.dart';
import 'family_list.dart';

/// The family: every person in the household with what is known about them,
/// children first, and the household's schools. Pushed from the household
/// screen, so it carries its own way back (`FE-17`). All four async states
/// come from the kit (`FE-08`).
class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FamilyController>();
    final failure = controller.actionFailure;
    return NestScaffold(
      title: FamilyCopy.title,
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
          if (failure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.lg),
              child: NestBanner(
                message: AppCopy.failure(failure),
                tone: NestBannerTone.danger,
                actionLabel: AppCopy.back,
                onAction: controller.dismissActionFailure,
              ),
            ),
          Expanded(
            child: NestAsyncView<FamilyRoster>(
              state: controller.roster,
              isEmpty: (roster) => roster.isEmpty,
              onRetry: controller.retry,
              emptyBuilder: (_) => const NestEmptyView(
                title: FamilyCopy.emptyTitle,
                message: FamilyCopy.emptyBody,
                icon: LucideIcons.users,
              ),
              dataBuilder: (_, roster) =>
                  FamilyList(roster: roster, controller: controller),
            ),
          ),
        ],
      ),
    );
  }
}
