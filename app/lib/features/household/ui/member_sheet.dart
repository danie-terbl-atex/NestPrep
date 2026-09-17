import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/member.dart';
import '../model/member_role.dart';
import 'member_colour_picker.dart';

/// What the member sheet collected. Null from `showMemberSheet` means the
/// person closed it without saving.
class MemberDraft {
  const MemberDraft({
    required this.displayName,
    required this.color,
    required this.role,
  });

  final String displayName;
  final MemberColor color;
  final MemberRole role;
}

Future<MemberDraft?> showMemberSheet({
  required BuildContext context,
  Member? existing,
}) => showNestSheet<MemberDraft>(
  context: context,
  title: existing == null
      ? AppCopy.householdAddMember
      : AppCopy.householdEditMember,
  builder: (sheetContext) => _MemberSheetBody(existing: existing),
);

class _MemberSheetBody extends StatefulWidget {
  const _MemberSheetBody({required this.existing});

  final Member? existing;

  @override
  State<_MemberSheetBody> createState() => _MemberSheetBodyState();
}

class _MemberSheetBodyState extends State<_MemberSheetBody> {
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.displayName ?? '',
  );
  late MemberColor _color = widget.existing?.color ?? MemberColor.violet;
  late MemberRole _role = widget.existing?.role ?? MemberRole.member;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final canSave = _name.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        NestTextField(
          label: AppCopy.householdMemberName,
          hint: AppCopy.householdMemberNameHint,
          controller: _name,
          autofocus: widget.existing == null,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: NestSpace.xl),
        Text(
          AppCopy.householdMemberColour,
          style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
        ),
        const SizedBox(height: NestSpace.sm),
        MemberColourPicker(
          selected: _color,
          onSelect: (color) => setState(() => _color = color),
        ),
        const SizedBox(height: NestSpace.xl),
        Text(
          AppCopy.householdMemberRole,
          style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
        ),
        const SizedBox(height: NestSpace.sm),
        Wrap(
          spacing: NestSpace.sm,
          children: [
            for (final role in MemberRole.values)
              NestChip(
                label: AppCopy.roleName(role.name),
                isSelected: role == _role,
                onTap: () => setState(() => _role = role),
              ),
          ],
        ),
        const SizedBox(height: NestSpace.xxl),
        NestButton(
          label: AppCopy.householdSave,
          onPressed: canSave
              ? () => Navigator.of(context).pop(
                  MemberDraft(
                    displayName: _name.text.trim(),
                    color: _color,
                    role: _role,
                  ),
                )
              : null,
        ),
      ],
    );
  }
}
