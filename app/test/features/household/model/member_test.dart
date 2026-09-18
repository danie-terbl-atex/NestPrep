import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/tokens/nest_member_palette.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/features/household/model/member_role.dart';

/// A member profile: what it is called, who has claimed it, and what it may do.
///
/// `initials` is the one that earns a test. Colour is never the only signal
/// saying who something is for (`FE-13`), so the letters on an avatar are the
/// signal — and they are computed from a name somebody typed, which means every
/// shape of name has to produce something.
void main() {
  Member named(
    String displayName, {
    String? claimedBy,
    String role = 'member',
  }) => Member(
    id: 'm1',
    displayName: displayName,
    color: MemberColor.violet,
    roleName: role,
    claimedBy: claimedBy,
  );

  group('the letters on the avatar', () {
    for (final (name, expected) in [
      ('Sam Parent', 'SP'),
      ('Sam', 'S'),
      ('Sam van der Merwe', 'SM'),
      ('  Thandi   Helper  ', 'TH'),
      ('sam parent', 'SP'),
    ]) {
      test('"$name" reads as $expected', () {
        expect(named(name).initials, expected);
      });
    }

    test('a name that is only spaces still says something', () {
      expect(
        named('   ').initials,
        '?',
        reason: 'an avatar with nothing on it is a person nobody can identify',
      );
    });

    test('and a name that is one emoji keeps it', () {
      expect(named('🐢').initials, isNotEmpty);
    });
  });

  group('who has claimed it', () {
    test('an unclaimed profile belongs to nobody', () {
      final member = named('Kid Parker');
      expect(member.isClaimed, isFalse);
      expect(member.isClaimedBy('uid-sam'), isFalse);
    });

    test('a claimed one belongs to exactly one account', () {
      final member = named('Sam Parent', claimedBy: 'uid-sam');
      expect(member.isClaimed, isTrue);
      expect(member.isClaimedBy('uid-sam'), isTrue);
      expect(
        member.isClaimedBy('uid-thandi'),
        isFalse,
        reason: 'two accounts must never both be the same person',
      );
    });
  });

  group('the role', () {
    for (final role in MemberRole.values) {
      test('${role.name} survives the round trip', () {
        expect(named('Sam', role: role.name).role, role);
      });
    }

    test('a role from a newer build does not crash an older one', () {
      // Roles are stored as strings; a document written by a build that knows
      // something this one does not must still render.
      expect(() => named('Sam', role: 'overlord').role, returnsNormally);
    });
  });
}
