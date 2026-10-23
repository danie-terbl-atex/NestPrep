import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/model/checkers_area.dart';
import 'package:nestprep/features/live_location/model/coordinates.dart';

/// The shopping areas a phone falls back to, with the public postal code
/// Pick n Pay's address check wants (add-to-pnp ADR-0002).
void main() {
  test('a point takes the area whose centre is nearest', () {
    const sandton = Coordinates(latitude: -26.1088, longitude: 28.0527);
    const stellenbosch = Coordinates(latitude: -33.9321, longitude: 18.8602);
    expect(CheckersArea.nearest(sandton), CheckersArea.johannesburg);
    expect(CheckersArea.nearest(stellenbosch), CheckersArea.capeTown);
    for (final area in CheckersArea.values) {
      expect(CheckersArea.nearest(area.centre), area);
    }
  });

  test('every area has a four-digit postal code', () {
    for (final area in CheckersArea.values) {
      expect(area.postalCode, matches(RegExp(r'^[0-9]{4}$')));
    }
  });
}
