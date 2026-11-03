import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/assistants_copy.dart';

/// The household's own switch for assistants (assistants ADR-0003): off,
/// every connected assistant is refused here until a parent puts it back.
/// Family only; it waits, unpressable, until the setting has been read.
class AssistantsSwitchCard extends StatelessWidget {
  const AssistantsSwitchCard({
    required this.allowed,
    required this.isBusy,
    required this.onChanged,
    super.key,
  });

  /// Null until the setting has been read.
  final bool? allowed;
  final bool isBusy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final value = allowed;
    final canPress = value != null && !isBusy;
    return NestCard(
      variant: NestCardVariant.flat,
      padding: const EdgeInsets.symmetric(vertical: NestSpace.xs),
      child: NestListRow(
        title: AssistantsCopy.allowTitle,
        subtitle: value == false
            ? AssistantsCopy.allowOffBody
            : AssistantsCopy.allowOnBody,
        trailing: Switch(
          value: value ?? true,
          onChanged: canPress ? onChanged : null,
        ),
        onTap: canPress ? () => onChanged(!value) : null,
      ),
    );
  }
}
