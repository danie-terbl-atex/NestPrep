import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/nanny_hub/model/house_code.dart';
import 'package:nestprep/features/nanny_hub/model/photo_update.dart';
import 'package:nestprep/features/nanny_hub/model/shift_booking.dart';

import 'model_fixtures.dart';
import 'nanny_fixtures.dart';

/// Photo updates, booked shifts and house codes (nanny-hub ADR-0004,
/// ADR-0006) for tests, and their stored models for the round-trip ratchet.
abstract final class AccessFixtures {
  /// A booking for Nomsa, the fixtures' carer, around [now]: [from] after it
  /// and lasting [length].
  static ShiftBooking booking({
    required DateTime now,
    Duration from = Duration.zero,
    Duration length = const Duration(hours: 4),
    String id = 'b1',
    String carerMemberId = 'm-nomsa',
    String? note,
  }) => ShiftBooking(
    id: id,
    carerMemberId: carerMemberId,
    startsAt: now.toUtc().add(from),
    endsAt: now.toUtc().add(from).add(length),
    note: note,
    createdBy: 'm-sam',
  );

  /// Nomsa, kept to the shifts a parent books for her (nanny-hub ADR-0006).
  static HouseholdView shiftOnlyCarerView() {
    final view = NannyFixtures.carerView();
    return HouseholdView(
      household: view.household.copyWith(
        shiftOnly: const {NannyFixtures.nomsaMemberId: true},
      ),
      members: view.members,
      viewerUid: view.viewerUid,
    );
  }

  static const alarm = HouseCode(
    id: 'code-alarm',
    label: 'Alarm',
    value: '4821',
    note: 'Panel behind the front door',
    createdBy: 'm-sam',
  );

  static const gate = HouseCode(
    id: 'code-gate',
    label: 'Gate',
    value: '1990#',
    createdBy: 'm-sam',
  );
}

List<ModelFixture> accessModelFixtures() {
  final at = fixtureInstant;
  final update = PhotoUpdate(
    id: 'u1',
    photoId: 'photo-fort-01',
    caption: 'Building a fort',
    childIds: const ['m-kid'],
    byMemberId: 'm-nomsa',
    createdAt: at,
  );
  final booking = ShiftBooking(
    id: 'b1',
    carerMemberId: 'm-nomsa',
    startsAt: at,
    endsAt: at.add(const Duration(hours: 4)),
    note: 'School pick-up first',
    createdBy: 'm-sam',
    createdAt: at,
  );
  final code = AccessFixtures.alarm.copyWith(createdAt: at);
  return [
    ModelFixture(
      label: 'PhotoUpdate',
      id: update.id,
      value: update,
      toJson: update.toJson,
      fromJson: PhotoUpdate.fromJson,
      keys: const {'photoId', 'caption', 'childIds', 'byMemberId', 'createdAt'},
    ),
    ModelFixture(
      label: 'ShiftBooking',
      id: booking.id,
      value: booking,
      toJson: booking.toJson,
      fromJson: ShiftBooking.fromJson,
      keys: const {
        'carerMemberId',
        'startsAt',
        'endsAt',
        'note',
        'createdBy',
        'createdAt',
      },
    ),
    ModelFixture(
      label: 'HouseCode',
      id: code.id,
      value: code,
      toJson: code.toJson,
      fromJson: HouseCode.fromJson,
      keys: const {'label', 'value', 'note', 'createdBy', 'createdAt'},
    ),
  ];
}
