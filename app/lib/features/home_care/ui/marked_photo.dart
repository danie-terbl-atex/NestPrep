import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../model/spot_mark.dart';
import 'spot_marks_painter.dart';

/// A photo at its own shape, with the circles drawn over it. The size comes
/// from the job rather than the bytes, so the frame is right before the
/// photo arrives and nothing jumps when it does (`FE-18`).
class MarkedPhoto extends StatelessWidget {
  const MarkedPhoto({
    required this.bytes,
    required this.aspectRatio,
    required this.semanticLabel,
    this.marks = const [],
    this.drawing = const [],
    super.key,
  });

  final Uint8List bytes;
  final double aspectRatio;
  final String semanticLabel;
  final List<SpotMark> marks;
  final List<Offset> drawing;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(NestRadius.lg),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(
              bytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              semanticLabel: semanticLabel,
              // Bytes that arrived damaged are a broken picture, not a
              // crash (`FE-09`).
              errorBuilder: (context, error, stack) => ColoredBox(
                color: nest.colors.surfaceTint,
                child: Icon(
                  LucideIcons.imageOff,
                  color: nest.colors.inkTertiary,
                  size: NestSize.iconLarge,
                ),
              ),
            ),
            CustomPaint(
              painter: SpotMarksPainter(
                marks: marks,
                drawing: drawing,
                line: nest.colors.danger,
                halo: nest.colors.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
