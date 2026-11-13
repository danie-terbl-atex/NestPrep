import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../tokens/nest_colors.dart';
import '../tokens/nest_motion.dart';
import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';
import 'nest_pressable.dart';

/// Premium's card: Butter with Ink on it in both themes, the crest on an Oat
/// tile, and a sheen that crosses it once as it arrives and stops
/// (subscriptions ADR-0007, design-system ADR-0002). With [onTap] it is a
/// control and says so with a chevron; without, it is something to read.
class NestPremiumCard extends StatefulWidget {
  const NestPremiumCard({
    required this.title,
    required this.body,
    this.detail,
    this.onTap,
    super.key,
  });

  final String title;
  final String body;
  final String? detail;
  final VoidCallback? onTap;

  @override
  State<NestPremiumCard> createState() => _NestPremiumCardState();
}

class _NestPremiumCardState extends State<NestPremiumCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheen = AnimationController(vsync: this);
  bool _hasStarted = false;

  static const _sheenStart = 0.3;
  static const _sheenStrength = 0.55;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasStarted) return;
    _hasStarted = true;
    final duration = NestMotion.of(context).sheen;
    if (duration == Duration.zero) return;
    _sheen
      ..duration = duration
      ..forward();
  }

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final detail = widget.detail;
    final onTap = widget.onTap;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(NestRadius.xl),
    );
    final card = DecoratedBox(
      decoration: ShapeDecoration(shape: shape, shadows: nest.shadows.card),
      child: Material(
        color: NestColors.butter,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(NestSpace.xl),
                child: Row(
                  children: [
                    const _Crest(),
                    const SizedBox(width: NestSpace.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: nest.text.title.copyWith(
                              color: NestColors.inkBrand,
                            ),
                          ),
                          const SizedBox(height: NestSpace.xs),
                          Text(
                            widget.body,
                            style: nest.text.body.copyWith(
                              color: NestColors.inkBrand,
                            ),
                          ),
                          if (detail != null) ...[
                            const SizedBox(height: NestSpace.sm),
                            Text(
                              detail,
                              style: nest.text.label.copyWith(
                                color: NestColors.inkBrand,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (onTap != null) ...[
                      const SizedBox(width: NestSpace.sm),
                      const Icon(
                        LucideIcons.chevronRight,
                        color: NestColors.inkBrand,
                      ),
                    ],
                  ],
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _sheen,
                    builder: (context, _) => _sheen.isAnimating
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: _sheenAt(_sheen.value),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return onTap == null ? card : NestPressable(child: card);
  }

  /// A soft band of Oat that starts off the card's left edge and ends off its
  /// right, after a short wait so the page has landed first.
  static LinearGradient _sheenAt(double progress) {
    final travelled = NestMotion.standardCurve.transform(
      ((progress - _sheenStart) / (1 - _sheenStart)).clamp(0, 1),
    );
    final x = -3 + 4 * travelled;
    return LinearGradient(
      begin: Alignment(x, -0.4),
      end: Alignment(x + 1, 0.4),
      colors: [
        NestColors.oat.withValues(alpha: 0),
        NestColors.oat.withValues(alpha: _sheenStrength),
        NestColors.oat.withValues(alpha: 0),
      ],
    );
  }
}

class _Crest extends StatelessWidget {
  const _Crest();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: NestColors.oat,
        borderRadius: BorderRadius.circular(NestRadius.md),
      ),
      child: const SizedBox.square(
        dimension: NestSize.iconTile,
        child: Icon(
          LucideIcons.award,
          size: NestSize.iconLarge,
          color: NestColors.inkBrand,
        ),
      ),
    ),
  );
}
