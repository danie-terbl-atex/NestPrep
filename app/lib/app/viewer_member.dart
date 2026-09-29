import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../features/household/model/household_view.dart';

/// The profile the signed-in account claimed here. Everything a member creates
/// is stamped with it, and the rules check it against `claimedBy` (household
/// ADR-0001). Empty for an account that has claimed none, which the rules
/// refuse any stamped write from.
String viewerMemberIdOf(BuildContext context) =>
    context.read<HouseholdView>().viewerMember?.id ?? '';
