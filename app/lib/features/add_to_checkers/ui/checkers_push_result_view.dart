import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/checkers_copy.dart';
import '../model/checkers_push_result.dart';

/// What went into the member's Checkers cart and what did not, in words a
/// person can act on, then the cart's count and total and where to finish.
class CheckersPushResultView extends StatelessWidget {
  const CheckersPushResultView({
    required this.result,
    required this.itemNames,
    required this.onDone,
    required this.onManageLink,
    super.key,
  });

  final CheckersPushResult result;

  /// The list's names by item id, for the lines the server skipped.
  final Map<String, String> itemNames;
  final VoidCallback onDone;
  final VoidCallback onManageLink;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (result.addedNothing) ...[
          Text(CheckersCopy.pushEmptyTitle, style: nest.text.title),
          Text(CheckersCopy.pushEmptyBody, style: nest.text.bodySecondary),
        ] else ...[
          NestSectionHeader(
            title: CheckersCopy.addedCount(result.added.length),
          ),
          for (final line in result.added)
            _Line(
              key: ValueKey('added-${line.itemId}'),
              title: line.name,
              detail: line.price.display,
            ),
        ],
        if (result.skipped.isNotEmpty) ...[
          const SizedBox(height: NestSpace.md),
          NestSectionHeader(
            title: CheckersCopy.skippedCount(result.skipped.length),
          ),
          for (final line in result.skipped)
            _Line(
              key: ValueKey('skipped-${line.itemId}'),
              title: itemNames[line.itemId] ?? CheckersCopy.skipUnknown,
              detail: _reason(line.reason),
            ),
        ],
        const SizedBox(height: NestSpace.lg),
        Text(
          CheckersCopy.cartSummary(result.cartItemCount, result.cartTotal),
          style: nest.text.bodyStrong,
        ),
        const SizedBox(height: NestSpace.xs),
        Text(CheckersCopy.finishInCheckers, style: nest.text.bodySecondary),
        const SizedBox(height: NestSpace.xl),
        NestButton(label: CheckersCopy.done, onPressed: onDone),
        const SizedBox(height: NestSpace.sm),
        NestButton(
          label: CheckersCopy.manageLink,
          variant: NestButtonVariant.ghost,
          onPressed: onManageLink,
        ),
      ],
    );
  }

  static String _reason(CheckersSkipReason reason) => switch (reason) {
    CheckersSkipReason.noMatch => CheckersCopy.skipNoMatch,
    CheckersSkipReason.outOfStock => CheckersCopy.skipOutOfStock,
    CheckersSkipReason.notFound => CheckersCopy.skipNotFound,
    CheckersSkipReason.weighedItem => CheckersCopy.skipWeighed,
    CheckersSkipReason.unrecognised => CheckersCopy.skipUnknown,
  };
}

class _Line extends StatelessWidget {
  const _Line({required this.title, required this.detail, super.key});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NestSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: nest.text.body),
          Text(
            detail,
            style: nest.text.caption.copyWith(color: nest.colors.inkSecondary),
          ),
        ],
      ),
    );
  }
}
