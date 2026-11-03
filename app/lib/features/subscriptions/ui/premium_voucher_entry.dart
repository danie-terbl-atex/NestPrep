import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/premium_voucher_copy.dart';
import '../state/premium_voucher_inbox.dart';
import 'premium_voucher_sheet.dart';

class PremiumVoucherEntry extends StatelessWidget {
  const PremiumVoucherEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final waiting = context.watch<PremiumVoucherInbox>().waiting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (waiting.isNotEmpty) ...[
          NestCard(
            variant: NestCardVariant.tinted,
            padding: EdgeInsets.zero,
            child: NestListRow(
              key: const ValueKey('plan-premium-waiting'),
              leading: const NestIconTile(
                icon: LucideIcons.gift,
                tint: NestTileTint.butter,
              ),
              title: PremiumVoucherCopy.sheetTitle,
              subtitle: PremiumVoucherCopy.waitingEntry(waiting),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => unawaited(showPremiumVoucherSheet(context)),
            ),
          ),
          const SizedBox(height: NestSpace.sm),
        ],
        NestButton(
          key: const ValueKey('plan-different-email'),
          label: PremiumVoucherCopy.differentEmail,
          variant: NestButtonVariant.link,
          icon: LucideIcons.mail,
          onPressed: () =>
              unawaited(showPremiumVoucherSheet(context, startWithEmail: true)),
        ),
      ],
    );
  }
}
