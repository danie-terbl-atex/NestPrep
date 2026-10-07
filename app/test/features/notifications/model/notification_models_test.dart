import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/model/access_defaults.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_permissions.dart';
import 'package:nestprep/features/notifications/model/digest_coverage.dart';
import 'package:nestprep/features/notifications/model/inbox_groups.dart';
import 'package:nestprep/features/notifications/model/inbox_item.dart';
import 'package:nestprep/features/notifications/model/notification_settings.dart';
import 'package:nestprep/features/notifications/model/notification_vocabulary.dart';
import 'package:nestprep/features/notifications/model/push_arrival.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/household_fixtures.dart';

/// Notifications' own rules on the phone (notifications ADR-0001 to ADR-0003):
/// the first-time defaults, the slot the digest job asks for, what a push's
/// data may be, how an inbox groups, and what a digest can hold for whom.
void main() {
  setUpAll(tz_data.initializeTimeZones);

  group('a person’s choices', () {
    test('family gets the digest at 06:30 the first time; others choose', () {
      final parent = NotificationSettings.firstTime(
        memberId: 'm-sam',
        updatedBy: 'm-sam',
        isFamily: true,
      );
      final helper = NotificationSettings.firstTime(
        memberId: 'm-thandi',
        updatedBy: 'm-thandi',
        isFamily: false,
      );
      expect(parent.digest, const DigestChoice(enabled: true));
      expect(parent.digest.minute, 390);
      expect(helper.digest.enabled, isFalse);
      for (final category in SwitchableCategory.values) {
        expect(parent.wants(category), isTrue);
      }
      expect(parent.quietHours, const QuietHours());
    });

    test(
      'the slot is the quarter hour while the digest is on, and none off',
      () {
        const on = NotificationSettings(
          id: 'm',
          updatedBy: 'm',
          digest: DigestChoice(enabled: true, minute: 420),
        );
        expect(on.digestSlot, 28);
        expect(on.copyWith(digest: const DigestChoice()).digestSlot, isNull);
      },
    );

    test('switching one category leaves the others as they were', () {
      final settings = NotificationSettings.unchosen(
        'm',
      ).withCategory(SwitchableCategory.chores, false);
      expect(settings.categories, {
        'documents': true,
        'handover': true,
        'chores': false,
      });
    });
  });

  group('a push’s data', () {
    test('reads ids and kinds into an arrival', () {
      final arrival = PushArrival.fromData(const {
        'householdId': 'h1',
        'inboxId': 'expiry_r1_m-sam',
        'target': 'shiftSummary',
        'targetId': 'shift-1',
      }, title: 'The shift handover is ready');
      expect(arrival?.target, NotificationTarget.shiftSummary);
      expect(arrival?.targetId, 'shift-1');
      expect(arrival?.title, 'The shift handover is ready');
    });

    test(
      'is not ours without a household and an item — refused, not guessed',
      () {
        expect(PushArrival.fromData(const {'inboxId': 'x'}), isNull);
        expect(PushArrival.fromData(const {'householdId': 'h1'}), isNull);
        expect(
          PushArrival.fromData(const {'householdId': 7, 'inboxId': 'x'}),
          isNull,
        );
      },
    );

    test('an unknown target opens the inbox, and an empty id is none', () {
      final arrival = PushArrival.fromData(const {
        'householdId': 'h1',
        'inboxId': 'x',
        'target': 'somethingNewer',
        'targetId': '',
      });
      expect(arrival?.target, NotificationTarget.inboxItem);
      expect(arrival?.targetId, isNull);
    });
  });

  group('the inbox', () {
    final clock = HouseholdClock('Africa/Johannesburg');

    InboxItem item(String id, DateTime? at) => InboxItem(
      id: id,
      memberId: 'm-sam',
      category: 'digest',
      title: 't',
      body: 'b',
      createdAt: at,
      localDate: '2026-09-29',
    );

    test('splits today from before, on the household’s clock', () {
      final now = clock.now;
      final groups = InboxGroups.of([
        item('new', now),
        item('old', now.subtract(const Duration(days: 3))),
      ], clock);
      expect(groups.today.map((each) => each.id), ['new']);
      expect(groups.earlier.map((each) => each.id), ['old']);
    });

    test('says the time for today, and the day before that', () {
      final now = clock.now;
      expect(
        InboxGroups.whenOf(item('a', now), clock),
        matches(r'^\d\d:\d\d$'),
      );
      expect(
        InboxGroups.whenOf(
          item('b', now.subtract(const Duration(days: 1))),
          clock,
        ),
        'Yesterday',
      );
    });

    test('a day it cannot read is no day, never a crash', () {
      expect(item('x', null).copyWith(localDate: 'garbage').day, isNull);
      expect(item('x', null).day?.iso, '2026-09-29');
    });

    test('an unknown category reads as a digest', () {
      expect(
        item('x', null).copyWith(category: 'fromTheFuture').kind,
        NotificationCategory.digest,
      );
    });
  });

  group('what a digest can hold (ADR-0002)', () {
    test('family: every section', () {
      final family = HouseholdPermissions.of(
        Fixtures.household(),
        Fixtures.samUid,
      );
      expect(digestCoverage(family), DigestSectionKind.values);
    });

    test('a helper who only cleans: nothing', () {
      final cleaner = Fixtures.helperView(
        AccessGrant.uniform(AccessLevel.none),
      ).permissions;
      expect(digestCoverage(cleaner), isEmpty);
    });

    test('a carer: the day, the lunches, their chores and the hub', () {
      final carer = Fixtures.helperView(AccessDefaults.carer).permissions;
      expect(digestCoverage(carer), [
        DigestSectionKind.events,
        DigestSectionKind.pack,
        DigestSectionKind.chores,
        DigestSectionKind.shift,
      ]);
    });
  });
}
