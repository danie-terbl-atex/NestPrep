import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

class RecipeBuilderRow extends StatelessWidget {
  const RecipeBuilderRow({
    required this.index,
    required this.count,
    required this.title,
    required this.removeLabel,
    required this.onEdit,
    required this.onRemove,
    required this.onMove,
    this.leading,
    this.titleStyle,
    super.key,
  });

  final int index;
  final int count;
  final String title;
  final String removeLabel;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  final void Function(int from, int to) onMove;
  final Widget? leading;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Semantics(
      container: true,
      customSemanticsActions: {
        if (index > 0)
          const CustomSemanticsAction(label: OwnRecipeCopy.moveUp): () =>
              onMove(index, index - 1),
        if (index < count - 1)
          const CustomSemanticsAction(label: OwnRecipeCopy.moveDown): () =>
              onMove(index, index + 1),
      },
      child: NestListRow(
        leading: leading,
        title: title,
        titleStyle: titleStyle,
        onTap: onEdit,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            NestIconButton(
              icon: LucideIcons.x,
              label: removeLabel,
              variant: NestIconButtonVariant.plain,
              onPressed: onRemove,
            ),
            ReorderableDragStartListener(
              index: index,
              // A tap that misses the drag must not open the row for editing.
              child: GestureDetector(
                onTap: () {},
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                child: Semantics(
                  label: OwnRecipeCopy.dragToMove,
                  child: SizedBox.square(
                    dimension: NestSize.touchTarget,
                    child: Icon(
                      LucideIcons.gripVertical,
                      size: NestSize.iconSmall,
                      color: nest.colors.inkTertiary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget recipeRowInFlight(Widget row, int index, Animation<double> animation) =>
    Material(type: MaterialType.transparency, child: row);
