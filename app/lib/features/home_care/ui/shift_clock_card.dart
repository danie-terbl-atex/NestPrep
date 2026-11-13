import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../model/shift/helper_shift.dart';
import '../state/helper_shifts_controller.dart';
import 'end_shift_sheet.dart';
import 'shift_clock.dart';

/// A helper's clock, first on home care's front door (home-care ADR-0007):
/// *Start shift* until she is clocked in, then since when, and *End shift*.
class ShiftClockCard extends StatelessWidget {
  const ShiftClockCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HelperShiftsController>();
    final nest = NestTheme.of(context);
    final clock = context.read<HouseholdClock>();
    final failure = controller.actionFailure;
    final shifts = controller.shifts;
    if (shifts case AsyncFailure(failure: final unread)) {
      return NestBanner(
        message: AppCopy.failure(unread),
        tone: NestBannerTone.danger,
        actionLabel: AppCopy.retry,
        onAction: controller.retry,
      );
    }
    final open = controller.ownOpenShift;
    return NestCard(
      variant: NestCardVariant.tinted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              NestIconTile(
                icon: open == null ? LucideIcons.clock : LucideIcons.clockCheck,
                tint: NestTileTint.basil,
              ),
              const SizedBox(width: NestSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      open == null
                          ? HomeCareShiftCopy.readyTitle
                          : HomeCareShiftCopy.onShiftTitle,
                      style: nest.text.title,
                    ),
                    Text(
                      open == null
                          ? HomeCareShiftCopy.readyBody
                          : HomeCareShiftCopy.since(
                              clock.shiftTime(open.startedAt),
                            ),
                      style: nest.text.bodySecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (failure != null) ...[
            const SizedBox(height: NestSpace.md),
            NestBanner(
              message: AppCopy.failure(failure),
              tone: NestBannerTone.danger,
              actionLabel: AppCopy.back,
              onAction: controller.dismissActionFailure,
            ),
          ],
          const SizedBox(height: NestSpace.lg),
          if (open == null)
            NestButton(
              label: HomeCareShiftCopy.startShift,
              icon: LucideIcons.play,
              isLoading: controller.isBusy,
              onPressed: shifts is AsyncData && !controller.isBusy
                  ? controller.start
                  : null,
            )
          else
            NestButton(
              label: HomeCareShiftCopy.endShift,
              icon: LucideIcons.logOut,
              variant: NestButtonVariant.outline,
              isLoading: controller.isBusy,
              onPressed: controller.isBusy
                  ? null
                  : () => _end(context, controller, clock, open),
            ),
        ],
      ),
    );
  }

  static Future<void> _end(
    BuildContext context,
    HelperShiftsController controller,
    HouseholdClock clock,
    HelperShift shift,
  ) async {
    final ends = await showEndHelperShiftSheet(
      context: context,
      title: HomeCareShiftCopy.endTitle,
      body: HomeCareShiftCopy.endBody(clock.shiftTime(shift.startedAt)),
    );
    if (ends) await controller.end(shift);
  }
}
