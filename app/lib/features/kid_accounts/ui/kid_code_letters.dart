import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';

/// A pairing code as six big letter tiles — the same on the parent's sheet,
/// where it is read out, and on the child's screen, where it is typed
/// (accounts ADR-0003). Seeing the same shape in both places is half of
/// explaining it to a seven-year-old.
///
/// Decorative to a screen reader: the field or the text beside it carries the
/// code as words.
class KidCodeLetters extends StatelessWidget {
  const KidCodeLetters({
    required this.code,
    required this.length,
    this.activeIndex,
    super.key,
  });

  final String code;
  final int length;

  /// The tile the next letter lands in, while somebody is typing.
  final int? activeIndex;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        children: [
          for (var index = 0; index < length; index++) ...[
            if (index > 0) const SizedBox(width: NestSpace.sm),
            Expanded(
              child: _LetterTile(
                letter: index < code.length ? code[index] : '',
                isActive: index == activeIndex,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LetterTile extends StatelessWidget {
  const _LetterTile({required this.letter, required this.isActive});

  final String letter;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final isFilled = letter.isNotEmpty;
    return AnimatedContainer(
      duration: NestMotion.of(context).quick,
      curve: NestMotion.enter,
      height: NestSize.controlHuge,
      decoration: BoxDecoration(
        color: isFilled ? c.accentSoft : c.surface,
        borderRadius: BorderRadius.circular(NestRadius.md),
        border: Border.all(
          color: isActive ? c.accent : c.outlineStrong,
          width: isActive ? NestStroke.focus : NestStroke.hairline,
        ),
      ),
      alignment: Alignment.center,
      // The letter shrinks to its tile rather than overflowing it when the
      // platform's text setting is large (`FE-13`).
      child: Padding(
        padding: const EdgeInsets.all(NestSpace.xs),
        child: FittedBox(
          child: Text(
            letter,
            style: nest.text.figure.copyWith(color: c.accentInk),
          ),
        ),
      ),
    );
  }
}
