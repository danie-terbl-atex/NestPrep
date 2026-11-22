import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/recipes/data/callable_recipe_drafter.dart';
import 'package:nestprep/features/recipes/model/recipe_snap.dart';

RecipeSnap _snap(List<int> parts, {int? whole}) => RecipeSnap(
  parts: [
    for (final part in parts) Uint8List.fromList([part]),
  ],
  thumbnail: Uint8List(0),
  whole: whole == null ? null : Uint8List.fromList([whole]),
);

String _base64(int byte) => base64Encode([byte]);

void main() {
  test('one ordinary photo goes whole, as a snap always did', () {
    expect(
      photosOnWire([
        _snap([1, 2], whole: 9),
      ]),
      {
        'photo': {'mimeType': 'image/jpeg', 'data': _base64(9)},
      },
    );
  });

  test('one long screenshot goes as its parts', () {
    expect(
      photosOnWire([
        _snap([1, 2, 3]),
      ]),
      {
        'photos': [
          {
            'parts': [_base64(1), _base64(2), _base64(3)],
          },
        ],
      },
    );
  });

  test('several photos go as parts, in order, whatever they keep whole', () {
    expect(
      photosOnWire([
        _snap([1, 2], whole: 9),
        _snap([3]),
      ]),
      {
        'photos': [
          {
            'parts': [_base64(1), _base64(2)],
          },
          {
            'parts': [_base64(3)],
          },
        ],
      },
    );
  });
}
