import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/list_match_copy.dart';
import '../state/list_match_controller.dart';

/// The foot of a step: *Next* once a product is selected, then *Remove* and
/// *Skip*. The place *Next* takes is held while it is away, so the products
/// above do not move as it comes and goes.
class ListMatchDock extends StatelessWidget {
  const ListMatchDock({super.key});

  static const nextKey = ValueKey('list-match-next');
  static const skipKey = ValueKey('list-match-skip');
  static const removeKey = ValueKey('list-match-remove');

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<ListMatchController>();
    final isRemoved = controller.outcome == ListMatchOutcome.removed;
    final hasRoomForIcons = MediaQuery.textScalerOf(context).scale(1) <= 1.3;
    final hint = switch (controller.products) {
      _ when isRemoved => '',
      AsyncData(value: final products) when products.isEmpty =>
        ListMatchCopy.nothingToPick,
      AsyncData() => ListMatchCopy.chooseHint,
      _ => '',
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: NestSize.controlLarge),
          child: AnimatedSwitcher(
            duration: NestMotion.of(context).quick,
            child: controller.selected != null && !isRemoved
                ? NestButton(
                    key: nextKey,
                    label: ListMatchCopy.next,
                    icon: LucideIcons.arrowRight,
                    onPressed: controller.next,
                  )
                : Center(
                    key: ValueKey(hint),
                    child: Text(
                      hint,
                      textAlign: TextAlign.center,
                      style: nest.text.caption.copyWith(
                        color: nest.colors.inkSecondary,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: NestSpace.sm),
        Row(
          children: [
            Expanded(
              child: isRemoved
                  ? NestButton(
                      label: ListMatchCopy.keep,
                      icon: hasRoomForIcons ? LucideIcons.undo2 : null,
                      variant: NestButtonVariant.outline,
                      size: NestButtonSize.medium,
                      onPressed: controller.keep,
                    )
                  : NestButton(
                      key: removeKey,
                      label: ListMatchCopy.remove,
                      icon: hasRoomForIcons ? LucideIcons.trash2 : null,
                      variant: NestButtonVariant.ghost,
                      size: NestButtonSize.medium,
                      onPressed: controller.remove,
                    ),
            ),
            const SizedBox(width: NestSpace.sm),
            Expanded(
              child: NestButton(
                key: skipKey,
                label: isRemoved ? ListMatchCopy.carryOn : ListMatchCopy.skip,
                variant: NestButtonVariant.tonal,
                size: NestButtonSize.medium,
                onPressed: controller.skip,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
