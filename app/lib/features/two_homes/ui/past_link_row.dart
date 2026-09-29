import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/co_parent_link.dart';

/// A link that is no longer open — ended by either home, or never confirmed.
/// An ended one still opens, read-only, because what was shared stays with
/// both homes (household ADR-0004).
class PastLinkRow extends StatelessWidget {
  const PastLinkRow({
    required this.link,
    required this.childName,
    required this.onTap,
    super.key,
  });

  final CoParentLink link;
  final String childName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return NestListRow(
      leading: NestAvatar(name: childName, color: link.ownHome.color),
      title: childName,
      subtitle: TwoHomesCopy.homesTogether(
        link.ownHome.name,
        link.otherHome.name,
      ),
      trailing: NestTag(
        label: link.status == LinkStatus.ended
            ? TwoHomesCopy.statusEnded
            : TwoHomesCopy.statusDeclined,
      ),
      onTap: onTap,
    );
  }
}
