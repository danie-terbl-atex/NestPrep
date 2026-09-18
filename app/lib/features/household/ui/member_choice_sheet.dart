import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../model/member.dart';

/// Picks one member from a few, and comes back null when nobody was picked.
///
/// `MemberPicker` is the other shape of this question — choose any number,
/// inline, as part of a form. This one is a single answer that decides what
/// happens next, so it is a sheet and it can be dismissed.
Future<Member?> showMemberChoiceSheet({
  required BuildContext context,
  required String title,
  required List<Member> members,
}) => showNestSheet<Member>(
  context: context,
  title: title,
  builder: (sheetContext) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final member in members)
        Padding(
          padding: const EdgeInsets.only(bottom: NestSpace.xs),
          child: NestListRow(
            key: ValueKey(member.id),
            leading: NestAvatar(name: member.displayName, color: member.color),
            title: member.displayName,
            onTap: () => Navigator.of(sheetContext).pop(member),
          ),
        ),
    ],
  ),
);
