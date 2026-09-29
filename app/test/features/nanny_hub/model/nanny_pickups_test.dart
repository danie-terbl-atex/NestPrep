import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/nanny_hub/model/nanny_pickups.dart';
import 'package:nestprep/features/nanny_hub/model/pickup_change.dart';
import 'package:nestprep/features/nanny_hub/model/pickup_collector.dart';
import 'package:nestprep/features/nanny_hub/model/pickup_person.dart';
import 'package:nestprep/features/nanny_hub/model/pickup_plan.dart';
import 'package:nestprep/features/nanny_hub/model/pickup_tidy.dart';
import 'package:nestprep/features/nanny_hub/model/school_run.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

/// Who collects a child on a day (nanny-hub ADR-0005): the day's change
/// wins, otherwise the weekday's run, otherwise nobody expects anyone.
void main() {
  // 2026-09-28 is a Monday; 2026-10-01 a Thursday.
  final monday = CalendarDate(2026, 9, 28);
  final thursday = CalendarDate(2026, 10, 1);

  SchoolRun run(int weekday, {String? personId, String? memberId}) => SchoolRun(
    id: SchoolRun.idFor('kid', weekday),
    childId: 'kid',
    weekday: weekday,
    personId: personId,
    memberId: memberId,
    atMinute: 870,
    place: 'Gate',
    updatedBy: 'sam',
  );

  PickupChange change(
    CalendarDate date, {
    String? personId,
    String? memberId,
  }) => PickupChange(
    id: PickupChange.idFor('kid', date),
    childId: 'kid',
    date: date,
    personId: personId,
    memberId: memberId,
    note: 'Gala',
    updatedBy: 'sam',
  );

  const gogo = PickupPerson(
    id: 'gogo',
    name: 'Gogo',
    relationship: 'Gran',
    childIds: ['kid'],
    createdBy: 'sam',
  );
  const aunt = PickupPerson(
    id: 'aunt',
    name: 'Aunt',
    relationship: 'Aunt',
    childIds: ['other'],
    createdBy: 'sam',
  );

  test('a run is found by the ISO weekday of the date: Monday is 1', () {
    final pickups = NannyPickups(
      people: [gogo],
      runs: [
        run(1, personId: 'gogo'),
        run(4, memberId: 'nomsa'),
      ],
      changes: [],
    );
    expect(
      pickups.planFor('kid', monday),
      const PickupPlan(
        collector: CollectedByPerson('gogo'),
        isChange: false,
        atMinute: 870,
        place: 'Gate',
      ),
    );
    expect(
      pickups.planFor('kid', thursday)?.collector,
      const CollectedByMember('nomsa'),
    );
  });

  test('a change for the date wins over the weekday, and says it is one', () {
    final pickups = NannyPickups(
      people: [gogo],
      runs: [run(1, personId: 'gogo')],
      changes: [change(monday, memberId: 'nomsa')],
    );
    final plan = pickups.planFor('kid', monday)!;
    expect(plan.collector, const CollectedByMember('nomsa'));
    expect(plan.isChange, isTrue);
    expect(plan.note, 'Gala');
    // The next Monday is the usual week again.
    expect(pickups.planFor('kid', monday.addDays(7))?.isChange, isFalse);
  });

  test('a change with no collector means nobody collects that day', () {
    final pickups = NannyPickups(
      people: [],
      runs: [run(1, personId: 'gogo')],
      changes: [change(monday)],
    );
    expect(pickups.planFor('kid', monday)?.collector, const NobodyCollects());
  });

  test('no run and no change is no school run, not somebody', () {
    final pickups = NannyPickups(
      people: [gogo],
      runs: [run(1, personId: 'gogo')],
      changes: [],
    );
    expect(pickups.planFor('kid', monday.addDays(1)), isNull);
    expect(pickups.planFor('another-child', monday), isNull);
  });

  test('only the people listed for a child may collect them', () {
    final pickups = NannyPickups(people: [gogo, aunt], runs: [], changes: []);
    expect(pickups.allowedFor('kid'), [gogo]);
    expect(pickups.allowedFor('nobody-listed'), isEmpty);
  });

  test('upcoming changes start today, soonest first, per child', () {
    final pickups = NannyPickups(
      people: [],
      runs: [],
      changes: [change(thursday), change(monday.addDays(-1)), change(monday)],
    );
    expect(
      [for (final c in pickups.upcomingFor('kid', monday)) c.date],
      [monday, thursday],
    );
  });

  test('a collector is a person before a member, and nobody without both', () {
    expect(
      PickupCollector.from(personId: 'p', memberId: 'm'),
      const CollectedByPerson('p'),
    );
    expect(PickupCollector.from(memberId: 'm'), const CollectedByMember('m'));
    expect(PickupCollector.from(), const NobodyCollects());
  });

  test('a person is tidied to the shape the rules accept', () {
    final tidy = tidyPerson((
      name: '  Gogo  ',
      relationship: ' Gran ',
      idNote: '   ',
      phone: ' 082 555 ',
      childIds: {for (var i = 0; i < 12; i++) 'c$i'},
    ));
    expect(tidy.name, 'Gogo');
    expect(tidy.relationship, 'Gran');
    expect(tidy.idNote, isNull);
    expect(tidy.phone, '082 555');
    expect(tidy.childIds, hasLength(10));
    expect(tidyText('x' * 300, 200), hasLength(200));
  });

  test(
    'a person with a number dials the digits only; without one, nothing',
    () {
      expect(
        gogo.copyWith(phone: '+27 (82) 555-0199').dialLink,
        Uri.parse('tel:+27825550199'),
      );
      expect(gogo.dialLink, isNull);
    },
  );
}
