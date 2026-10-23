import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../../../shared/ui/fact_list.dart';
import '../../../shared/ui/typed_confirm.dart';
import '../../account_data/ui/account_export_screen.dart';
import '../../account_data/ui/delete_account_screen.dart';
import '../model/household_view.dart';
import '../state/close_household_controller.dart';

/// Close household (household ADR-0007): the way out for a household's last
/// adult, who cannot leave because nobody would be left to run it.
///
/// Read first, then confirm — what goes, what stays, who loses access, the
/// store-billing warning, a copy of the person's data and the account
/// deletion that would close it too — and only then the typed word and the
/// one button. The household is already loaded by the shell, so the async
/// surface is the close itself: busy, refused in words, done (`FE-08`).
class CloseHouseholdScreen extends StatelessWidget {
  const CloseHouseholdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final view = context.watch<HouseholdView>();
    final controller = context.watch<CloseHouseholdController>();
    final nest = NestTheme.of(context);
    final others = view.othersInHousehold;
    return NestScaffold(
      title: CloseHouseholdCopy.title,
      leading: backLeading(context),
      body: ListView(
        padding: const EdgeInsets.only(bottom: NestSpace.huge),
        children: [
          Text(
            CloseHouseholdCopy.lead(view.household.name),
            style: nest.text.body,
          ),
          if (others > 0) ...[
            const SizedBox(height: NestSpace.lg),
            NestBanner(
              message: CloseHouseholdCopy.othersLoseAccess(others),
              tone: NestBannerTone.warning,
            ),
          ],
          const SizedBox(height: NestSpace.xl),
          const NestCard(
            variant: NestCardVariant.tinted,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FactList(
                  title: CloseHouseholdCopy.goesTitle,
                  facts: CloseHouseholdCopy.goes,
                  icon: LucideIcons.circleMinus,
                ),
                SizedBox(height: NestSpace.md),
                FactList(
                  title: CloseHouseholdCopy.staysTitle,
                  facts: CloseHouseholdCopy.stays,
                ),
              ],
            ),
          ),
          const SizedBox(height: NestSpace.lg),
          const NestBanner(message: CloseHouseholdCopy.premiumNote),
          const SizedBox(height: NestSpace.lg),
          NestButton(
            label: CloseHouseholdCopy.downloadFirst,
            variant: NestButtonVariant.outline,
            icon: LucideIcons.download,
            onPressed: () => context.push(AccountExportScreen.path),
          ),
          const SizedBox(height: NestSpace.xl),
          Text(CloseHouseholdCopy.deleteAccountInstead, style: nest.text.body),
          const SizedBox(height: NestSpace.sm),
          NestButton(
            label: CloseHouseholdCopy.deleteAccountButton,
            variant: NestButtonVariant.outline,
            icon: LucideIcons.userX,
            onPressed: () => context.push(DeleteAccountScreen.path),
          ),
          const SizedBox(height: NestSpace.xxl),
          TypedConfirm(
            label: CloseHouseholdCopy.confirmLabel,
            hint: CloseHouseholdCopy.confirmHint,
            buttonLabel: CloseHouseholdCopy.closeButton,
            busyLabel: CloseHouseholdCopy.closing,
            icon: LucideIcons.doorClosed,
            canConfirm: controller.canClose,
            isBusy: controller.isClosing || controller.isClosed,
            failure: controller.failure,
            onTyped: controller.typeConfirmation,
            onConfirm: controller.close,
          ),
        ],
      ),
    );
  }
}
