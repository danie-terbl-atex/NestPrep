import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../recipes/ui/recipe_sheet.dart';
import '../model/fill_week_box.dart';
import '../state/fill_week_controller.dart';
import 'fill_week_box_card.dart';

/// Step 1 (lunch-box ADR-0020): the child's own go-to boxes and NestPrep's
/// ready-made ones, in two groups, to choose from — or none. Only a group
/// swaps between loading, nothing and a failure to read; the heading and
/// the ways on stay, so skipping is always there (`FE-08`).
class FillWeekBoxesPanel extends StatelessWidget {
  const FillWeekBoxesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<FillWeekController>();
    final name = controller.childWeek?.child.member.displayName ?? '';
    final goTo = controller.goToBoxes;
    final readyMade = controller.readyMadeBoxes;
    final hasNothing =
        goTo.isEmpty &&
        readyMade is AsyncData<List<FillWeekBox>> &&
        readyMade.value.isEmpty;
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        Text(FillWeekCopy.boxesHeadline(name), style: nest.text.headline),
        const SizedBox(height: NestSpace.xs),
        Text(FillWeekCopy.boxesBody, style: nest.text.bodySecondary),
        const SizedBox(height: NestSpace.xl),
        if (hasNothing)
          const NestEmptyView(
            icon: LucideIcons.packageOpen,
            title: FillWeekCopy.nothingToChooseTitle,
            message: FillWeekCopy.nothingToChooseBody,
          )
        else ...[
          const NestSectionHeader(title: FillWeekCopy.goToHeader),
          const SizedBox(height: NestSpace.sm),
          if (goTo.isEmpty)
            Text(FillWeekCopy.noGoToBoxes(name), style: nest.text.caption)
          else
            _Boxes(boxes: goTo, childName: name),
          const SizedBox(height: NestSpace.xl),
          const NestSectionHeader(title: FillWeekCopy.readyMadeHeader),
          const SizedBox(height: NestSpace.sm),
          switch (readyMade) {
            AsyncLoading() => const NestLoadingView(rows: 2),
            AsyncFailure(:final failure) => NestErrorView(
              message: AppCopy.failure(failure),
              retryLabel: AppCopy.retry,
              onRetry: controller.readyMade.load,
            ),
            AsyncData(:final value) when value.isEmpty => Text(
              FillWeekCopy.noReadyMade,
              style: nest.text.caption,
            ),
            AsyncData(:final value) => _Boxes(boxes: value, childName: name),
          },
        ],
        const SizedBox(height: NestSpace.xl),
        NestStepActions(
          nextKey: const ValueKey('fill-week-review'),
          nextLabel: FillWeekCopy.reviewAction,
          nextIcon: LucideIcons.arrowRight,
          onNext: controller.chosenBoxes.isEmpty ? null : controller.review,
          secondaryKey: const ValueKey('fill-week-skip'),
          secondaryLabel: FillWeekCopy.skipAction,
          onSecondary: controller.skip,
        ),
      ],
    );
  }
}

class _Boxes extends StatelessWidget {
  const _Boxes({required this.boxes, required this.childName});

  final List<FillWeekBox> boxes;
  final String childName;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FillWeekController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final box in boxes) ...[
          FillWeekBoxCard(
            key: ValueKey('fill-week-card-${box.id}'),
            box: box,
            turn: controller.turnOf(box),
            childName: childName,
            onToggle: box.canBeChosen ? () => controller.toggle(box) : null,
            onOpenRecipe: (recipe) => showRecipeSheet(context, recipe),
          ),
          const SizedBox(height: NestSpace.md),
        ],
      ],
    );
  }
}
