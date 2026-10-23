import '../../household/model/household_view.dart';
import '../../household/model/member_role.dart';

/// How many people a family meal is cooked for when nobody has said: the
/// household's family and children (recipes ADR-0003 §5). A helper or a carer
/// is a member too, but is not who the dinner is counted for.
int familySizeOf(HouseholdView view) => view.members
    .where((member) => member.role.isFamily || member.role == MemberRole.kid)
    .length;
