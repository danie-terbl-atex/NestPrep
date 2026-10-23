import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/pnp_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/household_clock.dart';
import '../state/pnp_link_controller.dart';

/// Linked: since when, on the household's calendar, and the way to unlink —
/// which forgets the tokens on the server (add-to-pnp ADR-0003 §6).
class PnpLinkedCard extends StatelessWidget {
  const PnpLinkedCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PnpLinkController>();
    final clock = context.read<HouseholdClock>();
    final nest = NestTheme.of(context);
    final linkedAt = switch (controller.status) {
      AsyncData(:final value) => value.linkedAt,
      _ => null,
    };
    return NestCard(
      variant: NestCardVariant.flat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(PnpCopy.linkedTitle, style: nest.text.title),
          const SizedBox(height: NestSpace.xs),
          if (linkedAt != null)
            Text(
              PnpCopy.linkedSince(
                NestDates.full(clock.dateOf(linkedAt), clock.today),
              ),
              style: nest.text.bodySecondary,
            ),
          Text(PnpCopy.linkedBody, style: nest.text.bodySecondary),
          const SizedBox(height: NestSpace.lg),
          NestButton(
            label: PnpCopy.unlink,
            variant: NestButtonVariant.outline,
            isLoading: controller.isBusy,
            onPressed: controller.isBusy ? null : controller.unlink,
          ),
        ],
      ),
    );
  }
}
