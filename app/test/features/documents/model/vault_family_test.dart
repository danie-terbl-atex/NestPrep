import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/documents/model/vault_family.dart';
import 'package:nestprep/features/household/model/member_role.dart';

/// Who is family for the vaults (documents ADR-0002, household ADR-0003):
/// family reads and manages every vault; anybody else reads only their own and
/// what is shared with them.
void main() {
  test('an admin and a member — read as a parent — are family', () {
    expect(isVaultFamily(MemberRole.admin), isTrue);
    expect(isVaultFamily(MemberRole.member), isTrue);
  });

  test('a helper is not, and neither is somebody with no role here', () {
    expect(isVaultFamily(MemberRole.helper), isFalse);
    expect(isVaultFamily(null), isFalse);
  });
}
