import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../design/nest_kit.dart';
import '../../avatars/model/avatar_catalogue.g.dart';
import '../../avatars/model/avatar_face_anchor.dart';
import '../../avatars/model/resolved_avatar.dart';
import '../../avatars/ui/resolved_member_avatar.dart';

/// A member's pin: their colour, their initial, a ring so it reads on any map.
/// With an avatar, the picture and its layers on a smaller disc, so a hat has
/// room above it inside the bitmap.
final class MemberMarkerIcons {
  MemberMarkerIcons({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final Map<(String, MemberColor, bool, String), BitmapDescriptor> _cache = {};

  static const _size = 112.0;
  static const pinSize = 44.0;
  static const _disc = 0.72;

  static (String, MemberColor, bool, String) keyOf({
    required String name,
    required MemberColor color,
    required bool isDark,
    ResolvedAvatar? avatar,
    bool hasPhoto = false,
  }) => (
    name,
    color,
    isDark,
    avatar == null || avatar.isInitialOnly
        ? ''
        : '${avatar.signature}|$hasPhoto',
  );

  Future<BitmapDescriptor> of({
    required String name,
    required MemberColor color,
    required NestTheme theme,
    ResolvedAvatar? avatar,
    Uint8List? photo,
  }) async {
    final key = keyOf(
      name: name,
      color: color,
      isDark: theme.isDark,
      avatar: avatar,
      hasPhoto: photo != null,
    );
    final cached = _cache[key];
    if (cached != null) return cached;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    if (key.$4.isEmpty) {
      _paintInitial(canvas, name, color, theme);
    } else {
      await _paintAvatar(canvas, name, color, theme, avatar!, photo);
    }
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

  void _paintInitial(
    Canvas canvas,
    String name,
    MemberColor color,
    NestTheme theme,
  ) {
    final swatch = theme.members.of(color);
    const centre = Offset(_size / 2, _size / 2);
    canvas
      ..drawCircle(centre, _size / 2, Paint()..color = theme.colors.surface)
      ..drawCircle(centre, _size / 2 - 8, Paint()..color = swatch.fill);
    _paintLetter(canvas, theme, name, swatch, centre, _size);
  }

  void _paintLetter(
    Canvas canvas,
    NestTheme theme,
    String name,
    MemberSwatch swatch,
    Offset centre,
    double size,
  ) {
    final initial = TextPainter(
      text: TextSpan(
        text: name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: theme.text.title.copyWith(
          color: swatch.onFill,
          fontSize: size * 0.42,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    initial.paint(
      canvas,
      centre - Offset(initial.width / 2, initial.height / 2),
    );
  }

  Future<void> _paintAvatar(
    Canvas canvas,
    String name,
    MemberColor color,
    NestTheme theme,
    ResolvedAvatar avatar,
    Uint8List? photo,
  ) async {
    const disc = _size * _disc;
    const origin = Offset(
      (_size - disc) / 2,
      _size * NestAvatar.topOverhang * _disc * 1.1,
    );
    final circle = origin & const Size.square(disc);
    final pixels = (disc * 2).ceil();
    final base = switch (avatar.base) {
      ResolvedPreset(:final assetId) => await _asset(assetId, pixels),
      ResolvedImage() when photo != null => await _decode(photo, pixels),
      _ => null,
    };
    final swatch = base == null
        ? theme.members.of(color)
        : NestMemberPalette.light.of(color);
    canvas
      ..drawCircle(
        circle.center,
        disc / 2 + 5,
        Paint()..color = theme.colors.surface,
      )
      ..drawCircle(circle.center, disc / 2, Paint()..color = swatch.fill);
    if (base == null) {
      _paintLetter(canvas, theme, name, swatch, circle.center, disc);
    } else {
      canvas
        ..save()
        ..clipPath(Path()..addOval(circle))
        ..drawImageRect(base, _coverOf(base), circle, Paint())
        ..restore();
    }
    final face = switch (avatar.base) {
      final ResolvedPreset preset => preset.face,
      _ => null,
    };
    for (final slot in NestAvatarSlot.values) {
      final entry = avatar.layers.entries
          .where((entry) => ResolvedMemberAvatar.slotOf(entry.key) == slot)
          .firstOrNull;
      if (entry == null) continue;
      final art = await _asset(entry.value, pixels);
      if (art == null) continue;
      final isFace = entry.key == AvatarSlot.face && face != null;
      final box = NestAvatar.layerBox(
        NestAvatarLayer(
          slot: slot,
          image: AssetImage(avatarAssetPath(entry.value)),
          centre: isFace ? Offset(face.x, face.y) : null,
          width: isFace ? face.w * avatarFaceScale : null,
        ),
        disc,
      ).shift(origin);
      canvas.drawImageRect(
        art,
        Offset.zero & Size(art.width.toDouble(), art.height.toDouble()),
        box,
        Paint()..filterQuality = FilterQuality.medium,
      );
    }
  }

  static Rect _coverOf(ui.Image image) {
    final side = image.width < image.height ? image.width : image.height;
    return Rect.fromLTWH(
      (image.width - side) / 2,
      (image.height - side) / 2,
      side.toDouble(),
      side.toDouble(),
    );
  }

  Future<ui.Image?> _asset(String assetId, int pixels) async {
    try {
      final data = await _bundle.load(avatarAssetPath(assetId));
      return await _decode(data.buffer.asUint8List(), pixels);
    } on Exception {
      return null;
    }
  }

  static Future<ui.Image?> _decode(Uint8List bytes, int pixels) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: pixels);
      return (await codec.getNextFrame()).image;
    } on Exception {
      return null;
    }
  }
}
