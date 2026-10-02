import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../account_data/ui/account_centre_screen.dart';
import '../../household/ui/switch_household_sheet.dart';
import '../../product_analytics/ui/beta_numbers_link.dart';
import '../model/session.dart';
import '../state/session_controller.dart';

/// The way out of the app, in the one place every screen has a header
/// (accounts phase 1). It is an icon button rather than a menu item so that
/// signing out is never two taps deep on a shared phone.
class AccountMenuButton extends StatelessWidget {
  const AccountMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SessionController>();
    return NestIconButton(
      icon: LucideIcons.user,
      label: AppCopy.account,
      onPressed: () => _openSheet(context, controller),
    );
  }

  Future<void> _openSheet(
    BuildContext context,
    SessionController controller,
  ) async {
    final session = controller.session;
    final signedIn = session is AsyncData<Session> && session.value is SignedIn
        ? session.value as SignedIn
        : null;
    if (signedIn == null) return;
    await showNestSheet<void>(
      context: context,
      title: AppCopy.account,
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NestListRow(
            leading: NestAvatar(
              name: signedIn.account.displayName,
              color: MemberColor.violet,
            ),
            title: signedIn.account.displayName,
            subtitle: signedIn.user.email,
          ),
          if (signedIn.account.householdIds.length > 1) ...[
            const SizedBox(height: NestSpace.lg),
            NestButton(
              label: AppCopy.householdSwitch,
              variant: NestButtonVariant.outline,
              icon: LucideIcons.arrowLeftRight,
              onPressed: () async {
                final chosen = await showSwitchHouseholdSheet(
                  context: sheetContext,
                  householdIds: signedIn.account.householdIds,
                  activeHouseholdId: signedIn.account.activeHouseholdId,
                );
                if (chosen == null || !sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                await controller.switchHousehold(chosen);
              },
            ),
          ],
          const SizedBox(height: NestSpace.lg),
          // Download, delete and the legal pages (accounts ADR-0006).
          NestButton(
            label: AccountDataCopy.centreEntry,
            variant: NestButtonVariant.outline,
            icon: LucideIcons.shield,
            onPressed: () {
              // Taken before the sheet closes, while this context still has
              // a router above it — the same as the Beta numbers link.
              final router = GoRouter.of(context);
              Navigator.of(sheetContext).pop();
              router.push<void>(AccountCentreScreen.path);
            },
          ),
          // Offered only to a holder of the reader claim (product-analytics
          // ADR-0001); for everybody else it takes no space.
          BetaNumbersLink(onOpen: () => Navigator.of(sheetContext).pop()),
          const SizedBox(height: NestSpace.xl),
          NestButton(
            label: AppCopy.signOut,
            variant: NestButtonVariant.danger,
            icon: LucideIcons.logOut,
            onPressed: () async {
              Navigator.of(sheetContext).pop();
              await controller.signOut();
            },
          ),
        ],
      ),
    );
  }
}
