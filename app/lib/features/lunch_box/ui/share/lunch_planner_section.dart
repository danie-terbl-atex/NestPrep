import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../design/nest_kit.dart';
import '../../../../shared/copy/app_copy.dart';
import '../../model/lunch_board.dart';
import '../../state/lunch_share_controller.dart';

/// The printable A4 planner (lunch-box ADR-0005): this week written in, or
/// blank — the free printable — then print it or send it as a PDF.
class LunchPlannerSection extends StatelessWidget {
  const LunchPlannerSection({required this.board, super.key});

  final LunchBoard board;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<LunchShareController>();
    final task = controller.task;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NestSectionHeader(title: LunchShareCopy.plannerSection),
        Text(LunchShareCopy.plannerHint, style: nest.text.caption),
        const SizedBox(height: NestSpace.sm),
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            for (final (kind, label) in const [
              (LunchPlannerKind.filled, LunchShareCopy.plannerFilled),
              (LunchPlannerKind.blank, LunchShareCopy.plannerBlank),
            ])
              NestChip(
                label: label,
                isSelected: controller.plannerKind == kind,
                onTap: () => controller.choosePlanner(kind),
              ),
          ],
        ),
        const SizedBox(height: NestSpace.md),
        NestButton(
          label: LunchShareCopy.print,
          icon: LucideIcons.printer,
          variant: NestButtonVariant.tonal,
          size: NestButtonSize.medium,
          isLoading: task == LunchShareTask.printingPlanner,
          onPressed: controller.isBusy
              ? null
              : () => controller.printPlanner(board),
        ),
        const SizedBox(height: NestSpace.sm),
        NestButton(
          label: LunchShareCopy.sendPdf,
          icon: LucideIcons.fileText,
          variant: NestButtonVariant.outline,
          size: NestButtonSize.medium,
          isLoading: task == LunchShareTask.sendingPlanner,
          onPressed: controller.isBusy
              ? null
              : () => controller.sendPlanner(board),
        ),
      ],
    );
  }
}
