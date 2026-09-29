import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/kid_accounts/model/kid_device.dart';
import 'package:nestprep/features/kid_accounts/model/kid_sign_in_entry.dart';

import '../../../support/household_fixtures.dart';

/// Whom the parent's kid sign-in screen offers (accounts ADR-0004): an
/// unclaimed kid, and — so its devices can still be signed out — any profile
/// that has devices but is no longer eligible.
void main() {
  KidDevice deviceOf(String memberId) => KidDevice(
    id: 'kid_$memberId',
    memberId: memberId,
    label: 'Tablet',
    pairedBy: Fixtures.samUid,
    pairedAt: DateTime.utc(2026, 9, 28, 9),
  );

  test('an unclaimed kid is offered, and may add a device', () {
    final entries = KidSignInEntry.from(
      members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
      devices: const [],
    );
    expect(entries.single.member.id, Fixtures.kidMemberId);
    expect(entries.single.canAddDevice, isTrue);
  });

  test('an old `member` profile is an adult, and is not offered', () {
    final grownUp = Fixtures.kid.copyWith(roleName: 'member');
    expect(KidSignInEntry.from(members: [grownUp], devices: const []), isEmpty);
  });

  test('a profile moved off `kid` keeps its devices on the list to sign out, '
      'and offers no new one', () {
    final moved = Fixtures.kid.copyWith(roleName: 'parent');
    final entries = KidSignInEntry.from(
      members: [moved],
      devices: [deviceOf(Fixtures.kidMemberId)],
    );
    expect(entries.single.devices, hasLength(1));
    expect(entries.single.canAddDevice, isFalse);
  });
}
