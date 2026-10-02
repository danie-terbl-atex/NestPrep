import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/failure/app_failure.dart';
import '../../lunch_box/ui/art/lunch_glyph.dart';
import '../model/checked_product.dart';
import '../model/idea_search.dart';
import '../model/lunch_idea.dart';

/// One idea at the shop, as it happens: waiting, searching, what was found
/// and kept — each kept product with its price — and, a tap away, every
/// product left out with the reason for each child. A failed search says why
/// in words and can be tried again.
class PlanWeekSearchRow extends StatefulWidget {
  const PlanWeekSearchRow({
    required this.search,
    required this.childNames,
    required this.onRetry,
    super.key,
  });

  final IdeaSearch search;
  final Map<String, String> childNames;
  final VoidCallback onRetry;

  @override
  State<PlanWeekSearchRow> createState() => _PlanWeekSearchRowState();
}

class _PlanWeekSearchRowState extends State<PlanWeekSearchRow> {
  bool _showLeftOut = false;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final search = widget.search;
    final kept = search.kept;
    final leftOut = search.leftOut;
    return NestCard(
      variant: NestCardVariant.flat,
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              LunchGlyph(slot: search.idea.slot, size: NestSize.iconMedium),
              const SizedBox(width: NestSpace.sm),
              Expanded(child: Text(search.idea.idea, style: nest.text.title)),
            ],
          ),
          if (search.idea.origin == IdeaOrigin.aisle) ...[
            const SizedBox(height: NestSpace.xs),
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: NestTag(
                label: PlanWeekCopy.originAisle,
                tone: NestTagTone.accent,
                icon: LucideIcons.store,
              ),
            ),
          ],
          const SizedBox(height: NestSpace.xs),
          Semantics(
            liveRegion: true,
            child: _SearchStatus(search: search, onRetry: widget.onRetry),
          ),
          for (final product in kept)
            _ProductLine(
              key: ValueKey('kept-${product.productId}'),
              product: product,
              isKept: true,
              reasons: _reasonsFor(product),
            ),
          if (leftOut.isNotEmpty)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: NestButton(
                label: _showLeftOut
                    ? PlanWeekCopy.hideLeftOut
                    : PlanWeekCopy.showLeftOut(leftOut.length),
                variant: NestButtonVariant.ghost,
                size: NestButtonSize.small,
                isExpanded: false,
                onPressed: () => setState(() => _showLeftOut = !_showLeftOut),
              ),
            ),
          if (_showLeftOut)
            for (final product in leftOut)
              _ProductLine(
                key: ValueKey('left-${product.productId}'),
                product: product,
                isKept: false,
                reasons: _reasonsFor(product),
              ),
        ],
      ),
    );
  }

  /// Why it is kept from whom — on a kept product too, for the children it
  /// is not for.
  List<String> _reasonsFor(CheckedProduct product) => [
    for (final reason in product.reasons)
      PlanWeekCopy.reason(reason, childName: widget.childNames[reason.childId]),
  ];
}

/// Where one idea's search is, in words — and a failure's retry.
class _SearchStatus extends StatelessWidget {
  const _SearchStatus({required this.search, required this.onRetry});

  final IdeaSearch search;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return switch (search.status) {
      IdeaSearchStatus.waiting => Text(
        PlanWeekCopy.waiting,
        style: nest.text.caption,
      ),
      IdeaSearchStatus.searching => Row(
        children: [
          const SizedBox.square(
            dimension: NestSize.iconSmall,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: NestSpace.sm),
          Text(PlanWeekCopy.searching, style: nest.text.caption),
        ],
      ),
      IdeaSearchStatus.done when search.found.isEmpty => Text(
        PlanWeekCopy.nothingFound,
        style: nest.text.caption,
      ),
      IdeaSearchStatus.done => Text(
        PlanWeekCopy.found(search.found.length, search.kept.length),
        style: nest.text.caption,
      ),
      IdeaSearchStatus.failed => Row(
        children: [
          Expanded(
            child: Text(
              AppCopy.failure(
                search.failure ?? const UnknownFailure('search failed'),
              ),
              style: nest.text.caption.copyWith(color: nest.colors.danger),
            ),
          ),
          NestButton(
            label: AppCopy.retry,
            variant: NestButtonVariant.ghost,
            size: NestButtonSize.small,
            isExpanded: false,
            onPressed: onRetry,
          ),
        ],
      ),
    };
  }
}

class _ProductLine extends StatelessWidget {
  const _ProductLine({
    required this.product,
    required this.isKept,
    required this.reasons,
    super.key,
  });

  final CheckedProduct product;
  final bool isKept;

  /// Why it is kept from everybody, or from some of the idea's children.
  final List<String> reasons;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: NestSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isKept ? LucideIcons.circleCheck : LucideIcons.ban,
            size: NestSize.iconSmall,
            color: isKept ? nest.colors.success : nest.colors.inkTertiary,
          ),
          const SizedBox(width: NestSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.product.name, style: nest.text.body),
                for (final reason in reasons)
                  Text(reason, style: nest.text.caption),
              ],
            ),
          ),
          const SizedBox(width: NestSpace.sm),
          Text(product.product.price.display, style: nest.text.label),
        ],
      ),
    );
  }
}
