import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../avatars/ui/member_avatar.dart';
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
    this.onChangePicture,
    this.isRemoving = false,
    this.isInviting = false,
    this.actionsEnabled = true,
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

  /// For somebody who cannot manage the household: their own picture, or
  /// anybody's for family (avatars ADR-0001). Null when it is not theirs to
  /// change.
  final VoidCallback? onChangePicture;

  /// This profile's removal is on its way: the row says so and offers
  /// nothing until it is gone or refused.
  final bool isRemoving;

  /// This profile's invite code is being made: the row says so where the
  /// share button was, until the code arrives.
  final bool isInviting;

  /// False while another change is running, so a second removal cannot be
  /// asked for and silently dropped.
  final bool actionsEnabled;

  @override
  Widget build(BuildContext context) {
    final invite = onInvite;
    final remove = onRemove;
    final access = onAccess;
    if (isRemoving) {
      final nest = NestTheme.of(context);
      return Semantics(
        liveRegion: true,
        child: NestListRow(
          leading: Opacity(opacity: 0.5, child: MemberAvatar(member: member)),
          title: member.displayName,
          titleStyle: nest.text.bodyStrong.copyWith(
            color: nest.colors.inkTertiary,
          ),
          subtitle: AppCopy.householdRemoving,
          trailing: const _Working(),
        ),
      );
    }
    final changePicture = canManage ? null : onChangePicture;
    final row = NestListRow(
      leading: changePicture == null
          ? MemberAvatar(member: member)
          : NestEditablePicture(
              label: AvatarCopy.changePictureOf(member.displayName),
              pipSize: NestSize.iconMedium,
              onTap: changePicture,
              child: MemberAvatar(member: member),
            ),
      title: member.displayName,
      subtitle: _subtitle,
      onTap: canManage ? (actionsEnabled ? onEdit : null) : changePicture,
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
                if (isInviting)
                  const _Working()
                else if (invite != null)
                  NestIconButton(
                    icon: LucideIcons.share,
                    label: AppCopy.householdInvite,
                    variant: NestIconButtonVariant.plain,
                    onPressed: actionsEnabled ? invite : null,
                  ),
                if (remove != null)
                  NestIconButton(
                    icon: LucideIcons.userMinus,
                    label: AppCopy.householdRemove,
                    variant: NestIconButtonVariant.plain,
                    onPressed: actionsEnabled ? remove : null,
                  ),
              ],
            ),
    );
    return isInviting ? Semantics(liveRegion: true, child: row) : row;
  }

  /// The role, who this is, and the birthday when there is one — this row is
  /// where a birthday is read and changed, so it says so rather than making
  /// somebody open the sheet to find out (birthdays ADR-0001).
  String get _subtitle {
    if (isInviting) return AppCopy.householdMakingCode;
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

class _Working extends StatelessWidget {
  const _Working();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: NestSize.iconSmall,
      child: CircularProgressIndicator(
        strokeWidth: NestStroke.focus,
        color: NestTheme.of(context).colors.accent,
      ),
    );
  }
}
