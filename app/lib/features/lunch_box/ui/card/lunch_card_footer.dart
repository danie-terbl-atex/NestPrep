import 'package:flutter/material.dart';

import '../../../../design/nest_kit.dart';
import '../../../../shared/copy/app_copy.dart';
import 'lunch_card_layout.dart';

/// The card's sign-off (lunch-box ADR-0005): "Planned with Nest Prep" and,
/// when the parent leaves it on, the invite line with where to get the app.
///
/// On the tall formats the logo is already at the top, so this is one quiet
/// line. On the square the wordmark signs here — the logo's own drawing,
/// never retyped.
class LunchCardFooter extends StatelessWidget {
  const LunchCardFooter({
    required this.layout,
    required this.showsInvite,
    required this.inviteHost,
    super.key,
  });

  final LunchCardLayout layout;
  final bool showsInvite;

  /// The configured invite link's host; null says the app's name instead.
  final String? inviteHost;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final signature = layout.isStacked
        ? Text(
            LunchShareCopy.plannedWithNestPrep,
            maxLines: 1,
            style: nest.text.caption,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(LunchShareCopy.plannedWith, style: nest.text.caption),
              const SizedBox(width: NestSpace.sm),
              const NestWordmark(
                semanticsLabel: LunchShareCopy.plannedWithNestPrep,
                size: NestSize.wordmarkSignature,
              ),
            ],
          );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: signature,
          ),
        ),
        const SizedBox(width: NestSpace.lg),
        if (showsInvite)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  LunchShareCopy.planYours,
                  maxLines: 1,
                  style: nest.text.label.copyWith(color: nest.colors.accentInk),
                ),
                Text(
                  inviteHost ?? LunchShareCopy.findTheApp,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: nest.text.caption,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
