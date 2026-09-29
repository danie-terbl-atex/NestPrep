import '../../../shared/copy/app_copy.dart';
import '../../household/model/member.dart';
import '../model/nanny_pickups.dart';
import '../model/pickup_collector.dart';
import '../model/pickup_person.dart';

/// How a collector reads on a screen: a name, what they are to the family,
/// and — for a listed person — their record, which carries the photo. A
/// person or member deleted since the run was set reads as the plain words
/// "Not set" rather than a blank.
typedef CollectorLook = ({
  String name,
  String? detail,
  PickupPerson? person,
  Member? member,
});

CollectorLook lookOfCollector(
  PickupCollector collector, {
  required NannyPickups pickups,
  required Member? Function(String memberId) memberById,
}) => switch (collector) {
  CollectedByPerson(:final id) => switch (pickups.personById(id)) {
    final person? => (
      name: person.name,
      detail: person.relationship,
      person: person,
      member: null,
    ),
    null => _unknown,
  },
  CollectedByMember(:final id) => switch (memberById(id)) {
    final member? => (
      name: member.displayName,
      detail: NannyPickupCopy.household,
      person: null,
      member: member,
    ),
    null => _unknown,
  },
  NobodyCollects() => (
    name: NannyPickupCopy.nobodyToday,
    detail: null,
    person: null,
    member: null,
  ),
};

const CollectorLook _unknown = (
  name: NannyPickupCopy.notSet,
  detail: null,
  person: null,
  member: null,
);
