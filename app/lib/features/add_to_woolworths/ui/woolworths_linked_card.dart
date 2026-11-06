import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/woolworths_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/household_clock.dart';
import '../state/woolworths_link_controller.dart';

/// Linked: to which account, since when, and the way to unlink — which
/// forgets the session on the server.
class WoolworthsLinkedCard extends StatelessWidget {
  const WoolworthsLinkedCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WoolworthsLinkController>();
    final clock = context.read<HouseholdClock>();
    final nest = NestTheme.of(context);
    final status = switch (controller.status) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final linkedAt = status?.linkedAt;
    final email = status?.emailMasked;
    return NestCard(
      variant: NestCardVariant.flat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(WoolworthsCopy.linkedTitle, style: nest.text.title),
          const SizedBox(height: NestSpace.xs),
          if (email != null)
            Text(WoolworthsCopy.linkedAs(email), style: nest.text.body),
          if (linkedAt != null)
            Text(
              WoolworthsCopy.linkedSince(
                NestDates.full(clock.dateOf(linkedAt), clock.today),
              ),
              style: nest.text.bodySecondary,
            ),
          Text(WoolworthsCopy.linkedBody, style: nest.text.bodySecondary),
          const SizedBox(height: NestSpace.lg),
          NestButton(
            key: const ValueKey('woolworths-unlink'),
            label: WoolworthsCopy.unlink,
            variant: NestButtonVariant.outline,
            isLoading: controller.isBusy,
            onPressed: controller.isBusy ? null : controller.unlink,
          ),
        ],
      ),
    );
  }
}
