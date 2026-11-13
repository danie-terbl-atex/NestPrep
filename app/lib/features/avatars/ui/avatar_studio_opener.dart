import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/avatar_routes.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../household/model/household_view.dart';
import 'avatar_studio_tab.dart';

VoidCallback? avatarStudioOpener(
  BuildContext context,
  String memberId, {
  AvatarStudioTab? tab,
}) {
  final view = context.read<HouseholdView?>();
  if (view == null ||
      !AvatarRoute.isOn(context.read<FeatureFlagsController?>()) ||
      !AvatarRoute.canOpen(view, memberId)) {
    return null;
  }
  return () =>
      context.push(AvatarRoute.pathFor(view.household.id, memberId, tab: tab));
}
