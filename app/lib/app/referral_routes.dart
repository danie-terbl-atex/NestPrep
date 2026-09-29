import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/household/data/invite_sharer.dart';
import '../features/referrals/data/referral_directory.dart';
import '../features/referrals/data/referral_repository.dart';
import '../features/referrals/state/referral_controller.dart';
import '../features/referrals/ui/referral_screen.dart';
import 'household_route.dart';
import 'referral_route.dart';

/// Referrals' route under the household shell (subscriptions ADR-0002), in
/// its own file so the route table gains one line.
GoRoute referralRoute() => GoRoute(
  path: ReferralRoute.path,
  builder: (context, state) => ChangeNotifierProvider(
    create: (context) => ReferralController(
      referralRepository: context.read<ReferralRepository>(),
      referralDirectory: context.read<ReferralDirectory>(),
      inviteSharer: context.read<InviteSharer>(),
      householdId: HouseholdRoute.idFrom(state),
    ),
    child: const ReferralScreen(),
  ),
);
