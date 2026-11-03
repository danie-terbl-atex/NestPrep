import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/assistants_copy.dart';
import '../model/assistant_via.dart';

/// The small mark on an event or a grocery item an assistant added — *via
/// Claude* — so the household can tell it from what a person typed
/// (assistants ADR-0005). Quiet on purpose: a neutral badge, said in full
/// to a screen reader.
class AssistantViaMark extends StatelessWidget {
  const AssistantViaMark({required this.via, super.key});

  final AssistantVia via;

  @override
  Widget build(BuildContext context) => Semantics(
    label: AssistantsCopy.viaSpoken(via),
    excludeSemantics: true,
    child: NestBadge(label: AssistantsCopy.via(via), icon: LucideIcons.bot),
  );
}
