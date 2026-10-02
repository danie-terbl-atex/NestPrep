import '../../live_location/model/coordinates.dart';

/// The cities a household can say it shops in when the phone's location is
/// not already shared with NestPrep. Each is a fixed point in the city's
/// centre; Checkers works out which stores deliver there.
enum CheckersArea {
  capeTown(
    'capeTown',
    'Cape Town',
    Coordinates(latitude: -33.9249, longitude: 18.4241),
  ),
  johannesburg(
    'johannesburg',
    'Johannesburg',
    Coordinates(latitude: -26.2041, longitude: 28.0473),
  ),
  pretoria(
    'pretoria',
    'Pretoria',
    Coordinates(latitude: -25.7479, longitude: 28.2293),
  ),
  durban(
    'durban',
    'Durban',
    Coordinates(latitude: -29.8587, longitude: 31.0218),
  ),
  gqeberha(
    'gqeberha',
    'Gqeberha',
    Coordinates(latitude: -33.9608, longitude: 25.6022),
  ),
  bloemfontein(
    'bloemfontein',
    'Bloemfontein',
    Coordinates(latitude: -29.0852, longitude: 26.1596),
  ),
  eastLondon(
    'eastLondon',
    'East London',
    Coordinates(latitude: -33.0292, longitude: 27.8546),
  );

  const CheckersArea(this.code, this.label, this.centre);

  /// As stored on the phone.
  final String code;
  final String label;
  final Coordinates centre;

  static const fallback = capeTown;

  static CheckersArea? fromCode(String code) =>
      values.where((area) => area.code == code).firstOrNull;
}
