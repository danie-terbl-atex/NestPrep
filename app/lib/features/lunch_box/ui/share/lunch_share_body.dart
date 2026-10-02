import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../design/nest_kit.dart';
import '../../../../shared/copy/app_copy.dart';
import '../../model/lunch_board.dart';
import '../../state/lunch_share_controller.dart';
import 'lunch_card_choices.dart';
import 'lunch_card_preview.dart';
import 'lunch_planner_section.dart';

/// The share screen once the week has loaded: the card as it will be sent,
/// the one button that sends it, the choices that change it, and the
/// printable planner. A week with nothing packed still shows the card and
/// says why it cannot go yet — the planner below is still a way out
/// (`FE-08`).
class LunchShareBody extends StatelessWidget {
  const LunchShareBody({required this.board, super.key});

  final LunchBoard board;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LunchShareController>();
    final content = controller.contentFor(board);
    final failure = controller.actionFailure;
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        if (failure != null)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.md),
            child: NestBanner(
              message: AppCopy.failure(failure),
              tone: NestBannerTone.danger,
              actionLabel: AppCopy.back,
              onAction: controller.dismissActionFailure,
            ),
          ),
        NestRiseIn(
          child: LunchCardPreview(
            content: content,
            options: controller.options,
            inviteHost: controller.inviteHost,
          ),
        ),
        const SizedBox(height: NestSpace.xl),
        if (content.isEmpty) ...[
          const NestBanner(message: LunchShareCopy.nothingToShare),
          const SizedBox(height: NestSpace.md),
        ],
        NestButton(
          label: LunchShareCopy.shareImage,
          icon: LucideIcons.share,
          isLoading: controller.task == LunchShareTask.sharingCard,
          onPressed: content.isEmpty || controller.isBusy
              ? null
              : () => controller.shareCard(board),
        ),
        const SizedBox(height: NestSpace.xl),
        NestRiseIn(index: 1, child: LunchCardChoices(board: board)),
        const SizedBox(height: NestSpace.xl),
        NestRiseIn(index: 2, child: LunchPlannerSection(board: board)),
      ],
    );
  }
}
