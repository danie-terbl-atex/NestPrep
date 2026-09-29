import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../../household/model/household_view.dart';
import '../../household/model/member.dart';
import '../../household/model/member_role.dart';
import '../model/shift_booking.dart';
import '../state/bookings_controller.dart';
import 'booking_row.dart';
import 'carer_access_row.dart';
import 'hub_clock.dart';
import 'hub_empty_note.dart';

/// What the booked-shifts screen shows once the bookings have loaded. Family
/// sees the carers — and whether each is kept to their shifts — then every
/// shift coming up; a carer sees only their own.
class BookingsView extends StatelessWidget {
  const BookingsView({
    required this.bookings,
    required this.carers,
    required this.controller,
    required this.view,
    super.key,
  });

  final List<ShiftBooking> bookings;
  final List<Member> carers;
  final BookingsController controller;
  final HouseholdView view;

  Future<void> _cancel(BuildContext context, ShiftBooking booking) async {
    final confirmed = await showNestConfirm(
      context: context,
      title: NannyBookingCopy.cancelConfirm,
      message: NannyBookingCopy.cancelBody,
      confirmLabel: NannyBookingCopy.cancelAction,
      cancelLabel: NannyBookingCopy.keep,
      isDangerous: true,
    );
    if (confirmed != true) return;
    await controller.cancel(booking);
  }

  @override
  Widget build(BuildContext context) {
    final clock = context.read<HouseholdClock>();
    final now = clock.now;
    final isFamily = controller.isFamily;
    final sections = <Widget>[
      if (isFamily) ...[
        const NestSectionHeader(title: NannyBookingCopy.carers),
        if (!carers.any((carer) => carer.role == MemberRole.carer))
          const HubEmptyNote(
            icon: Icons.person_add_alt_1_outlined,
            title: NannyBookingCopy.noCarersTitle,
            message: NannyBookingCopy.noCarersBody,
          ),
        // Only a carer can be kept to their booked shifts (nanny-hub
        // ADR-0006); a helper can be booked, and is not listed here.
        for (final carer in carers)
          if (carer.role == MemberRole.carer)
            CarerAccessRow(
              key: ValueKey(carer.id),
              carer: carer,
              isShiftOnly: view.household.isShiftOnly(carer.id),
              isChanging: controller.isChangingShiftOnly(carer.id),
              onChanged: view.viewerIsAdmin
                  ? (isShiftOnly) => controller.setShiftOnly(
                      carer.id,
                      isShiftOnly: isShiftOnly,
                    )
                  : null,
            ),
      ],
      NestSectionHeader(
        title: isFamily
            ? NannyBookingCopy.upcoming
            : NannyBookingCopy.yourShifts,
      ),
      if (bookings.isEmpty)
        HubEmptyNote(
          icon: Icons.event_available_outlined,
          title: NannyBookingCopy.noBookingsTitle,
          message: isFamily
              ? NannyBookingCopy.noBookingsBody
              : NannyBookingCopy.yourShiftsEmpty,
        ),
      for (final booking in bookings)
        BookingRow(
          key: ValueKey(booking.id),
          when: clock.bookingOf(booking),
          carer: isFamily ? view.memberById(booking.carerMemberId) : null,
          note: booking.note,
          isOnNow: booking.isOpenAt(now),
          onCancel: isFamily ? () => _cancel(context, booking) : null,
        ),
    ];
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge * 2),
      children: [
        for (final (index, section) in sections.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: NestRiseIn(index: index, child: section),
          ),
      ],
    );
  }
}
