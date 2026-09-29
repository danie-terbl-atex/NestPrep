import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/two_homes/model/change_request.dart';
import 'package:nestprep/features/two_homes/model/co_parent_link.dart';
import 'package:nestprep/features/two_homes/model/custody_band.dart';
import 'package:nestprep/features/two_homes/model/custody_side.dart';
import 'package:nestprep/features/two_homes/model/handover_note.dart';
import 'package:nestprep/features/two_homes/model/two_homes_access.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/two_homes_model_fixtures.dart';

/// A link as each home sees it (household ADR-0004), and what a viewer may
/// do with it — the client's mirror of the rules, so nobody is offered what
/// the server would refuse.
void main() {
  final friday = CalendarDate(2026, 10, 2);

  group('a link', () {
    test('names its own home and the other one by side', () {
      final ours = aLink();
      expect(ours.ownHome, mumsHome);
      expect(ours.otherHome, dadsHome);
      final theirs = aLink(ownSide: CustodySide.b);
      expect(theirs.ownHome, dadsHome);
      expect(theirs.otherSide, CustodySide.a);
    });

    test('shows days only while it is active', () {
      expect(aLink().daysBetween(friday, friday), hasLength(1));
      for (final status in [
        LinkStatus.pending,
        LinkStatus.declined,
        LinkStatus.ended,
      ]) {
        final link = aLink(status: status);
        expect(link.daysBetween(friday, friday), isEmpty, reason: '$status');
        expect(link.upcoming(friday), isEmpty, reason: '$status');
      }
    });

    test('knows when it is waiting on this home to confirm', () {
      expect(
        aLink(
          status: LinkStatus.pending,
          awaitingSide: CustodySide.a,
        ).awaitsOurConfirmation,
        isTrue,
      );
      expect(
        aLink(
          status: LinkStatus.pending,
          ownSide: CustodySide.b,
          awaitingSide: CustodySide.a,
        ).awaitsOurConfirmation,
        isFalse,
      );
      expect(aLink().isOpen, isTrue);
      expect(aLink(status: LinkStatus.ended).isOpen, isFalse);
    });

    test('a status this build does not know reads as ended — never shared', () {
      // The server's timestamps are the fixture's business; this is about
      // the status.
      final json = aLink().toJson()
        ..['status'] = 'paused'
        ..remove('createdAt')
        ..remove('updatedAt');
      final read = CoParentLink.fromJson({...json, 'id': 'link-sam'});
      expect(read.status, LinkStatus.ended);
    });
  });

  group('a band on the calendar', () {
    test('is in the colour of the home the child is with that day', () {
      final link = aLink();
      final band = CustodyBand(
        link: link,
        day: link.daysBetween(friday, friday).single,
      );
      expect(band.home, mumsHome);
      expect(band.isWithUs, isTrue);
      expect(band.day.isHandover, isTrue);
      expect(band.key, 'custody_link-sam_2026-10-02');
    });
  });

  group('a request', () {
    test('counts the days a swap covers', () {
      final request = ChangeRequest(
        id: 'r',
        kind: ChangeKind.swap,
        from: CalendarDate(2026, 10, 9),
        to: CalendarDate(2026, 10, 11),
        proposedBySide: CustodySide.b,
        status: RequestStatus.pending,
      );
      expect(request.dayCount, 3);
      expect(request.isPending, isTrue);
      expect(request.copyWith(from: null).dayCount, 0);
    });
  });

  group('a handover', () {
    test('counts what is packed, and whether anything is written', () {
      final note = HandoverNote(
        id: '2026-10-02',
        date: friday,
        items: const [
          HandoverItem(text: 'Bag', packed: true),
          HandoverItem(text: 'Inhaler', packed: false),
        ],
      );
      expect(note.packedCount, 1);
      expect(note.hasNotes, isFalse);
      expect(note.copyWith(homework: 'Maths').hasNotes, isTrue);
    });
  });

  group('who may see and do what', () {
    test('an admin sees everything and manages the link', () {
      final access = TwoHomesAccess.of(Fixtures.view());
      expect(access.canSeeSchedule, isTrue);
      expect(access.canSeeHandovers, isTrue);
      expect(access.canSeeRequests, isTrue);
      expect(access.isFamily, isTrue);
      expect(access.isAdmin, isTrue);
      expect(access.showsWayIn, isTrue);
    });

    test(
      'a helper who reads the calendar sees where the child is, no more',
      () {
        final access = TwoHomesAccess.of(
          Fixtures.helperView(
            AccessGrant.uniform(AccessLevel.none)
                .withLevel(HouseholdArea.calendar, AccessLevel.view),
          ),
        );
        expect(access.canSeeSchedule, isTrue);
        expect(access.canSeeHandovers, isFalse);
        expect(access.canSeeRequests, isFalse);
        expect(access.showsWayIn, isFalse);
      },
    );

    test('handovers need medical as well as the calendar', () {
      final access = TwoHomesAccess.of(
        Fixtures.helperView(
          AccessGrant.uniform(AccessLevel.none)
              .withLevel(HouseholdArea.calendar, AccessLevel.view)
              .withLevel(HouseholdArea.medical, AccessLevel.view),
        ),
      );
      expect(access.canSeeHandovers, isTrue);
      expect(access.canSeeRequests, isFalse);
    });

    test('requests follow whoever may change the calendar', () {
      final access = TwoHomesAccess.of(
        Fixtures.helperView(
          AccessGrant.uniform(AccessLevel.none)
              .withLevel(HouseholdArea.calendar, AccessLevel.edit),
        ),
      );
      expect(access.canSeeRequests, isTrue);
      expect(access.isFamily, isFalse);
    });

    test('a helper with no calendar sees nothing of two homes', () {
      final access = TwoHomesAccess.of(
        Fixtures.helperView(AccessGrant.uniform(AccessLevel.none)),
      );
      expect(access.canSeeSchedule, isFalse);
      expect(access, isNot(TwoHomesAccess.of(Fixtures.view())));
    });
  });
}
