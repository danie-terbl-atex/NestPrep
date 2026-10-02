import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/checkers_copy.dart';
import '../../../shared/failure/app_failure.dart';
import '../model/checkers_push_state.dart';
import '../state/checkers_push_controller.dart';
import 'checkers_push_result_view.dart';

/// What *Add to Checkers* did, as it happens: adding, a failure with a retry,
/// a link that ran out, or the result (`FE-08`).
Future<void> showCheckersPushSheet({
  required BuildContext context,
  required CheckersPushController controller,
  required Map<String, String> itemNames,
  required VoidCallback onLink,
  required VoidCallback onManageLink,
}) => showNestSheet<void>(
  context: context,
  title: CheckersCopy.pushTitle,
  builder: (sheetContext) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => SingleChildScrollView(
      child: switch (controller.state) {
        CheckersPushIdle() || CheckersPushing() => const _Pushing(),
        CheckersPushNeedsLink() => _Notice(
          message: CheckersCopy.problem(CheckersProblem.linkExpired),
          actionLabel: CheckersCopy.linkTitle,
          onAction: () {
            Navigator.of(sheetContext).pop();
            onLink();
          },
        ),
        CheckersPushFailed(:final failure) => _Notice(
          message: AppCopy.failure(failure),
          actionLabel: CheckersCopy.retry,
          onAction: controller.retry,
        ),
        CheckersPushed(:final result) => CheckersPushResultView(
          result: result,
          itemNames: itemNames,
          onDone: () => Navigator.of(sheetContext).pop(),
          onManageLink: () {
            Navigator.of(sheetContext).pop();
            onManageLink();
          },
        ),
      },
    ),
  ),
);

class _Pushing extends StatelessWidget {
  const _Pushing();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        CheckersCopy.pushing,
        style: NestTheme.of(context).text.bodySecondary,
      ),
      const SizedBox(height: NestSpace.md),
      const NestSkeleton.rows(count: 3),
    ],
  );
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(message, style: NestTheme.of(context).text.body),
      const SizedBox(height: NestSpace.lg),
      NestButton(label: actionLabel, onPressed: onAction),
    ],
  );
}
