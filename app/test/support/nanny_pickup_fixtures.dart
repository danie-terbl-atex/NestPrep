import 'package:nestprep/features/nanny_hub/model/contact_kind.dart';
import 'package:nestprep/features/nanny_hub/model/emergency_contact.dart';
import 'package:nestprep/features/nanny_hub/model/pickup_change.dart';
import 'package:nestprep/features/nanny_hub/model/pickup_person.dart';
import 'package:nestprep/features/nanny_hub/model/school_run.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/time/household_clock.dart';

import 'household_fixtures.dart';
import 'model_fixtures.dart';
import 'nanny_fixtures.dart';

/// Who may collect Kid, and their school-run week (nanny-hub ADR-0005): Gogo
/// with a photo and an ID note, Uncle Thabo with neither, and Mom on the
/// emergency sheet as the parent to call.
abstract final class PickupFixtures {
  /// The household's today, as the screens under test read it.
  static CalendarDate get today =>
      HouseholdClock(Fixtures.household().timeZone).today;

  static PickupPerson get gogo => const PickupPerson(
    id: 'p-gogo',
    name: 'Gogo Dlamini',
    relationship: 'Gogo',
    idNote: 'Shows her ID; drives a white Polo',
    phone: '082 555 0199',
    photoId: 'photo-gogo-01',
    childIds: [Fixtures.kidMemberId],
    createdBy: Fixtures.samMemberId,
  );

  static PickupPerson get thabo => const PickupPerson(
    id: 'p-thabo',
    name: 'Thabo Mokoena',
    relationship: 'Uncle',
    childIds: [Fixtures.kidMemberId],
    createdBy: Fixtures.samMemberId,
  );

  /// Gogo collects Kid every weekday of today's, at 14:30, from the gate.
  static SchoolRun get todaysRun => SchoolRun(
    id: SchoolRun.idFor(Fixtures.kidMemberId, today.weekday),
    childId: Fixtures.kidMemberId,
    weekday: today.weekday,
    personId: gogo.id,
    atMinute: 870,
    place: 'Oakwood, side gate',
    updatedBy: Fixtures.samMemberId,
  );

  /// Nomsa, the carer, collects Kid today instead.
  static PickupChange get nomsaToday => PickupChange(
    id: PickupChange.idFor(Fixtures.kidMemberId, today),
    childId: Fixtures.kidMemberId,
    date: today,
    memberId: NannyFixtures.nomsaMemberId,
    atMinute: 900,
    note: 'Swimming gala',
    updatedBy: Fixtures.samMemberId,
  );

  static EmergencyContact get mom => const EmergencyContact(
    id: 'c-mom',
    name: 'Mom',
    kind: ContactKind.parent,
    phone: '+27 82 555 0100',
    createdBy: Fixtures.samMemberId,
  );
}

/// The three stored pickup models, every field filled, spread by
/// `nannyModelFixtures()` so the round-trip test covers them.
List<ModelFixture> pickupModelFixtures() {
  final at = fixtureInstant;
  final person = PickupFixtures.gogo.copyWith(createdAt: at);
  final run = SchoolRun(
    id: 'm-kid_2',
    childId: 'm-kid',
    weekday: 2,
    personId: 'p-gogo',
    atMinute: 870,
    place: 'Side gate',
    updatedBy: 'm-sam',
    updatedAt: at,
  );
  final change = PickupChange(
    id: 'm-kid_2026-09-30',
    childId: 'm-kid',
    date: CalendarDate(2026, 9, 30),
    memberId: 'm-nomsa',
    atMinute: 900,
    note: 'Gala',
    updatedBy: 'm-sam',
    updatedAt: at,
  );
  return [
    ModelFixture(
      label: 'PickupPerson',
      id: person.id,
      value: person,
      toJson: person.toJson,
      fromJson: PickupPerson.fromJson,
      keys: const {
        'name',
        'relationship',
        'idNote',
        'phone',
        'photoId',
        'childIds',
        'createdBy',
        'createdAt',
      },
    ),
    ModelFixture(
      label: 'SchoolRun',
      id: run.id,
      value: run,
      toJson: run.toJson,
      fromJson: SchoolRun.fromJson,
      keys: const {
        'childId',
        'weekday',
        'personId',
        'memberId',
        'atMinute',
        'place',
        'updatedBy',
        'updatedAt',
      },
    ),
    ModelFixture(
      label: 'PickupChange',
      id: change.id,
      value: change,
      toJson: change.toJson,
      fromJson: PickupChange.fromJson,
      note: 'the date is a YYYY-MM-DD string, never a timestamp (ENG-21)',
      keys: const {
        'childId',
        'date',
        'personId',
        'memberId',
        'atMinute',
        'note',
        'updatedBy',
        'updatedAt',
      },
    ),
  ];
}
