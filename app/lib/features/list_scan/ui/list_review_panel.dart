import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/failure/app_failure.dart';
import '../../groceries/model/product_match.dart';
import '../model/list_scan_line.dart';
import 'list_line_tile.dart';

/// What the photo read, to tick, change and add (list-scan ADR-0001). Nothing
/// on it is on the grocery list yet; only the buttons at the foot add, and
/// they say how many. Everything but the buttons scrolls, so at 200% text the
/// lines stay reachable and the actions in reach (`FE-14`).
class ListReviewPanel extends StatelessWidget {
  const ListReviewPanel({
    required this.lines,
    required this.shops,
    required this.isAdding,
    required this.onToggle,
    required this.onChange,
    required this.onAddToList,
    required this.onFindAtShop,
    required this.onStartOver,
    this.callsLeft,
    this.failure,
    this.onDismissFailure,
    super.key,
  });

  final List<ListScanLine> lines;

  final List<ProductRetailer> shops;
  final bool isAdding;
  final ValueChanged<int> onToggle;
  final ValueChanged<ListScanLine> onChange;
  final VoidCallback onAddToList;
  final VoidCallback onFindAtShop;
  final VoidCallback onStartOver;
  final int? callsLeft;
  final AppFailure? failure;
  final VoidCallback? onDismissFailure;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final included = lines.where((line) => line.isIncluded).length;
    final left = callsLeft;
    final shown = failure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: NestSpace.xl),
            children: [
              if (shown != null) ...[
                NestBanner(
                  message: AppCopy.failure(shown),
                  tone: NestBannerTone.warning,
                  actionLabel: AppCopy.back,
                  onAction: onDismissFailure,
                ),
                const SizedBox(height: NestSpace.lg),
              ],
              Text(
                lines.isEmpty
                    ? ListScanCopy.noneTitle
                    : ListScanCopy.found(lines.length),
                style: nest.text.title.copyWith(color: nest.colors.ink),
              ),
              const SizedBox(height: NestSpace.xs),
              Text(
                lines.isEmpty ? ListScanCopy.noneBody : ListScanCopy.reviewBody,
                style: nest.text.body.copyWith(color: nest.colors.inkSecondary),
              ),
              if (left != null) ...[
                const SizedBox(height: NestSpace.xs),
                Text(
                  AiCopy.callsLeft(left),
                  style: nest.text.caption.copyWith(
                    color: nest.colors.inkTertiary,
                  ),
                ),
              ],
              const SizedBox(height: NestSpace.lg),
              for (final (index, line) in lines.indexed)
                Padding(
                  key: ValueKey('list-line-${line.key}'),
                  padding: const EdgeInsets.only(bottom: NestSpace.sm),
                  child: NestRiseIn(
                    index: index,
                    child: ListLineTile(
                      line: line,
                      onToggle: isAdding ? null : () => onToggle(line.key),
                      onChange: isAdding ? null : () => onChange(line),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            top: NestSpace.sm,
            bottom: NestSpace.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (lines.isNotEmpty && shops.isNotEmpty) ...[
                NestButton(
                  key: const ValueKey('list-scan-find'),
                  label: shops.length == 1
                      ? ListScanCopy.findAt(shops.single)
                      : ListScanCopy.findAtYourShop,
                  icon: LucideIcons.shoppingBasket,
                  onPressed: included == 0 || isAdding ? null : onFindAtShop,
                ),
                const SizedBox(height: NestSpace.sm),
              ],
              if (lines.isNotEmpty)
                NestButton(
                  key: const ValueKey('list-scan-add'),
                  label: ListScanCopy.addToList(included),
                  icon: LucideIcons.listPlus,
                  variant: shops.isEmpty
                      ? NestButtonVariant.primary
                      : NestButtonVariant.tonal,
                  isLoading: isAdding,
                  onPressed: included == 0 || isAdding ? null : onAddToList,
                ),
              const SizedBox(height: NestSpace.xs),
              NestButton(
                label: lines.isEmpty
                    ? ListScanCopy.tryAnother
                    : ListScanCopy.startOver,
                icon: LucideIcons.camera,
                variant: lines.isEmpty
                    ? NestButtonVariant.primary
                    : NestButtonVariant.ghost,
                onPressed: isAdding ? null : onStartOver,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
