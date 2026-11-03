import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/premium_voucher_copy.dart';
import '../../accounts/model/session.dart';
import '../../accounts/state/session_controller.dart';
import '../../household/data/household_repository.dart';
import '../../household/model/household.dart';
import '../../household/model/household_view.dart';
import '../data/premium_voucher_directory.dart';
import '../model/voucher_claim_state.dart';
import '../state/premium_claim_controller.dart';
import '../state/premium_voucher_inbox.dart';
import '../state/voucher_email_controller.dart';
import 'premium_voucher_card.dart';
import 'voucher_email_flow.dart';

Future<void> showPremiumVoucherSheet(
  BuildContext context, {
  bool startWithEmail = false,
}) {
  final view = context.read<HouseholdView>();
  final directory = context.read<PremiumVoucherDirectory>();
  final inbox = context.read<PremiumVoucherInbox>()..markOffered();
  final households = context.read<HouseholdRepository>();
  final householdIds = switch (context.read<SessionController>().session) {
    AsyncData(value: final SignedIn signedIn) => signedIn.account.householdIds,
    _ => [view.household.id],
  };
  return showNestSheet<void>(
    context: context,
    builder: (_) => MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PremiumClaimController(
            directory: directory,
            inbox: inbox,
            householdRepository: households,
            uid: view.viewerUid,
            current: view.household,
            householdIds: householdIds,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              VoucherEmailController(directory: directory, inbox: inbox),
        ),
      ],
      child: PremiumVoucherSheetBody(startWithEmail: startWithEmail),
    ),
  );
}

class PremiumVoucherSheetBody extends StatefulWidget {
  const PremiumVoucherSheetBody({required this.startWithEmail, super.key});

  final bool startWithEmail;

  @override
  State<PremiumVoucherSheetBody> createState() =>
      _PremiumVoucherSheetBodyState();
}

class _PremiumVoucherSheetBodyState extends State<PremiumVoucherSheetBody> {
  late bool _wantsEmail = widget.startWithEmail;

  void _openEmail(VoucherEmailController email) {
    if (email.step == VoucherEmailStep.confirmed) email.useAnotherEmail();
    setState(() => _wantsEmail = true);
  }

  @override
  Widget build(BuildContext context) {
    final claim = context.watch<PremiumClaimController>();
    final email = context.watch<VoucherEmailController>();
    final confirmedWithPremium =
        email.step == VoucherEmailStep.confirmed &&
        !email.isLookingForPremium &&
        claim.vouchers.isNotEmpty;
    final onEmail = _wantsEmail && !confirmedWithPremium;
    final anyAdded = claim.vouchers.any(
      (voucher) => claim.stateOf(voucher) is VoucherAdded,
    );
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onEmail)
            const VoucherEmailFlow()
          else
            _VoucherList(
              claim: claim,
              confirmedEmail: confirmedWithPremium ? email.emailMasked : null,
            ),
          const SizedBox(height: NestSpace.xl),
          if (!onEmail && !claim.isFinished) ...[
            NestButton(
              key: const ValueKey('voucher-different-email'),
              label: PremiumVoucherCopy.differentEmail,
              variant: NestButtonVariant.link,
              onPressed: () => _openEmail(email),
            ),
            const SizedBox(height: NestSpace.sm),
          ],
          NestButton(
            key: const ValueKey('voucher-sheet-close'),
            label: anyAdded || email.step == VoucherEmailStep.confirmed
                ? PremiumVoucherCopy.done
                : PremiumVoucherCopy.notNow,
            variant: anyAdded
                ? NestButtonVariant.primary
                : NestButtonVariant.ghost,
            onPressed: claim.isClaiming
                ? null
                : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _VoucherList extends StatelessWidget {
  const _VoucherList({required this.claim, required this.confirmedEmail});

  final PremiumClaimController claim;
  final String? confirmedEmail;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final confirmed = confirmedEmail;
    final households = claim.households;
    final selected = claim.selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(PremiumVoucherCopy.sheetTitle, style: nest.text.title),
        if (confirmed != null) ...[
          const SizedBox(height: NestSpace.md),
          NestBanner(
            message: PremiumVoucherCopy.confirmed(confirmed),
            tone: NestBannerTone.success,
          ),
        ],
        const SizedBox(height: NestSpace.md),
        switch (households) {
          AsyncLoading() => Text(
            PremiumVoucherCopy.loadingHouseholds,
            style: nest.text.bodySecondary,
          ),
          AsyncData(:final value) when value.length > 1 => _HouseholdChoice(
            households: value,
            selectedId: selected?.id,
            onSelect: claim.isClaiming ? null : claim.select,
          ),
          AsyncData(:final value) when value.length == 1 => Text(
            PremiumVoucherCopy.intoOnly(value.single.name),
            style: nest.text.body,
          ),
          _ => const NestBanner(
            message: PremiumVoucherCopy.noFamilyHousehold,
            tone: NestBannerTone.warning,
          ),
        },
        for (final voucher in claim.vouchers) ...[
          const SizedBox(height: NestSpace.lg),
          PremiumVoucherCard(
            key: ValueKey(voucher.voucherId),
            voucher: voucher,
            state: claim.stateOf(voucher),
            householdName: selected?.name,
            onClaim: claim.isClaiming ? null : () => claim.claim(voucher),
          ),
        ],
        if (claim.vouchers.isEmpty || claim.isFinished) ...[
          const SizedBox(height: NestSpace.lg),
          Text(PremiumVoucherCopy.nothingLeft, style: nest.text.bodySecondary),
        ],
      ],
    );
  }
}

class _HouseholdChoice extends StatelessWidget {
  const _HouseholdChoice({
    required this.households,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Household> households;
  final String? selectedId;
  final ValueChanged<String>? onSelect;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final select = onSelect;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(PremiumVoucherCopy.chooseHousehold, style: nest.text.bodyStrong),
        const SizedBox(height: NestSpace.xs),
        Text(
          PremiumVoucherCopy.chooseHouseholdBody,
          style: nest.text.bodySecondary,
        ),
        const SizedBox(height: NestSpace.md),
        for (final household in households)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.xs),
            child: NestListRow(
              key: ValueKey('voucher-household-${household.id}'),
              leading: const Icon(LucideIcons.house),
              title: household.name,
              isSelected: household.id == selectedId,
              trailing: household.id == selectedId
                  ? const Icon(LucideIcons.check)
                  : null,
              onTap: select == null ? null : () => select(household.id),
            ),
          ),
      ],
    );
  }
}
