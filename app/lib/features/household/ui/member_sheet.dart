import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/birthday.dart';
import '../model/member.dart';
import '../model/member_role.dart';
import 'member_birthday_field.dart';
import 'member_colour_picker.dart';
import 'role_picker.dart';

/// What the member sheet collected. Null from `showMemberSheet` means the
/// person closed it without saving.
class MemberDraft {
  const MemberDraft({
    required this.displayName,
    required this.color,
    required this.role,
    this.birthday,
  });

  final String displayName;
  final MemberColor color;
  final MemberRole role;

  /// Null means no birthday, which is an answer and not a gap (birthdays
  /// ADR-0001).
  final Birthday? birthday;
}

Future<MemberDraft?> showMemberSheet({
  required BuildContext context,
  required CalendarDate today,
  Member? existing,
}) => showNestSheet<MemberDraft>(
  context: context,
  title: existing == null
      ? AppCopy.householdAddMember
      : AppCopy.householdEditMember,
  builder: (sheetContext) => _MemberSheetBody(existing: existing, today: today),
);

class _MemberSheetBody extends StatefulWidget {
  const _MemberSheetBody({required this.existing, required this.today});

  final Member? existing;

  /// Today where the household lives, which is what bounds the birthday picker
  /// (foundation ADR-0007).
  final CalendarDate today;

  @override
  State<_MemberSheetBody> createState() => _MemberSheetBodyState();
}

class _MemberSheetBodyState extends State<_MemberSheetBody> {
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.displayName ?? '',
  );
  late MemberColor _color = widget.existing?.color ?? MemberColor.violet;
  late MemberRole _role = widget.existing?.role ?? MemberRole.parent;
  late Birthday? _birthday = widget.existing?.birthday;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final canSave = _name.text.trim().isNotEmpty;
    // Scrollable like the event sheet: the birthday field made this the
    // tallest sheet in the app, and at 200% text it is taller than a phone.
    return SingleChildScrollView(
      child: Column(
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
          RolePicker(
            selected: _role,
            onSelect: (role) => setState(() => _role = role),
          ),
          const SizedBox(height: NestSpace.xl),
          MemberBirthdayField(
            value: _birthday,
            today: widget.today,
            onChanged: (birthday) => setState(() => _birthday = birthday),
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
                      birthday: _birthday,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
