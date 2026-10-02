import 'dart:async';

import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/kid_copy.dart';
import '../model/kid_pairing.dart';

/// How long a pairing code has left, as a ring that empties and the minutes
/// and seconds in words (accounts ADR-0003). When it runs out it says so and
/// hands the parent the one thing to do next.
///
/// The ring moves once a second because time does, not as decoration; under
/// reduce-motion it still steps, since the number is information (`FE-15`).
class KidPairingCountdown extends StatefulWidget {
  const KidPairingCountdown({
    required this.pairing,
    required this.lifetime,
    required this.onMakeAnother,
    this.now = DateTime.now,
    super.key,
  });

  final KidPairing pairing;

  /// The code's whole life, for the ring's proportion.
  final Duration lifetime;
  final VoidCallback onMakeAnother;
  final DateTime Function() now;

  @override
  State<KidPairingCountdown> createState() => _KidPairingCountdownState();
}

class _KidPairingCountdownState extends State<KidPairingCountdown> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    setState(() {});
    if (widget.pairing.hasExpiredAt(widget.now())) _ticker?.cancel();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final now = widget.now();
    if (widget.pairing.hasExpiredAt(now)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            KidCopy.pairExpired,
            textAlign: TextAlign.center,
            style: nest.text.bodyStrong.copyWith(color: nest.colors.warning),
          ),
          const SizedBox(height: NestSpace.md),
          NestButton(
            label: KidCopy.pairMakeAnother,
            icon: LucideIcons.refreshCw,
            onPressed: widget.onMakeAnother,
          ),
        ],
      );
    }
    final left = widget.pairing.remainingAt(now);
    final fraction = widget.lifetime == Duration.zero
        ? 0.0
        : left.inMilliseconds / widget.lifetime.inMilliseconds;
    final words = KidCopy.pairTimeLeft(
      left.inMinutes,
      left.inSeconds.remainder(Duration.secondsPerMinute),
    );
    return Semantics(
      label: words,
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox.square(
            dimension: NestSize.iconLarge,
            child: CircularProgressIndicator(
              value: fraction.clamp(0, 1),
              strokeWidth: NestStroke.focus + NestStroke.hairline,
              backgroundColor: nest.colors.surfaceTint,
              color: nest.colors.accent,
            ),
          ),
          const SizedBox(width: NestSpace.sm),
          Flexible(
            child: Text(
              words,
              style: nest.text.bodyStrong.copyWith(
                color: nest.colors.inkSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
