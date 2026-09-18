import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/live_location/model/coordinates.dart';

/// The distance a household reads on the screen. It is the only arithmetic in
/// this feature, and a sign error in it reads as somebody being at home when
/// they are not.
void main() {
  const johannesburg = Coordinates(latitude: -26.2041, longitude: 28.0473);
  const pretoria = Coordinates(latitude: -25.7479, longitude: 28.2293);
  const capeTown = Coordinates(latitude: -33.9249, longitude: 18.4241);

  test('a point is no distance from itself', () {
    expect(johannesburg.metresTo(johannesburg), 0);
  });

  test('Johannesburg to Pretoria is about 54 km in a straight line', () {
    // The road is nearer 58; this is the great circle, which is what a screen
    // saying "54 km away" means and what a household reads it as.
    expect(johannesburg.metresTo(pretoria) / 1000, closeTo(53.9, 0.5));
  });

  test('Johannesburg to Cape Town is about 1264 km', () {
    expect(johannesburg.metresTo(capeTown) / 1000, closeTo(1264, 10));
  });

  test('distance does not care which way round it is asked', () {
    expect(
      johannesburg.metresTo(capeTown),
      closeTo(capeTown.metresTo(johannesburg), 0.001),
    );
  });

  test('a hundred metres north is a hundred metres', () {
    // The number the distance filter is set to, checked at the scale the
    // feature actually works at rather than only across a country.
    const hundredMetresNorth = Coordinates(
      latitude: -26.2041 + 0.000899,
      longitude: 28.0473,
    );
    expect(johannesburg.metresTo(hundredMetresNorth), closeTo(100, 1));
  });

  test('two points with the same numbers are the same point', () {
    expect(
      const Coordinates(latitude: 1.5, longitude: 2.5),
      const Coordinates(latitude: 1.5, longitude: 2.5),
    );
    expect(
      const Coordinates(latitude: 1.5, longitude: 2.5).hashCode,
      const Coordinates(latitude: 1.5, longitude: 2.5).hashCode,
    );
    expect(
      const Coordinates(latitude: 1.5, longitude: 2.5),
      isNot(const Coordinates(latitude: 2.5, longitude: 1.5)),
    );
  });
}
