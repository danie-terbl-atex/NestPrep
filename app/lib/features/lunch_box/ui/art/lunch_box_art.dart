import 'package:flutter/material.dart';

import '../../../../design/nest_kit.dart';
import '../../../../shared/copy/app_copy.dart';
import '../../model/lunch_box.dart';
import '../../model/lunch_slot.dart';
import 'lunch_glyph.dart';

/// A drawn lunch box — the brand's lunchbox, open, with one compartment per
/// slot (lunch-box ADR-0004). A filled compartment is tinted and holds its
/// slot's little drawing; an empty one is left pale, so a box that still
/// needs something looks like it.
///
/// When something lands in a compartment it pops in once, with the
/// celebrate curve; under reduce-motion it is simply there (`FE-15`). To a
/// screen reader the whole picture is one sentence naming what is packed.
class LunchBoxArt extends StatelessWidget {
  const LunchBoxArt({required this.box, this.height = 132, super.key});

  final LunchBox box;
  final double height;

  static const _aspect = 1.55;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final names = [for (final (_, pick) in box.filled) pick.name].join(', ');
    return Semantics(
      container: true,
      image: true,
      label: LunchCopy.boxArtLabel(names),
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          width: height * _aspect,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(NestRadius.xl),
              border: Border.all(
                color: c.outlineStrong,
                width: NestStroke.focus,
              ),
              boxShadow: nest.shadows.card,
            ),
            child: Padding(
              padding: const EdgeInsets.all(NestSpace.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _Compartment(slot: LunchSlot.main, box: box),
                  ),
                  const SizedBox(width: NestSpace.sm),
                  Expanded(
                    child: Column(
                      children: [
                        _CompartmentPair(
                          first: LunchSlot.fruit,
                          second: LunchSlot.veg,
                          box: box,
                        ),
                        const SizedBox(height: NestSpace.sm),
                        _CompartmentPair(
                          first: LunchSlot.snack,
                          second: LunchSlot.treat,
                          box: box,
                        ),
                      ],
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

/// Two small compartments side by side, taking half the height.
class _CompartmentPair extends StatelessWidget {
  const _CompartmentPair({
    required this.first,
    required this.second,
    required this.box,
  });

  final LunchSlot first;
  final LunchSlot second;
  final LunchBox box;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _Compartment(slot: first, box: box),
        ),
        const SizedBox(width: NestSpace.sm),
        Expanded(
          child: _Compartment(slot: second, box: box),
        ),
      ],
    ),
  );
}

class _Compartment extends StatelessWidget {
  const _Compartment({required this.slot, required this.box});

  final LunchSlot slot;
  final LunchBox box;

  @override
  Widget build(BuildContext context) {
    final c = NestTheme.of(context).colors;
    final motion = NestMotion.of(context);
    final pick = box[slot];
    return AnimatedContainer(
      duration: motion.standard,
      curve: NestMotion.standardCurve,
      decoration: BoxDecoration(
        color: pick == null ? c.surfaceTint : slotFill(c, slot),
        borderRadius: BorderRadius.circular(NestRadius.sm),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => AnimatedSwitcher(
          duration: motion.slow,
          switchInCurve: NestMotion.celebrate,
          switchOutCurve: NestMotion.exit,
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: pick == null
              ? SizedBox.shrink(key: ValueKey('empty-${slot.name}'))
              : Center(
                  key: ValueKey(pick.itemId),
                  child: LunchGlyph(
                    slot: slot,
                    size: constraints.biggest.shortestSide * 0.66,
                  ),
                ),
        ),
      ),
    );
  }
}
