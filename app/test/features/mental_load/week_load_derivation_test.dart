import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/mental_load/model/load_sources.dart';
import 'package:nestprep/features/mental_load/model/week_load.dart';
import 'package:nestprep/features/mental_load/model/week_load_derivation.dart';
import 'package:nestprep/features/nanny_hub/model/shift.dart';
import 'package:nestprep/features/nanny_hub/model/shift_summary.dart';
import 'package:nestprep/shared/recurrence/recurrence_rule.dart';

import '../../support/household_fixtures.dart';
import '../../support/mental_load_fixtures.dart';

/// Who picked up what (calendar ADR-0006) — derived from what the calendar,
/// to-dos, groceries and the nanny hub already hold, never stored, and never
/// a ranking.
void main() {
  const sam = Fixtures.samMemberId;
  const alex = LoadFixtures.alexMemberId;

  WeekLoad derive(LoadSources sources) => deriveWeekLoad(
    members: LoadFixtures.members,
    sources: sources,
    weekStart: LoadFixtures.weekStart,
    today: LoadFixtures.wednesday,
    dayOf: LoadFixtures.dayOf,
  );

  AdultLoad of(WeekLoad week, String memberId) =>
      week.adults.firstWhere((adult) => adult.member.id == memberId);

  test('counts only the adults, in the household’s order', () {
    final week = derive(const LoadSources());
    expect(week.adults.map((adult) => adult.member.id), [sam, alex]);
    expect(week.isEmpty, isTrue);
  });

  test('an event planned counts once for its planner however often it '
      'happens; each occurrence counts for who is at it', () {
    final daily =
        LoadFixtures.event(
          'e1',
          createdBy: sam,
          memberIds: [alex],
          date: LoadFixtures.weekStart,
        ).copyWith(
          recurrence: const RecurrenceRule(
            frequency: RecurrenceFrequency.daily,
          ),
        );
    final week = derive(LoadSources(events: [daily]));
    expect(of(week, sam).countOf(LoadKind.eventsPlanned), 1);
    expect(of(week, sam).highlights, ['Event e1']);
    expect(of(week, alex).countOf(LoadKind.eventsAttended), 7);
  });

  test('an event for everyone is on nobody’s plate in particular', () {
    final week = derive(
      LoadSources(events: [LoadFixtures.event('e1', createdBy: alex)]),
    );
    expect(of(week, alex).countOf(LoadKind.eventsPlanned), 1);
    expect(of(week, sam).countOf(LoadKind.eventsAttended), 0);
  });

  test(
    'an event outside the week, or planned by the helper, is not counted',
    () {
      final week = derive(
        LoadSources(
          events: [
            LoadFixtures.event(
              'e1',
              createdBy: sam,
              date: LoadFixtures.weekStart.addDays(7),
            ),
            LoadFixtures.event('e2', createdBy: Fixtures.thandiMemberId),
          ],
        ),
      );
      expect(week.isEmpty, isTrue);
    },
  );

  test('a to-do done counts for the doer; one waiting for who it names', () {
    final week = derive(
      LoadSources(
        tasks: [
          LoadFixtures.task('t1', assigneeIds: [alex]),
          LoadFixtures.task('t2', assigneeIds: [alex, sam]),
          LoadFixtures.task('t3'),
        ],
        completions: [LoadFixtures.done('t1', by: sam)],
      ),
    );
    expect(of(week, sam).countOf(LoadKind.todosDone), 1);
    expect(of(week, sam).highlights, ['Task t1']);
    expect(of(week, sam).countOf(LoadKind.todosWaiting), 1);
    expect(of(week, alex).countOf(LoadKind.todosWaiting), 1);
    expect(of(week, alex).countOf(LoadKind.todosDone), 0);
  });

  test('groceries count for who bought and who noticed, in this week', () {
    final lastWeek = LoadFixtures.at(LoadFixtures.weekStart.addDays(-2));
    final wednesday = LoadFixtures.at(LoadFixtures.wednesday);
    final week = derive(
      LoadSources(
        groceries: [
          LoadFixtures.grocery(
            'g1',
            addedBy: sam,
            addedAt: wednesday,
            boughtBy: alex,
            boughtAt: wednesday,
          ),
          // Ticked a moment ago, not yet on the server: this week.
          LoadFixtures.grocery('g2', addedBy: alex, boughtBy: alex),
          LoadFixtures.grocery(
            'g3',
            addedBy: sam,
            addedAt: lastWeek,
            boughtBy: sam,
            boughtAt: lastWeek,
          ),
        ],
      ),
    );
    expect(of(week, alex).countOf(LoadKind.groceriesBought), 2);
    expect(of(week, sam).countOf(LoadKind.groceriesAdded), 1);
    expect(of(week, sam).countOf(LoadKind.groceriesBought), 0);
  });

  test('a carer’s shift counts for the parent who started or closed it, '
      'never for the carer', () {
    final wednesday = LoadFixtures.at(LoadFixtures.wednesday);
    final week = derive(
      LoadSources(
        openShifts: [
          Shift(
            id: 's1',
            carerMemberId: Fixtures.thandiMemberId,
            startedBy: sam,
            startedAt: wednesday,
          ),
          Shift(
            id: 's2',
            carerMemberId: Fixtures.thandiMemberId,
            startedBy: Fixtures.thandiMemberId,
            startedAt: wednesday,
          ),
        ],
        shiftSummaries: [
          ShiftSummary(
            id: 's0',
            carerMemberId: Fixtures.thandiMemberId,
            endedAt: wednesday,
            endedBy: alex,
          ),
        ],
      ),
    );
    expect(of(week, sam).countOf(LoadKind.careShifts), 1);
    expect(of(week, alex).countOf(LoadKind.careShifts), 1);
  });

  test('keeps at most three highlights, each once', () {
    final week = derive(
      LoadSources(
        events: [
          for (final id in ['a', 'b', 'c', 'd'])
            LoadFixtures.event(id, createdBy: sam),
        ],
      ),
    );
    expect(of(week, sam).highlights, hasLength(3));
    expect(of(week, sam).total, 4);
    expect(week.total, 4);
  });
}
