import 'package:flutter/material.dart';

@immutable
class NestShadows {
  const NestShadows({required this.card, required this.floating});

  final List<BoxShadow> card;

  final List<BoxShadow> floating;

  static const light = NestShadows(
    card: [
      BoxShadow(color: Color(0x1435252E), blurRadius: 24, offset: Offset(0, 8)),
    ],
    floating: [
      BoxShadow(
        color: Color(0x2235252E),
        blurRadius: 32,
        offset: Offset(0, 12),
      ),
    ],
  );

  static const dark = NestShadows(
    card: [
      BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 6)),
    ],
    floating: [
      BoxShadow(
        color: Color(0x59000000),
        blurRadius: 28,
        offset: Offset(0, 10),
      ),
    ],
  );
}
