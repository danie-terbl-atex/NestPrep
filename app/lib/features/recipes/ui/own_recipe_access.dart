import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../accounts/state/session_controller.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';

@immutable
final class OwnRecipeAccess {
  const OwnRecipeAccess({required this.canDelete, required this.isSwitchedOn});

  // A kid device can pass `canEdit`, but `requireUid` refuses every kid.
  factory OwnRecipeAccess.of(BuildContext context) {
    final permissions = context.watch<HouseholdView>().permissions;
    final isKidDevice =
        context.watch<SessionController?>()?.kidIdentity != null;
    final flags = context.watch<FeatureFlagsController?>();
    return OwnRecipeAccess(
      canDelete: !isKidDevice && permissions.canEdit(HouseholdArea.meals),
      isSwitchedOn: flags?.isOn(FeatureFlag.householdRecipes) ?? false,
    );
  }

  factory OwnRecipeAccess.now(BuildContext context) {
    final permissions = context.read<HouseholdView>().permissions;
    final isKidDevice = context.read<SessionController?>()?.kidIdentity != null;
    final flags = context.read<FeatureFlagsController?>();
    return OwnRecipeAccess(
      canDelete: !isKidDevice && permissions.canEdit(HouseholdArea.meals),
      isSwitchedOn: flags?.isOn(FeatureFlag.householdRecipes) ?? false,
    );
  }

  final bool canDelete;
  final bool isSwitchedOn;

  bool get canAddOrEdit => canDelete && isSwitchedOn;
}
