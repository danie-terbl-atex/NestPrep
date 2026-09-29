import 'package:flutter/material.dart';

/// The fixed set of colours a household member may pick. Stored by `name`,
/// never as a hex value, so the palette can be retuned without touching data.
/// A member colour is never the only signal: an avatar always carries the
/// initial and a row always carries the name (`FE-13`).
enum MemberColor {
  violet,
  pink,
  coral,
  amber,
  lime,
  mint,
  teal,
  sky,
  indigo,
  plum;

  static MemberColor fromName(String name) => MemberColor.values.firstWhere(
    (color) => color.name == name,
    orElse: () => MemberColor.violet,
  );
}

@immutable
class MemberSwatch {
  const MemberSwatch({required this.fill, required this.onFill});

  final Color fill;
  final Color onFill;
}

/// One swatch per member colour, distinguishable in the theme it belongs to
/// and AA-legible for the initial drawn on it.
@immutable
class NestMemberPalette {
  const NestMemberPalette._(this._swatches);

  final Map<MemberColor, MemberSwatch> _swatches;

  MemberSwatch of(MemberColor color) => _swatches[color]!;

  static const _lightInk = Color(0xFF1C2920);
  static const _darkInk = Color(0xFFF5F1E6);

  static const light = NestMemberPalette._({
    MemberColor.violet: MemberSwatch(
      fill: Color(0xFFC9BFFF),
      onFill: _lightInk,
    ),
    MemberColor.pink: MemberSwatch(fill: Color(0xFFF7BFDD), onFill: _lightInk),
    MemberColor.coral: MemberSwatch(fill: Color(0xFFFFC2B3), onFill: _lightInk),
    MemberColor.amber: MemberSwatch(fill: Color(0xFFFFD98A), onFill: _lightInk),
    MemberColor.lime: MemberSwatch(fill: Color(0xFFD3EB9A), onFill: _lightInk),
    MemberColor.mint: MemberSwatch(fill: Color(0xFFA9E8CF), onFill: _lightInk),
    MemberColor.teal: MemberSwatch(fill: Color(0xFF9EDDE3), onFill: _lightInk),
    MemberColor.sky: MemberSwatch(fill: Color(0xFFB5D6FF), onFill: _lightInk),
    MemberColor.indigo: MemberSwatch(
      fill: Color(0xFFB8C3FF),
      onFill: _lightInk,
    ),
    MemberColor.plum: MemberSwatch(fill: Color(0xFFE2BFF2), onFill: _lightInk),
  });

  static const dark = NestMemberPalette._({
    MemberColor.violet: MemberSwatch(fill: Color(0xFF5B4BD6), onFill: _darkInk),
    MemberColor.pink: MemberSwatch(fill: Color(0xFFB23B7A), onFill: _darkInk),
    MemberColor.coral: MemberSwatch(fill: Color(0xFFB84634), onFill: _darkInk),
    MemberColor.amber: MemberSwatch(fill: Color(0xFF8A6410), onFill: _darkInk),
    MemberColor.lime: MemberSwatch(fill: Color(0xFF4E7A16), onFill: _darkInk),
    MemberColor.mint: MemberSwatch(fill: Color(0xFF1F7A5B), onFill: _darkInk),
    MemberColor.teal: MemberSwatch(fill: Color(0xFF15747C), onFill: _darkInk),
    MemberColor.sky: MemberSwatch(fill: Color(0xFF2465B5), onFill: _darkInk),
    MemberColor.indigo: MemberSwatch(fill: Color(0xFF3D4FC2), onFill: _darkInk),
    MemberColor.plum: MemberSwatch(fill: Color(0xFF7B3C9E), onFill: _darkInk),
  });
}
