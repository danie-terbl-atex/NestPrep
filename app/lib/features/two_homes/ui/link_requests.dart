import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/two_homes_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../household/model/household_view.dart';
import '../model/change_request.dart';
import '../model/co_parent_link.dart';
import '../model/two_homes_access.dart';
import '../state/link_controller.dart';
import 'request_row.dart';
import 'swap_sheet.dart';

/// What the two homes have asked each other (household ADR-0004): the
/// requests still waiting first, with this home's answers, then the ways to
/// ask, then the history — every request kept, answered or not.
class LinkRequests extends StatelessWidget {
  const LinkRequests({required this.link, required this.childName, super.key});

  final CoParentLink link;
  final String childName;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LinkController>();
    final access = TwoHomesAccess.of(context.watch<HouseholdView>());
    final canAct = access.isFamily && link.isActive;
    final waiting = controller.waiting;
    final answered = controller.answered;
    final nest = NestTheme.of(context);

    Widget row(ChangeRequest request) => Padding(
      key: ValueKey(request.id),
      padding: const EdgeInsets.only(bottom: NestSpace.sm),
      child: RequestRow(
        request: request,
        link: link,
        childName: childName,
        today: controller.today,
        canAct: canAct,
        isBusy: controller.isSending,
        onAnswer: (answer) => controller.answer(request, answer),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NestSectionHeader(title: TwoHomesCopy.requests),
        const SizedBox(height: NestSpace.sm),
        if (waiting.isEmpty && answered.isEmpty)
          Text(TwoHomesCopy.noRequests, style: nest.text.bodySecondary),
        if (waiting.isNotEmpty) ...[
          Text(
            TwoHomesCopy.waitingForAnswer,
            style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.sm),
          for (final request in waiting) row(request),
        ],
        if (canAct) ...[
          const SizedBox(height: NestSpace.md),
          NestButton(
            label: TwoHomesCopy.askForASwap,
            icon: Icons.swap_horiz,
            variant: NestButtonVariant.tonal,
            onPressed: controller.isSending ? null : () => _askForSwap(context),
          ),
          const SizedBox(height: NestSpace.sm),
          NestButton(
            label: TwoHomesCopy.suggestSchedule,
            icon: Icons.event_repeat,
            variant: NestButtonVariant.outline,
            onPressed: () => context.push(
              TwoHomesRoute.schedulePathFor(controller.householdId, link.id),
            ),
          ),
        ],
        if (answered.isNotEmpty) ...[
          const SizedBox(height: NestSpace.xl),
          Text(
            TwoHomesCopy.history,
            style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.sm),
          for (final request in answered) row(request),
        ],
      ],
    );
  }

  Future<void> _askForSwap(BuildContext context) async {
    final controller = context.read<LinkController>();
    final ask = await showSwapSheet(
      context: context,
      link: link,
      today: controller.today,
    );
    if (ask == null) return;
    await controller.proposeSwap(
      from: ask.from,
      to: ask.to,
      toSide: ask.toSide,
      note: ask.note,
    );
  }
}
