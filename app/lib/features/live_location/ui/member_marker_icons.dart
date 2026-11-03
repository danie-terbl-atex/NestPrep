import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../design/nest_kit.dart';

/// A member's pin: their colour, their initial, a ring so it reads on any map.
final class MemberMarkerIcons {
  final Map<(String, MemberColor, bool), BitmapDescriptor> _cache = {};

  static const _size = 112.0;
  static const pinSize = 44.0;

  Future<BitmapDescriptor> of({
    required String name,
    required MemberColor color,
    required NestTheme theme,
  }) async {
    final key = (name, color, theme.isDark);
    final cached = _cache[key];
    if (cached != null) return cached;
    final swatch = theme.members.of(color);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const centre = Offset(_size / 2, _size / 2);
    canvas
      ..drawCircle(centre, _size / 2, Paint()..color = theme.colors.surface)
      ..drawCircle(centre, _size / 2 - 8, Paint()..color = swatch.fill);
    final initial = TextPainter(
      text: TextSpan(
        text: name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: theme.text.title.copyWith(
          color: swatch.onFill,
          fontSize: _size * 0.42,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    initial.paint(
      canvas,
      centre - Offset(initial.width / 2, initial.height / 2),
    );
    final image = await recorder.endRecording().toImage(
      _size.toInt(),
      _size.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final icon = BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: pinSize,
      height: pinSize,
    );
    _cache[key] = icon;
    return icon;
  }
}
