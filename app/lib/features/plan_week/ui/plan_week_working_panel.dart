import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../lunch_box/model/lunch_slot.dart';
import '../../lunch_box/ui/art/lunch_glyph.dart';

/// The model is working: the mark, the five compartments rising in under it
/// one by one, and a line on what is happening, so a wait of a few seconds
/// reads as work being done, not a spinner (`FE-08`). While it waits the mark
/// breathes, the compartments bob in a wave and the row turns one place each
/// beat; under reduce-motion it is simply there, still.
class PlanWeekWorkingPanel extends StatelessWidget {
  const PlanWeekWorkingPanel({
    required this.title,
    required this.line,
    this.progress,
    super.key,
  });

  final String title;
  final String line;

  /// How far it has got, when that can be counted.
  final String? progress;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Semantics(
      liveRegion: true,
      label: title,
      child: ListView(
        children: [
          const SizedBox(height: NestSpace.xl),
          const _WorkingLoop(),
          const SizedBox(height: NestSpace.xl),
          Text(title, textAlign: TextAlign.center, style: nest.text.headline),
          const SizedBox(height: NestSpace.sm),
          Text(
            line,
            textAlign: TextAlign.center,
            style: nest.text.body.copyWith(color: nest.colors.inkSecondary),
          ),
          if (progress case final progress?) ...[
            const SizedBox(height: NestSpace.sm),
            Text(
              progress,
              textAlign: TextAlign.center,
              style: nest.text.caption,
            ),
          ],
        ],
      ),
    );
  }
}

/// The mark and the row of compartments, kept moving on one repeating
/// controller: each lap is one beat, and when a lap ends two neighbours trade
/// places, so there is no timer to outlive the widget.
class _WorkingLoop extends StatefulWidget {
  const _WorkingLoop();

  @override
  State<_WorkingLoop> createState() => _WorkingLoopState();
}

class _WorkingLoopState extends State<_WorkingLoop>
    with SingleTickerProviderStateMixin {
  static const _beat = Duration(milliseconds: 1800);
  static const _tile = NestSize.avatarMedium;
  static const _gap = NestSpace.sm;
  static const _bob = NestSpace.xs;
  static const _breath = 0.04;

  static const _slots = LunchSlot.values;

  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: _beat,
  )..addListener(_swapOnNewLap);

  final List<LunchSlot> _row = [...LunchSlot.values];
  double _lastValue = 0;
  int _swaps = 0;

  void _swapOnNewLap() {
    final value = _loop.value;
    if (value < _lastValue) {
      setState(() {
        final left = _swaps++ % (_row.length - 1);
        _row.insert(left, _row.removeAt(left + 1));
      });
    }
    _lastValue = value;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (NestMotion.of(context).isReduced) {
      _loop.stop();
      _loop.value = 0;
      _lastValue = 0;
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  /// 0 at rest, 1 at the top of a swell; [lag] is how far behind the lead it
  /// runs, as a fraction of a lap.
  double _swell(double lag) =>
      (1 - math.cos((_loop.value - lag) * 2 * math.pi)) / 2;

  @override
  Widget build(BuildContext context) {
    final motion = NestMotion.of(context);
    final still = motion.isReduced;
    final width = _slots.length * (_tile + _gap) - _gap;
    return AnimatedBuilder(
      animation: _loop,
      builder: (context, _) => Column(
        children: [
          Center(
            child: Transform.scale(
              scale: still ? 1 : 1 + _breath * _swell(0),
              child: const NestBrandMark(),
            ),
          ),
          const SizedBox(height: NestSpace.xl),
          Center(
            child: SizedBox(
              width: width,
              height: _tile + _bob,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final (index, slot) in _slots.indexed)
                    AnimatedPositioned(
                      key: ValueKey(slot),
                      duration: motion.slow,
                      curve: NestMotion.standardCurve,
                      left: _row.indexOf(slot) * (_tile + _gap),
                      top: _bob,
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          still ? 0 : -_bob * _swell(index / _slots.length),
                        ),
                        child: NestRiseIn(
                          index: index,
                          child: LunchSlotTile(slot: slot),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
