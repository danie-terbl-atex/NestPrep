import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../lunch_box/model/lunch_box.dart';
import '../../lunch_box/ui/art/lunch_box_art.dart';
import '../../lunch_box/ui/art/lunch_glyph.dart';

/// What is in the kid's own lunch box today, drawn and then named — the box
/// a grown-up packed for them (lunch-box ADR-0004). Read-only: the plan is
/// the grown-ups' to change.
class KidLunchCard extends StatelessWidget {
  const KidLunchCard({required this.box, super.key});

  final LunchBox box;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(LunchCopy.kidLunchTitle, style: nest.text.title),
          const SizedBox(height: NestSpace.lg),
          Center(child: LunchBoxArt(box: box, height: 112)),
          const SizedBox(height: NestSpace.lg),
          if (box.isEmpty)
            Text(
              LunchCopy.kidLunchNothing,
              textAlign: TextAlign.center,
              style: nest.text.body.copyWith(color: nest.colors.inkTertiary),
            ),
          for (final (slot, pick) in box.filled)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.sm),
              child: Row(
                children: [
                  LunchSlotTile(slot: slot),
                  const SizedBox(width: NestSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LunchCopy.slotName(slot),
                          style: nest.text.label.copyWith(
                            color: nest.colors.inkSecondary,
                          ),
                        ),
                        Text(pick.name, style: nest.text.bodyStrong),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
