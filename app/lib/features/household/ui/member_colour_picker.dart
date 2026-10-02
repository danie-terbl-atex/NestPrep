import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';

/// The fixed member palette, as a row of taps. Every colour in it is proven
/// readable against both themes' surfaces by the contrast test, and the chosen
/// one is marked with a tick as well as a ring, so the choice is not carried by
/// colour alone (`FE-13`, design-system ADR-0001).
class MemberColourPicker extends StatelessWidget {
  const MemberColourPicker({
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final MemberColor selected;
  final ValueChanged<MemberColor> onSelect;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Wrap(
      spacing: NestSpace.sm,
      runSpacing: NestSpace.sm,
      children: [
        for (final color in MemberColor.values)
          Semantics(
            button: true,
            selected: color == selected,
            label: color.name,
            child: InkWell(
              onTap: () => onSelect(color),
              borderRadius: BorderRadius.circular(NestRadius.pill),
              child: SizedBox(
                width: NestSize.touchTarget,
                height: NestSize.touchTarget,
                child: Center(
                  child: Container(
                    width: NestSize.avatarSmall,
                    height: NestSize.avatarSmall,
                    decoration: BoxDecoration(
                      color: nest.members.of(color).fill,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color == selected
                            ? nest.colors.ink
                            : nest.colors.outline,
                        width: color == selected
                            ? NestStroke.focus
                            : NestStroke.hairline,
                      ),
                    ),
                    child: color == selected
                        ? Icon(
                            LucideIcons.check,
                            size: NestSize.iconSmall,
                            color: nest.members.of(color).onFill,
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
