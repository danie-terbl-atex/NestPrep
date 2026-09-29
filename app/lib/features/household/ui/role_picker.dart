import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/member_role.dart';

/// The five roles as chips, with a line under them saying what the chosen one
/// means — so choosing a role is not a guess about what somebody will see
/// (household ADR-0003). Shared by the member sheet and the invite sheet.
class RolePicker extends StatelessWidget {
  const RolePicker({
    required this.selected,
    required this.onSelect,
    this.roles = MemberRole.values,
    super.key,
  });

  final MemberRole selected;
  final ValueChanged<MemberRole> onSelect;
  final List<MemberRole> roles;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            for (final role in roles)
              NestChip(
                label: AccessCopy.roleName(role),
                isSelected: role == selected,
                onTap: () => onSelect(role),
              ),
          ],
        ),
        const SizedBox(height: NestSpace.sm),
        Text(
          AccessCopy.roleBlurb(selected),
          style: nest.text.caption.copyWith(color: nest.colors.inkSecondary),
        ),
      ],
    );
  }
}
