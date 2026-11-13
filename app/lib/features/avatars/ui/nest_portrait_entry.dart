import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/avatar_routes.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/subscription_copy.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../household/model/household_view.dart';
import '../../subscriptions/state/household_entitlement.dart';
import '../model/avatar_creation.dart';
import 'avatar_studio_tab.dart';
import 'creation_card.dart';

class NestPortraitEntry extends StatelessWidget {
  const NestPortraitEntry({super.key});

  static bool isOffered(BuildContext context) {
    final view = context.watch<HouseholdView?>();
    return view != null &&
        view.permissions.isFamily &&
        view.viewerMember != null &&
        view.household.avatarCreationsOn &&
        AvatarRoute.creationsOn(context.watch<FeatureFlagsController?>());
  }

  @override
  Widget build(BuildContext context) {
    if (!isOffered(context)) return const SizedBox.shrink();
    final view = context.read<HouseholdView>();
    final entitlement = context.watch<HouseholdEntitlement?>();
    final needsPremium =
        (entitlement?.isKnown ?? false) && !(entitlement?.isPremium ?? false);
    return Padding(
      padding: const EdgeInsets.only(bottom: NestSpace.lg),
      child: CreationCard(
        key: const ValueKey('nest-portrait-entry'),
        recipe: CreationRecipe.portrait,
        tag: needsPremium ? SubscriptionCopy.premium : null,
        onTap: () => context.push(
          AvatarRoute.pathFor(
            view.household.id,
            view.viewerMember!.id,
            tab: AvatarStudioTab.create,
          ),
        ),
      ),
    );
  }
}
