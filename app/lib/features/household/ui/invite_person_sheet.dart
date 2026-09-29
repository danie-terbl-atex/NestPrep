import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/member_role.dart';
import 'role_picker.dart';

/// Who is being invited, and as what. Null from `showInvitePersonSheet` means
/// the sheet was closed without inviting anybody.
class InviteDraft {
  const InviteDraft({required this.displayName, required this.role});

  final String displayName;
  final MemberRole role;
}

/// A name and a role — nothing else is needed to make a profile somebody can
/// join as. The role starts at what the tapped option suggested, and can be
/// changed before anything is created (household ADR-0003).
Future<InviteDraft?> showInvitePersonSheet({
  required BuildContext context,
  required MemberRole suggestedRole,
}) => showNestSheet<InviteDraft>(
  context: context,
  title: AccessCopy.inviteNameTitle,
  builder: (sheetContext) => _InvitePersonBody(suggestedRole: suggestedRole),
);

class _InvitePersonBody extends StatefulWidget {
  const _InvitePersonBody({required this.suggestedRole});

  final MemberRole suggestedRole;

  @override
  State<_InvitePersonBody> createState() => _InvitePersonBodyState();
}

class _InvitePersonBodyState extends State<_InvitePersonBody> {
  final _name = TextEditingController();
  late MemberRole _role = widget.suggestedRole;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _canSend => _name.text.trim().isNotEmpty;

  void _send() {
    if (!_canSend) return;
    Navigator.of(context)
        .pop(InviteDraft(displayName: _name.text.trim(), role: _role));
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NestTextField(
            label: AccessCopy.inviteNameLabel,
            hint: AppCopy.householdMemberNameHint,
            controller: _name,
            autofocus: true,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _send(),
          ),
          const SizedBox(height: NestSpace.xl),
          Text(
            AccessCopy.inviteRoleLabel,
            style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.sm),
          RolePicker(
            selected: _role,
            onSelect: (role) => setState(() => _role = role),
          ),
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: AccessCopy.inviteSend,
            icon: Icons.send_outlined,
            onPressed: _canSend ? _send : null,
          ),
        ],
      ),
    );
  }
}
