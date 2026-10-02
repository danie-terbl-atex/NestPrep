import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../model/shift_booking.dart';
import 'hub_clock.dart';

/// What a carer kept to their booked shifts sees between them (nanny-hub
/// ADR-0006): not an error and not a locked door, but when they are next
/// expected and when the household opens for them. The rules keep everything
/// else shut until then; this says so kindly.
class OffShiftScreen extends StatelessWidget {
  const OffShiftScreen({
    required this.upcoming,
    required this.onCheckAgain,
    super.key,
  });

  /// The carer's own booked shifts still to come, soonest first.
  final List<ShiftBooking> upcoming;
  final VoidCallback onCheckAgain;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final clock = context.read<HouseholdClock>();
    final next = upcoming.firstOrNull;
    final later = upcoming.skip(1).take(4).toList();
    return NestScaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: NestSpace.xxl),
        children: [
          const Center(child: NestBrandMark()),
          const SizedBox(height: NestSpace.xl),
          Text(
            NannyBookingCopy.offShiftTitle,
            style: nest.text.headline,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: NestSpace.xl),
          NestCard(
            variant: NestCardVariant.tinted,
            child: next == null
                ? Text(NannyBookingCopy.offShiftNone, style: nest.text.body)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        NannyBookingCopy.offShiftNext(clock.bookingOf(next)),
                        style: nest.text.title,
                      ),
                      const SizedBox(height: NestSpace.sm),
                      Text(
                        NannyBookingCopy.opensAt(clock.timeOf(next.opensAt)),
                        style: nest.text.bodySecondary,
                      ),
                    ],
                  ),
          ),
          if (later.isNotEmpty) ...[
            const SizedBox(height: NestSpace.xl),
            const NestSectionHeader(title: NannyBookingCopy.yourShifts),
            const SizedBox(height: NestSpace.sm),
            for (final booking in later)
              Padding(
                padding: const EdgeInsets.only(bottom: NestSpace.sm),
                child: NestCard(
                  variant: NestCardVariant.flat,
                  padding: EdgeInsets.zero,
                  child: NestListRow(
                    leading: const NestIconTile(
                      icon: Icons.event_available_outlined,
                      tint: NestTileTint.basil,
                    ),
                    title: clock.bookingOf(booking),
                    subtitle: booking.note,
                  ),
                ),
              ),
          ],
          const SizedBox(height: NestSpace.xl),
          NestButton(
            label: NannyBookingCopy.checkAgain,
            variant: NestButtonVariant.tonal,
            icon: Icons.refresh,
            onPressed: onCheckAgain,
          ),
        ],
      ),
    );
  }
}
