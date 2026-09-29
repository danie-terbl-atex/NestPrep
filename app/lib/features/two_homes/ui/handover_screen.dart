import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../../../shared/ui/back_leading.dart';
import '../../household/model/household_view.dart';
import '../model/handover_view.dart';
import '../model/two_homes_access.dart';
import '../state/handover_controller.dart';
import 'handover_form.dart';

/// One handover, written up for both homes (household ADR-0004): who goes
/// where, what is in the bag, medicine given, homework, clothes and anything
/// else. Family edits it; anybody else whose grant reaches it reads it.
class HandoverScreen extends StatelessWidget {
  const HandoverScreen({required this.today, super.key});

  final CalendarDate today;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HandoverController>();
    final failure = controller.actionFailure;
    return NestScaffold(
      title: TwoHomesHandoverCopy.title,
      subtitle: NestDates.relative(controller.date, today),
      leading: backLeading(context),
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
            child: NestAsyncView<HandoverView?>(
              state: controller.view,
              isEmpty: (view) => view == null,
              onRetry: controller.retry,
              emptyBuilder: (_) => const NestEmptyView(
                icon: Icons.link_off,
                title: TwoHomesHandoverCopy.title,
                message: TwoHomesCopy.linkGone,
              ),
              dataBuilder: (context, view) => view == null
                  ? const SizedBox.shrink()
                  : HandoverForm(
                      view: view,
                      canEdit:
                          TwoHomesAccess.of(context.watch<HouseholdView>())
                              .isFamily &&
                          view.link.isActive,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
