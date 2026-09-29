import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../../../shared/ui/back_leading.dart';
import '../../household/model/household_view.dart';
import '../../household/model/member.dart';
import '../../household/model/member_role.dart';
import '../state/bookings_controller.dart';
import 'booking_sheet.dart';
import 'bookings_view.dart';

/// Booked shifts (nanny-hub ADR-0006): family books a carer's shifts ahead
/// and, as an admin, keeps a carer to them; a carer sees their own. The book
/// button is always there for family, including before anything is booked
/// (`FE-08`).
class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  /// Who can be booked: the grown-ups who are not family — carers and helpers.
  static List<Member> bookable(HouseholdView view) => [
    for (final member in view.members)
      if (member.role == MemberRole.carer || member.role == MemberRole.helper)
        member,
  ];

  Future<void> _book(BuildContext context, List<Member> carers) async {
    final controller = context.read<BookingsController>();
    final choice = await showBookingSheet(
      context: context,
      carers: carers,
      clock: context.read<HouseholdClock>(),
    );
    if (choice == null) return;
    await controller.book(
      carerMemberId: choice.carerMemberId,
      startsAt: choice.startsAt,
      endsAt: choice.endsAt,
      note: choice.note,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BookingsController>();
    final view = context.watch<HouseholdView>();
    final carers = bookable(view);
    final failure = controller.actionFailure;
    final mayBook = controller.isFamily && carers.isNotEmpty;
    return NestScaffold(
      title: NannyBookingCopy.bookingsTitle,
      leading: backLeading(context),
      floatingAction: mayBook
          ? NestButton(
              label: NannyBookingCopy.book,
              icon: Icons.add,
              isExpanded: false,
              isLoading: controller.isBooking,
              onPressed: controller.isBooking
                  ? null
                  : () => _book(context, carers),
            )
          : null,
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
            child: NestAsyncView(
              state: controller.upcoming,
              isEmpty: (_) => false,
              onRetry: controller.retry,
              emptyBuilder: (_) => const SizedBox.shrink(),
              dataBuilder: (context, bookings) => BookingsView(
                bookings: bookings,
                carers: carers,
                controller: controller,
                view: view,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
