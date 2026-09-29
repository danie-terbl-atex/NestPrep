import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';

/// One section of a profile — allergies, food, medication, school, sizes: a
/// card with a tinted mark, a title, and the one way to change it in the
/// corner. The corner button is absent, not disabled, for somebody the rules
/// would refuse (`FE-04`).
class FamilySectionCard extends StatelessWidget {
  const FamilySectionCard({
    required this.icon,
    required this.tint,
    required this.title,
    required this.child,
    this.actionIcon = Icons.edit_outlined,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final NestTileTint tint;
  final String title;
  final Widget child;
  final IconData actionIcon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final action = onAction;
    return NestCard(
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              NestIconTile(
                icon: icon,
                tint: tint,
                size: NestSize.avatarMedium,
                iconSize: NestSize.iconMedium,
              ),
              const SizedBox(width: NestSpace.md),
              Expanded(child: Text(title, style: nest.text.title)),
              if (action != null)
                NestIconButton(
                  icon: actionIcon,
                  label: actionLabel ?? title,
                  variant: NestIconButtonVariant.plain,
                  onPressed: action,
                ),
            ],
          ),
          const SizedBox(height: NestSpace.md),
          child,
        ],
      ),
    );
  }
}
