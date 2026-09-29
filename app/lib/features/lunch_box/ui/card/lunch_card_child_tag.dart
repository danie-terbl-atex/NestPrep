import 'package:flutter/material.dart';

import '../../../../design/nest_kit.dart';
import '../../model/lunch_card_content.dart';

/// Who a box is for on a card: the child's avatar — their initials, or their
/// number when the parent chose no names — and, when there are words to say,
/// the words beside it on a pill (lunch-box ADR-0005).
class LunchCardChildTag extends StatelessWidget {
  const LunchCardChildTag({
    required this.child,
    required this.surface,
    this.text,
    super.key,
  });

  final LunchCardChild child;
  final Color surface;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final words = text;
    final avatar = NestAvatar(
      name: child.label ?? '${child.number}',
      color: child.color,
      size: NestSize.avatarSmall,
    );
    if (words == null) return avatar;
    return DecoratedBox(
      decoration: ShapeDecoration(color: surface, shape: const StadiumBorder()),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          NestSpace.xxs,
          NestSpace.xxs,
          NestSpace.md,
          NestSpace.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            avatar,
            const SizedBox(width: NestSpace.sm),
            Flexible(
              child: Text(
                words,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: nest.text.label,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
