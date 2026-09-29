import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/grocery_plan_copy.dart';
import '../../household/model/household_view.dart';
import '../model/grocery_plan_selection.dart';
import '../model/grocery_plan_view.dart';
import '../state/grocery_plan_controller.dart';
import 'grocery_plan_content.dart';

/// *From this week's plans* (groceries ADR-0002): what the week's meals and
/// lunch boxes would change on the list, for a person to tick through — and
/// the switch that lets the list keep itself in step. Nothing is written
/// until they say so.
Future<void> showGroceryPlanSheet({
  required BuildContext context,
  required ValueChanged<GroceryPlanDestination> onPlan,
}) {
  final controller = context.read<GroceryPlanController>();
  final household = context.read<HouseholdView>();
  return showNestSheet<void>(
    context: context,
    title: GroceryPlanCopy.title,
    builder: (sheetContext) => _GroceryPlanSheetBody(
      controller: controller,
      nameOf: (memberId) => household.memberById(memberId)?.displayName,
      onPlan: onPlan,
    ),
  );
}

class _GroceryPlanSheetBody extends StatefulWidget {
  const _GroceryPlanSheetBody({
    required this.controller,
    required this.nameOf,
    required this.onPlan,
  });

  final GroceryPlanController controller;
  final String? Function(String memberId) nameOf;
  final ValueChanged<GroceryPlanDestination> onPlan;

  @override
  State<_GroceryPlanSheetBody> createState() => _GroceryPlanSheetBodyState();
}

class _GroceryPlanSheetBodyState extends State<_GroceryPlanSheetBody> {
  /// What the person ticked is theirs, local to this sheet (`FE-07`).
  final _selection = GroceryPlanSelection();

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    // The sheet is its own route, above the screen's providers, so it listens
    // to the controller it was handed rather than looking one up.
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => switch (controller.view) {
        AsyncLoading() => const NestLoadingView(rows: 3),
        AsyncFailure(:final failure) => NestErrorView(
          message: AppCopy.failure(failure),
          retryLabel: AppCopy.retry,
          onRetry: controller.retry,
        ),
        AsyncData(:final value) => GroceryPlanContent(
          view: value,
          selection: _selection,
          now: controller.now,
          changedBy: switch (value.settings.updatedBy) {
            final memberId? => widget.nameOf(memberId),
            null => null,
          },
          onSelectionChanged: () => setState(() {}),
          onKeepInStep: controller.setKeepInStep,
          onStaple: controller.setStaple,
          onApply: () => _apply(value),
          onPlan: _plan,
        ),
      },
    );
  }

  /// The sheet closes first: offline, a write only completes when the network
  /// is back, and the list already shows it (the vault lesson on writes to an
  /// unreachable backend).
  Future<void> _apply(GroceryPlanView view) async {
    final chosen = _selection.chosenFrom(view.diff);
    Navigator.of(context).pop();
    await widget.controller.apply(
      addKeys: chosen.addKeys,
      refreshIds: chosen.refreshIds,
      removeIds: chosen.removeIds,
    );
  }

  void _plan(GroceryPlanDestination destination) {
    Navigator.of(context).pop();
    widget.onPlan(destination);
  }
}
