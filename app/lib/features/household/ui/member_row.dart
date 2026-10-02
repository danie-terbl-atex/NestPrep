import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../model/member.dart';

/// One profile in the household list. The colour is never the only signal that
/// says who this is — the initials and the name carry it too (`FE-13`).
class MemberRow extends StatelessWidget {
  const MemberRow({
    required this.member,
    required this.isViewer,
    required this.canManage,
    required this.onEdit,
    required this.onInvite,
    required this.onRemove,
    this.accessSummary,
    this.onAccess,
    super.key,
  });

  final Member member;
  final bool isViewer;
  final bool canManage;
  final VoidCallback onEdit;

  /// Null when there is nothing to invite: the profile is already claimed, or
  /// the viewer is not an admin.
  final VoidCallback? onInvite;

  /// Null when removing this profile makes no sense — it is the viewer's own.
  final VoidCallback? onRemove;

  /// For a kid, helper or carer, what they can see — said on the row, so a
  /// parent does not have to open anything to find out (household ADR-0003).
  final String? accessSummary;

  /// Opens the access editor. Null for family, and for anybody but an admin.
  final VoidCallback? onAccess;

  @override
  Widget build(BuildContext context) {
    final invite = onInvite;
    final remove = onRemove;
    final access = onAccess;
    return NestListRow(
      leading: NestAvatar(name: member.displayName, color: member.color),
      title: member.displayName,
      subtitle: _subtitle,
      onTap: canManage ? onEdit : null,
      trailing: !canManage
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (access != null)
                  NestIconButton(
                    icon: LucideIcons.eye,
                    label: AccessCopy.peopleAccess,
                    variant: NestIconButtonVariant.plain,
                    onPressed: access,
                  ),
                if (invite != null)
                  NestIconButton(
                    icon: LucideIcons.share,
                    label: AppCopy.householdInvite,
                    variant: NestIconButtonVariant.plain,
                    onPressed: invite,
                  ),
                if (remove != null)
                  NestIconButton(
                    icon: LucideIcons.userMinus,
                    label: AppCopy.householdRemove,
                    variant: NestIconButtonVariant.plain,
                    onPressed: remove,
                  ),
              ],
            ),
    );
  }

  /// The role, who this is, and the birthday when there is one — this row is
  /// where a birthday is read and changed, so it says so rather than making
  /// somebody open the sheet to find out (birthdays ADR-0001).
  String get _subtitle {
    final birthday = member.birthday;
    final parts = [
      AppCopy.roleName(member.roleName),
      if (isViewer)
        AppCopy.householdYou
      else if (!member.isClaimed)
        AppCopy.householdUnclaimed,
      if (birthday != null)
        NestDates.dayOfYear(
          month: birthday.month,
          day: birthday.day,
          year: birthday.year,
        ),
    ];
    final summary = accessSummary;
    return summary == null
        ? parts.join(' · ')
        : '${parts.join(' · ')}\n$summary';
  }
}
