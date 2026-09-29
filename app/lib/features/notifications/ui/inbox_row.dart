import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/notifications_copy.dart';
import '../model/inbox_item.dart';
import 'notification_look.dart';

/// One notification in the inbox: what kind, what it said, when, and whether
/// it has been read — the dot is never the only sign, the row says "Unread" to
/// a screen reader and its title is bolder (`FE-13`). Swiping it away clears
/// it; tapping opens it.
class InboxRow extends StatelessWidget {
  const InboxRow({
    required this.item,
    required this.when,
    required this.onOpen,
    required this.onClear,
    super.key,
  });

  final InboxItem item;
  final String when;
  final VoidCallback onOpen;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final category = item.kind;
    return Dismissible(
      key: ValueKey('inbox-dismiss-${item.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onClear(),
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: NestSpace.xl),
        decoration: BoxDecoration(
          color: nest.colors.dangerSoft,
          borderRadius: BorderRadius.circular(NestRadius.lg),
        ),
        child: Text(
          NotificationsCopy.clear,
          style: nest.text.label.copyWith(color: nest.colors.danger),
        ),
      ),
      child: Semantics(
        label: item.isUnread
            ? '${NotificationsCopy.categoryName(category)}, '
                  '${NotificationsCopy.unread}'
            : NotificationsCopy.categoryName(category),
        child: NestListRow(
          leading: NestIconTile(
            icon: NotificationLook.categoryIcon(category),
            tint: NotificationLook.categoryTint(category),
            size: NestSize.avatarMedium,
            iconSize: NestSize.iconMedium,
          ),
          title: item.title,
          titleStyle: item.isUnread ? nest.text.bodyStrong : nest.text.body,
          subtitle: item.detail ?? item.body,
          trailing: _When(when: when, isUnread: item.isUnread),
          onTap: onOpen,
        ),
      ),
    );
  }
}

class _When extends StatelessWidget {
  const _When({required this.when, required this.isUnread});

  final String when;
  final bool isUnread;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(when, style: nest.text.caption),
        if (isUnread) ...[
          const SizedBox(height: NestSpace.xs),
          ExcludeSemantics(
            child: Container(
              width: NestSpace.sm,
              height: NestSpace.sm,
              decoration: BoxDecoration(
                color: nest.colors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
