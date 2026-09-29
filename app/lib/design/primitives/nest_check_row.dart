import 'package:flutter/material.dart';

import '../tokens/nest_motion.dart';
import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';

/// A statement a person ticks to say it is true of them — "I am 18 or older",
/// "I am this child's parent". The whole row is the target, so a long
/// sentence at 200% text is still one easy tap (`FE-13`), and a screen reader
/// hears it as the checkbox it is, with its state.
///
/// The tick is the signal, not the fill colour: the box holds a check mark
/// when ticked and nothing when not.
class NestCheckRow extends StatelessWidget {
  const NestCheckRow({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final bool value;

  /// Null disables the row — while its form is being sent, say.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final change = onChanged;
    final isEnabled = change != null;
    return Semantics(
      checked: value,
      enabled: isEnabled,
      label: label,
      excludeSemantics: true,
      onTap: isEnabled ? () => change(!value) : null,
      child: Material(
        color: value ? c.surfaceTint : c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NestRadius.lg),
          side: BorderSide(color: value ? c.accent : c.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isEnabled ? () => change(!value) : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: NestSize.controlLarge),
            child: Padding(
              padding: const EdgeInsets.all(NestSpace.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: NestMotion.of(context).quick,
                    width: NestSize.iconLarge,
                    height: NestSize.iconLarge,
                    decoration: BoxDecoration(
                      color: value ? c.accent : c.surface,
                      borderRadius: BorderRadius.circular(NestRadius.sm),
                      border: Border.all(
                        color: value ? c.accent : c.outlineStrong,
                        width: NestStroke.focus,
                      ),
                    ),
                    child: value
                        ? Icon(
                            Icons.check,
                            size: NestSize.iconSmall,
                            color: c.onAccent,
                          )
                        : null,
                  ),
                  const SizedBox(width: NestSpace.md),
                  Expanded(
                    child: Text(
                      label,
                      style: nest.text.body.copyWith(
                        color: isEnabled ? c.ink : c.inkSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
