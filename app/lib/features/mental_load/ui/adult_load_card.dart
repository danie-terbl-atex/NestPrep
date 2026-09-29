import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/week_load.dart';

/// One adult's week: what they picked up, kind by kind, and a few of the
/// things themselves. The card is also the picture that is shared — the
/// [RepaintBoundary] around it is what [shareKey] captures — so it carries
/// the week and the brand inside its own box, and the share button sits
/// just outside it.
class AdultLoadCard extends StatelessWidget {
  const AdultLoadCard({
    required this.adult,
    required this.weekLabel,
    required this.shareKey,
    required this.onShare,
    super.key,
  });

  final AdultLoad adult;
  final String weekLabel;
  final GlobalKey shareKey;
  final VoidCallback onShare;

  static const _icons = {
    LoadKind.eventsPlanned: Icons.edit_calendar_outlined,
    LoadKind.eventsAttended: Icons.directions_car_outlined,
    LoadKind.todosDone: Icons.check_circle_outline,
    LoadKind.todosWaiting: Icons.pending_actions_outlined,
    LoadKind.groceriesBought: Icons.shopping_basket_outlined,
    LoadKind.groceriesAdded: Icons.playlist_add_outlined,
    LoadKind.careShifts: Icons.child_care_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final name = adult.member.displayName;
    final highlights = adult.highlights;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepaintBoundary(
          key: shareKey,
          child: NestCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    NestAvatar(name: name, color: adult.member.color),
                    const SizedBox(width: NestSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            MentalLoadCopy.carried(name, adult.total),
                            style: nest.text.title.copyWith(
                              color: nest.colors.ink,
                            ),
                          ),
                          Text(
                            weekLabel,
                            style: nest.text.caption.copyWith(
                              color: nest.colors.inkTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (adult.total > 0) const SizedBox(height: NestSpace.md),
                for (final kind in LoadKind.values)
                  if (adult.countOf(kind) > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: NestSpace.xs),
                      child: Row(
                        children: [
                          Icon(
                            _icons[kind],
                            size: NestSize.iconSmall,
                            color: nest.colors.accentInk,
                          ),
                          const SizedBox(width: NestSpace.sm),
                          Expanded(
                            child: Text(
                              '${adult.countOf(kind)} '
                              '${MentalLoadCopy.kind(kind, adult.countOf(kind))}',
                              style: nest.text.body.copyWith(
                                color: nest.colors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                if (highlights.isNotEmpty) ...[
                  const SizedBox(height: NestSpace.md),
                  Text(
                    MentalLoadCopy.including(highlights.join(', ')),
                    style: nest.text.caption.copyWith(
                      color: nest.colors.inkSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: NestSpace.md),
                const Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: NestBrandMark(width: NestSize.avatarSmall),
                ),
              ],
            ),
          ),
        ),
        // Outside the picture, so the shared card carries no button.
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Semantics(
            button: true,
            label: MentalLoadCopy.shareLabel(name),
            excludeSemantics: true,
            child: NestButton(
              label: MentalLoadCopy.share,
              icon: Icons.ios_share,
              variant: NestButtonVariant.ghost,
              size: NestButtonSize.small,
              isExpanded: false,
              onPressed: onShare,
            ),
          ),
        ),
      ],
    );
  }
}
