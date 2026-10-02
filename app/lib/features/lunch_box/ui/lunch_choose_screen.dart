import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../model/lunch_choice_day.dart';
import '../state/lunch_choose_controller.dart';
import 'lunch_choose_body.dart';

/// A child choosing their lunch (lunch-box ADR-0008) — on their own tablet,
/// or on a parent's phone handed over, when [childName] greets them and
/// [onDone] hands it back. Nothing to choose says so kindly; a refused pick
/// is said in a child's words.
class LunchChooseScreen extends StatelessWidget {
  const LunchChooseScreen({this.childName, this.onDone, super.key});

  final String? childName;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LunchChooseController>();
    final failure = controller.actionFailure;
    final name = childName;
    return NestScaffold(
      title: name == null
          ? LunchKidPicksCopy.chooserTitle
          : LunchKidPicksCopy.chooserTitleFor(name),
      leading: backLeading(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.md),
              child: NestBanner(
                message: AppCopy.failure(failure),
                tone: NestBannerTone.warning,
                actionLabel: AppCopy.back,
                onAction: controller.dismissActionFailure,
              ),
            ),
          Expanded(
            child: NestAsyncView<List<LunchChoiceDay>>(
              state: controller.days,
              isEmpty: (days) => days.isEmpty,
              onRetry: controller.retry,
              emptyBuilder: (context) => const NestEmptyView(
                icon: LucideIcons.sandwich,
                title: LunchKidPicksCopy.nothingToChoose,
                message: LunchKidPicksCopy.nothingToChooseBody,
              ),
              dataBuilder: (context, days) =>
                  LunchChooseBody(days: days, onDone: onDone),
            ),
          ),
        ],
      ),
    );
  }
}
