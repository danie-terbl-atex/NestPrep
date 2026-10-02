import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../groceries/model/grocery_list_view.dart';
import '../../groceries/state/grocery_list_controller.dart';
import '../../todos/model/todo_board.dart';
import '../../todos/state/todo_controller.dart';
import 'today_async.dart';
import 'today_section.dart';

/// What is left for the viewer today, overdue included.
class TodayTodoSection extends StatelessWidget {
  const TodayTodoSection({required this.onOpen, super.key});

  final VoidCallback onOpen;

  static const _shown = 3;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<TodoController>();
    return TodaySection(
      eyebrow: TodayCopy.todoEyebrow,
      actionLabel: TodayCopy.seeAll,
      onAction: onOpen,
      child: TodayAsync<TodoBoard>(
        state: controller.board,
        builder: (context, board) {
          final left = board.mine;
          if (left.isEmpty) {
            return Text(TodayCopy.todoDone, style: nest.text.bodySecondary);
          }
          return NestCard(
            padding: const EdgeInsets.symmetric(vertical: NestSpace.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final occurrence in left.take(_shown))
                  NestListRow(
                    title: occurrence.task.title,
                    leading: Icon(
                      occurrence.isOverdue(board.today)
                          ? LucideIcons.clockAlert
                          : LucideIcons.circle,
                      size: NestSize.iconMedium,
                      color: occurrence.isOverdue(board.today)
                          ? nest.colors.warning
                          : nest.colors.inkSecondary,
                    ),
                    onTap: onOpen,
                  ),
                if (left.length > _shown)
                  NestListRow(
                    title: TodayCopy.todoMore(left.length - _shown),
                    titleStyle: nest.text.label.copyWith(
                      color: nest.colors.accentInk,
                    ),
                    onTap: onOpen,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// How much is on the grocery list, one tap from it.
class TodayGrocerySection extends StatelessWidget {
  const TodayGrocerySection({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GroceryListController>();
    return TodaySection(
      eyebrow: TodayCopy.groceryEyebrow,
      child: TodayAsync<GroceryListView>(
        state: controller.list,
        builder: (context, list) => NestCard(
          onTap: onOpen,
          child: Row(
            children: [
              const NestIconTile(
                icon: LucideIcons.shoppingBasket,
                tint: NestTileTint.butter,
                size: NestSize.avatarLarge,
                iconSize: NestSize.iconMedium,
              ),
              const SizedBox(width: NestSpace.lg),
              Expanded(
                child: Text(
                  TodayCopy.groceryCount(list.toBuy.length),
                  style: NestTheme.of(context).text.title,
                ),
              ),
              const Icon(LucideIcons.chevronRight),
            ],
          ),
        ),
      ),
    );
  }
}
