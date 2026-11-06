import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../../household/model/people_view.dart';
import '../../household/ui/people_view_switch.dart';
import '../model/family_roster.dart';
import '../state/family_controller.dart';
import 'family_list.dart';

/// People's Profiles tab (design-system ADR-0022): every person in the
/// household with what is known about them, children first, and the
/// household's schools. All four async states come from the kit (`FE-08`).
class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FamilyController>();
    final failure = controller.actionFailure;
    return NestScaffold(
      title: MoreCopy.peopleTitle,
      leading: backLeading(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PeopleViewSwitch(current: PeopleView.profiles),
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
