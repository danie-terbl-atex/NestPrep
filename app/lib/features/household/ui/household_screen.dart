import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../../../shared/ui/back_leading.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../model/household_view.dart';
import '../state/household_controller.dart';
import 'household_body.dart';
import 'member_sheet.dart';

/// The household: who is in it, who has joined, and the admin actions. All four
/// async states come from the kit (`FE-08`).
class HouseholdScreen extends StatelessWidget {
  const HouseholdScreen({super.key});

  static const routeName = 'household';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HouseholdController>();
    final failure = controller.actionFailure;
    return NestScaffold(
      title: AppCopy.householdTitle,
      // This screen is pushed from a tab, so it carries the way back itself
      // rather than relying on the system gesture alone (`FE-17`). A deep link
      // straight here has nothing to pop, and then there is no button.
      leading: backLeading(context),
      trailing: const [AccountMenuButton()],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.lg),
              child: NestBanner(
                message: AppCopy.failure(failure),
                tone: NestBannerTone.danger,
                actionLabel: AppCopy.back,
                onAction: controller.dismissActionFailure,
              ),
            ),
          Expanded(
            child: NestAsyncView<HouseholdView>(
              state: controller.view,
              isEmpty: (view) => view.members.isEmpty,
              onRetry: controller.retry,
              emptyBuilder: (_) => NestEmptyView(
                title: AppCopy.householdEmptyTitle,
                message: AppCopy.householdEmptyBody,
                icon: LucideIcons.users,
                actionLabel: AppCopy.householdAddMember,
                onAction: () => addMember(context, controller),
              ),
              dataBuilder: (_, view) =>
                  HouseholdBody(view: view, controller: controller),
            ),
          ),
        ],
      ),
    );
  }

  /// Adds a profile — from the empty state here, and from the body's header.
  static Future<void> addMember(
    BuildContext context,
    HouseholdController controller,
  ) async {
    final result = await showMemberSheet(
      context: context,
      today: context.read<HouseholdClock>().today,
    );
    if (result == null) return;
    await controller.addMember(
      displayName: result.displayName,
      color: result.color,
      role: result.role,
      birthday: result.birthday,
      guardianConsent: result.guardianConsent,
    );
  }
}
