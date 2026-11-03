import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/premium_voucher_copy.dart';
import '../model/premium_voucher.dart';
import '../model/premium_voucher_kind.dart';
import '../model/voucher_claim_state.dart';

class PremiumVoucherCard extends StatelessWidget {
  const PremiumVoucherCard({
    required this.voucher,
    required this.state,
    required this.householdName,
    required this.onClaim,
    super.key,
  });

  final PremiumVoucher voucher;
  final VoucherClaimState state;
  final String? householdName;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final into = householdName;
    final state = this.state;
    final canClaim = switch (state) {
      VoucherAdded() => false,
      final VoucherRefused refused => !refused.endsVoucher,
      VoucherWaiting() || VoucherClaiming() => true,
    };
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              NestIconTile(
                icon: voucher.kind == PremiumVoucherKind.frame
                    ? LucideIcons.image
                    : LucideIcons.gift,
                tint: NestTileTint.butter,
              ),
              const SizedBox(width: NestSpace.lg),
              Expanded(
                child: Text(
                  PremiumVoucherCopy.voucherTitle(voucher),
                  style: nest.text.cardTitle,
                ),
              ),
              if (voucher.isTest) ...[
                const SizedBox(width: NestSpace.sm),
                const NestTag(
                  label: PremiumVoucherCopy.testOrder,
                  tone: NestTagTone.warning,
                ),
              ],
            ],
          ),
          const SizedBox(height: NestSpace.sm),
          Text(
            PremiumVoucherCopy.sentTo(voucher.emailMasked),
            style: nest.text.caption,
          ),
          if (state case VoucherAdded(:final claim, :final householdName)) ...[
            const SizedBox(height: NestSpace.md),
            NestBanner(
              message: claim.queued
                  ? PremiumVoucherCopy.addedQueued(householdName)
                  : PremiumVoucherCopy.added(householdName),
              tone: NestBannerTone.success,
            ),
          ],
          if (state case VoucherRefused(:final failure)) ...[
            const SizedBox(height: NestSpace.md),
            NestBanner(
              message: AppCopy.failure(failure),
              tone: NestBannerTone.danger,
            ),
          ],
          if (canClaim && into != null) ...[
            const SizedBox(height: NestSpace.lg),
            NestButton(
              key: ValueKey('claim-${voucher.voucherId}'),
              label: PremiumVoucherCopy.addTo(into),
              icon: LucideIcons.sparkles,
              isLoading: state is VoucherClaiming,
              onPressed: onClaim,
            ),
          ],
        ],
      ),
    );
  }
}
