import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/quick_add_copy.dart';

/// The quick-add bar on the week: one line that looks like the field it opens,
/// with an example of what to type (calendar ADR-0004). It opens the quick-add
/// sheet rather than typing in place, because the week under it needs its
/// height — at 200% text a live field and its preview would leave the day's
/// agenda no room at all (`FE-14`).
class QuickAddBar extends StatelessWidget {
  const QuickAddBar({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Semantics(
      button: true,
      label: '${QuickAddCopy.label}. ${QuickAddCopy.hint}',
      excludeSemantics: true,
      child: Material(
        color: nest.colors.surface,
        shape: StadiumBorder(side: BorderSide(color: nest.colors.outline)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: NestSize.controlMedium,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: NestSpace.lg),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.sparkles,
                    size: NestSize.iconMedium,
                    color: nest.colors.accent,
                  ),
                  const SizedBox(width: NestSpace.md),
                  // Both yield at large text sizes: the example gives way
                  // first, and neither pushes past the edge (`FE-13`).
                  Expanded(
                    flex: 3,
                    child: Text(
                      QuickAddCopy.hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: nest.text.body.copyWith(
                        color: nest.colors.inkTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(width: NestSpace.sm),
                  Flexible(
                    flex: 2,
                    child: Text(
                      QuickAddCopy.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: nest.text.label.copyWith(
                        color: nest.colors.accentInk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
