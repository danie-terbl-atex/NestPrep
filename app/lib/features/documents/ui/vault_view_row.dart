import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/vault_copy.dart';
import '../../household/model/member.dart';

/// One line of the view log: what was opened, by whom, in whose vault, and
/// when. The viewer is a name and a mark, never a colour alone (`FE-13`).
class VaultViewRow extends StatelessWidget {
  const VaultViewRow({
    required this.documentName,
    required this.viewer,
    required this.vaultOwner,
    required this.when,
    this.isThroughSharedLink = false,
    super.key,
  });

  final String documentName;

  /// Null for an account that had no profile, or one since removed.
  final Member? viewer;
  final Member? vaultOwner;

  /// When, as a person reads it — "just now", "Tue 29 Sep, 10:42".
  final String when;

  /// Opened by whoever held a shared link — nobody the household knows by
  /// name (documents ADR-0006).
  final bool isThroughSharedLink;

  @override
  Widget build(BuildContext context) {
    final who = viewer;
    final viewerName = isThroughSharedLink
        ? VaultCopy.logThroughLink
        : who?.displayName ?? VaultCopy.logSomebody;
    final vault = vaultOwner == null
        ? VaultCopy.homeTitle
        : VaultCopy.vaultOf(vaultOwner!.displayName);
    return NestListRow(
      title: documentName,
      subtitle: '${VaultCopy.logLine(viewerName, vault)} · $when',
      leading: who == null
          ? NestIconTile(
              icon: isThroughSharedLink ? LucideIcons.link : LucideIcons.user,
              size: NestSize.avatarMedium,
              iconSize: NestSize.iconMedium,
            )
          : NestAvatar(name: who.displayName, color: who.color),
    );
  }
}
