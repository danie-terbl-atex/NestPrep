import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/list_scan_line.dart';

/// One line the photo read: the tick, the name, how much, and a way to change
/// it. The whole row toggles, like a grocery line; the pencil is its own
/// button, so the two gestures cannot be confused.
class ListLineTile extends StatelessWidget {
  const ListLineTile({
    required this.line,
    required this.onToggle,
    required this.onChange,
    super.key,
  });

  final ListScanLine line;
  final VoidCallback? onToggle;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final quantity = line.quantity;
    return NestCard(
      variant: line.isIncluded ? NestCardVariant.raised : NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(NestRadius.lg),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            NestSpace.md,
            NestSpace.sm,
            NestSpace.xs,
            NestSpace.sm,
          ),
          child: Row(
            children: [
              Semantics(
                checked: line.isIncluded,
                label: line.isIncluded
                    ? ListScanCopy.ticked(line.name)
                    : ListScanCopy.unticked(line.name),
                excludeSemantics: true,
                child: Icon(
                  line.isIncluded
                      ? LucideIcons.circleCheck
                      : LucideIcons.circle,
                  color: line.isIncluded
                      ? nest.colors.success
                      : nest.colors.outlineStrong,
                  size: NestSize.iconLarge,
                ),
              ),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.name,
                      style: nest.text.bodyStrong.copyWith(
                        color: line.isIncluded
                            ? nest.colors.ink
                            : nest.colors.inkTertiary,
                        decoration: line.isIncluded
                            ? null
                            : TextDecoration.lineThrough,
                      ),
                    ),
                    if (quantity != null)
                      Text(
                        quantity,
                        style: nest.text.caption.copyWith(
                          color: nest.colors.inkSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              NestIconButton(
                icon: LucideIcons.pencil,
                label: ListScanCopy.change(line.name),
                variant: NestIconButtonVariant.plain,
                onPressed: onChange,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
