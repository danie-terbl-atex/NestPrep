import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/product_analytics/model/weekly_numbers.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

/// One week's totals as the rollup writes them (product-analytics ADR-0001).
void main() {
  group('reading a totals document', () {
    test('reads every count the rollup writes', () {
      final numbers = WeeklyNumbers.fromJson({
        'id': '2026-W40',
        'week': '2026-W40',
        'weekStart': '2026-09-28',
        'activeFamilies': 12,
        'familiesSeen': 20,
        'lunchPlansCreated': 31,
        'familiesPlanningLunches': 9,
        'newFamilies': 5,
        'newFamiliesInvitingAnAdult': 3,
        'isInviteCohortComplete': true,
        'computedAt': Timestamp.fromDate(DateTime.utc(2026, 10, 5, 1)),
        // Written by the rollup and not shown on the phone — ignored, not
        // refused, so the server can grow a field without breaking this.
        'adultInvitesByRole': {'member': 2, 'helper': 1},
        'definitionVersion': 1,
      });

      expect(numbers.week, '2026-W40');
      expect(numbers.weekStart, CalendarDate(2026, 9, 28));
      expect(numbers.activeFamilies, 12);
      expect(numbers.familiesSeen, 20);
      expect(numbers.lunchPlansCreated, 31);
      expect(numbers.familiesPlanningLunches, 9);
      expect(numbers.newFamilies, 5);
      expect(numbers.newFamiliesInvitingAnAdult, 3);
      expect(numbers.isInviteCohortComplete, isTrue);
      expect(numbers.computedAt, DateTime.utc(2026, 10, 5, 1));
    });

    test('reads a count missing from an older document as zero', () {
      final numbers = WeeklyNumbers.fromJson({
        'week': '2026-W40',
        'weekStart': '2026-09-28',
      });

      expect(numbers.activeFamilies, 0);
      expect(numbers.newFamilies, 0);
      expect(numbers.isInviteCohortComplete, isFalse);
      expect(numbers.computedAt, isNull);
    });

    test('refuses a week whose Monday is not a date', () {
      expect(
        () => WeeklyNumbers.fromJson({'week': '2026-W40', 'weekStart': 'soon'}),
        throwsFormatException,
      );
    });
  });

  group('the invite rate', () {
    WeeklyNumbers cohort(int inviting, int newFamilies) => WeeklyNumbers(
      week: '2026-W40',
      weekStart: CalendarDate(2026, 9, 28),
      newFamilies: newFamilies,
      newFamiliesInvitingAnAdult: inviting,
    );

    test('is a whole percentage of the families that started that week', () {
      expect(cohort(2, 3).inviteRatePercent, 67);
      expect(cohort(1, 8).inviteRatePercent, 13);
      expect(cohort(0, 4).inviteRatePercent, 0);
      expect(cohort(5, 5).inviteRatePercent, 100);
    });

    test('is nothing at all when nobody started that week — not 0%', () {
      expect(cohort(0, 0).inviteRatePercent, isNull);
    });
  });
}
