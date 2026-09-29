import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/vault_copy.dart';
import '../../household/model/household_view.dart';
import '../../household/model/member.dart';
import '../model/vault_family.dart';
import '../state/vault_controller.dart';

/// Who besides its owner and the admins can read a vault, and the switch for
/// each (documents ADR-0002). Only somebody who has joined can be granted —
/// the grant names their account, which an unclaimed profile does not have.
Future<void> showVaultAccessSheet({
  required BuildContext context,
  required String ownerMemberId,
}) {
  final controller = context.read<VaultController>();
  final view = context.read<HouseholdView>();
  return showNestSheet<void>(
    context: context,
    title: VaultCopy.accessTitle,
    builder: (sheetContext) => ChangeNotifierProvider<VaultController>.value(
      value: controller,
      child: _VaultAccessBody(ownerMemberId: ownerMemberId, view: view),
    ),
  );
}

class _VaultAccessBody extends StatelessWidget {
  const _VaultAccessBody({required this.ownerMemberId, required this.view});

  final String ownerMemberId;
  final HouseholdView view;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VaultController>();
    final grants = controller.loadedShelf?.grantsOf(ownerMemberId) ?? const [];
    final grantedUids = {for (final grant in grants) grant.granteeUid};
    final others = [
      for (final member in view.members)
        if (member.id != ownerMemberId && member.isClaimed) member,
    ];
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(VaultCopy.accessBody, style: nest.text.bodySecondary),
        const SizedBox(height: NestSpace.lg),
        if (others.isEmpty)
          Text(VaultCopy.accessNobodyElse, style: nest.text.body)
        else
          for (final member in others)
            _AccessRow(
              key: ValueKey(member.id),
              member: member,
              isFamily: isVaultFamily(member.role),
              isGranted: grantedUids.contains(member.claimedBy),
              onChanged: (grant) => grant
                  ? controller.share(ownerMemberId, member)
                  : controller.unshare(ownerMemberId, member.claimedBy ?? ''),
            ),
      ],
    );
  }
}

class _AccessRow extends StatelessWidget {
  const _AccessRow({
    required this.member,
    required this.isFamily,
    required this.isGranted,
    required this.onChanged,
    super.key,
  });

  final Member member;
  final bool isFamily;
  final bool isGranted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    // One node for a screen reader: the person's name, their role, and the
    // switch's state together (`FE-13`).
    return MergeSemantics(
      child: NestListRow(
        title: member.displayName,
        subtitle: isFamily
            ? VaultCopy.accessAlways
            : AppCopy.roleName(member.roleName),
        leading: NestAvatar(name: member.displayName, color: member.color),
        trailing: isFamily
            ? const Icon(Icons.verified_user_outlined)
            : Switch(value: isGranted, onChanged: onChanged),
      ),
    );
  }
}
