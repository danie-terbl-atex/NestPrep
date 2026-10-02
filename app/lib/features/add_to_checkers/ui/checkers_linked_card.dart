import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/checkers_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/household_clock.dart';
import '../state/checkers_link_controller.dart';

/// Linked: to which number, until when on the household's clock, and the way
/// to unlink — which deletes the session on the server.
class CheckersLinkedCard extends StatelessWidget {
  const CheckersLinkedCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CheckersLinkController>();
    final clock = context.read<HouseholdClock>();
    final nest = NestTheme.of(context);
    final status = switch (controller.status) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final expiresAt = status?.expiresAt;
    final until = expiresAt == null
        ? ''
        : NestDates.timeOfDay(clock.minutesOfDay(expiresAt));
    return NestCard(
      variant: NestCardVariant.flat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(CheckersCopy.linkedTitle, style: nest.text.title),
          const SizedBox(height: NestSpace.xs),
          Text(
            CheckersCopy.linkedBody(status?.mobileMasked ?? '', until),
            style: nest.text.bodySecondary,
          ),
          const SizedBox(height: NestSpace.lg),
          NestButton(
            label: CheckersCopy.unlink,
            variant: NestButtonVariant.outline,
            isLoading: controller.isBusy,
            onPressed: controller.isBusy ? null : controller.unlink,
          ),
        ],
      ),
    );
  }
}
