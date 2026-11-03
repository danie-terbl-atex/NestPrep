import 'dart:convert';

import 'package:flutter/painting.dart';

import '../../../design/nest_kit.dart';

/// The map in the brand's own colours, light or dark, built from the tokens so
/// no colour lives anywhere else.
abstract final class MapStyle {
  static String of(NestColors colors) => jsonEncode([
    _rule('geometry', colors.canvas),
    _rule('labels.text.fill', colors.inkSecondary),
    _rule('labels.text.stroke', colors.canvas),
    _rule('geometry', colors.surface, feature: 'road'),
    _rule('geometry.stroke', colors.outline, feature: 'road'),
    _rule('geometry', colors.secondarySoft, feature: 'water'),
    _rule('geometry', colors.successSoft, feature: 'poi.park'),
    {
      'featureType': 'poi.business',
      'stylers': [
        {'visibility': 'off'},
      ],
    },
    {
      'featureType': 'transit',
      'elementType': 'labels.icon',
      'stylers': [
        {'visibility': 'off'},
      ],
    },
  ]);

  static Map<String, Object> _rule(
    String element,
    Color color, {
    String? feature,
  }) => {
    'featureType': ?feature,
    'elementType': element,
    'stylers': [
      {'color': hex(color)},
    ],
  };

  static String hex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}
