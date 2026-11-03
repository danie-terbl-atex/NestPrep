import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/cook_along_copy.dart';

class CookAlongFramePicture extends StatelessWidget {
  const CookAlongFramePicture({super.key});

  static const _steps = 4;
  static const _step = 2;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    return Semantics(
      image: true,
      label: CookAlongCopy.pictureLabel,
      excludeSemantics: true,
      // A picture of the frame's screen, not text to read: it keeps its
      // proportions at any text size.
      child: MediaQuery.withNoTextScaling(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.surfaceTint,
            borderRadius: BorderRadius.circular(NestRadius.xl),
          ),
          child: Padding(
            padding: const EdgeInsets.all(NestSpace.xl),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.chrome,
                borderRadius: BorderRadius.circular(NestRadius.lg),
                boxShadow: nest.shadows.card,
              ),
              child: Padding(
                padding: const EdgeInsets.all(NestSpace.sm),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.canvas,
                    borderRadius: BorderRadius.circular(NestRadius.xs),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(NestSpace.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                CookAlongCopy.pictureStep.toUpperCase(),
                                style: nest.text.eyebrow,
                              ),
                            ),
                            for (var index = 0; index < _steps; index++)
                              _Segment(isDone: index < _step),
                          ],
                        ),
                        const SizedBox(height: NestSpace.md),
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: CookAlongCopy.pictureBefore),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: _TimePill(color: c.tileButter),
                              ),
                            ],
                          ),
                          style: nest.text.title,
                        ),
                        const SizedBox(height: NestSpace.lg),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _Arrow(icon: LucideIcons.arrowLeft),
                            SizedBox(width: NestSpace.sm),
                            _Arrow(icon: LucideIcons.arrowRight, isNext: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.isDone});

  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final c = NestTheme.of(context).colors;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: NestSpace.xxs),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDone ? c.accent : c.outlineStrong,
          borderRadius: BorderRadius.circular(NestRadius.pill),
        ),
        child: const SizedBox(width: NestSpace.lg, height: NestSpace.xs),
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final ink = nest.colors.ink;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(NestRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: NestSpace.sm,
          vertical: NestSpace.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.timer, size: NestSize.iconSmall, color: ink),
            const SizedBox(width: NestSpace.xs),
            Flexible(
              child: Text(
                CookAlongCopy.pictureTime,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: nest.text.label.copyWith(color: ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, this.isNext = false});

  final IconData icon;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final c = NestTheme.of(context).colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isNext ? c.accent : c.surface,
        shape: BoxShape.circle,
        border: isNext ? null : Border.all(color: c.outlineStrong),
      ),
      child: SizedBox.square(
        dimension: NestSize.avatarSmall,
        child: Icon(
          icon,
          size: NestSize.iconSmall,
          color: isNext ? c.onAccent : c.ink,
        ),
      ),
    );
  }
}
