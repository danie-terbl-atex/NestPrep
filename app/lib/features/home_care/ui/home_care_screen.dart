import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/home_care_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../model/home_care_board.dart';
import '../state/home_care_controller.dart';
import 'home_care_shortcuts.dart';
import 'job_list.dart';

/// Home care's front door: the jobs, in three piles — to do, to review,
/// done. A parent sees every job and can start a new one; a helper sees the
/// jobs assigned to her (home-care ADR-0001).
///
/// Reached from the household screen, like the family and the documents,
/// because the bottom bar stays at the four things a household does in a
/// week.
class HomeCareScreen extends StatelessWidget {
  const HomeCareScreen({required this.pile, super.key});

  /// The pile on show, from the route so it can be linked to (`FE-17`).
  final JobPile pile;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeCareController>();
    final access = controller.access;
    final householdId = controller.householdId;
    final failure = controller.actionFailure;
    return NestScaffold(
      title: access.canManage ? HomeCareCopy.title : HomeCareCopy.yourJobs,
      subtitle: access.canManage
          ? HomeCareCopy.subtitle
          : HomeCareCopy.helperSubtitle,
      leading: backLeading(context),
      trailing: [
        NestIconButton(
          icon: Icons.meeting_room_outlined,
          label: HomeCareLibraryCopy.rooms,
          onPressed: () =>
              context.push(HomeCareRoute.roomsPathFor(householdId)),
        ),
        NestIconButton(
          icon: Icons.sanitizer_outlined,
          label: HomeCareLibraryCopy.products,
          onPressed: () =>
              context.push(HomeCareRoute.productsPathFor(householdId)),
        ),
        const AccountMenuButton(),
      ],
      floatingAction: access.canManage
          ? NestButton(
              label: HomeCareCopy.newJob,
              icon: Icons.add_a_photo_outlined,
              isExpanded: false,
              onPressed: () =>
                  context.push(HomeCareRoute.newJobPathFor(householdId)),
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
            child: NestAsyncView<HomeCareBoard>(
              state: controller.board,
              // The piles are the controls, so the list *is* the empty
              // state and says so in place (`FE-08`).
              isEmpty: (_) => false,
              onRetry: controller.retry,
              emptyBuilder: (_) => const SizedBox.shrink(),
              dataBuilder: (context, board) => JobList(
                header: const HomeCareShortcuts(),
                board: board,
                pile: pile,
                access: access,
                onSelectPile: (next) => context.replace(
                  HomeCareRoute.pathFor(householdId, pile: next),
                ),
                onOpen: (job) =>
                    context.push(HomeCareRoute.jobPathFor(householdId, job.id)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
