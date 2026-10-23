import '../../live_location/model/coordinates.dart';

/// The cities a household can say it shops in when the phone's location is
/// not already shared with NestPrep. Each is a fixed point in the city's
/// centre, with the centre's public postal code; each shop works out which
/// of its stores deliver there — Pick n Pay from an address it insists is
/// complete in shape (add-to-pnp ADR-0002).
enum CheckersArea {
  capeTown(
    'capeTown',
    'Cape Town',
    Coordinates(latitude: -33.9249, longitude: 18.4241),
    '8001',
  ),
  johannesburg(
    'johannesburg',
    'Johannesburg',
    Coordinates(latitude: -26.2041, longitude: 28.0473),
    '2001',
  ),
  pretoria(
    'pretoria',
    'Pretoria',
    Coordinates(latitude: -25.7479, longitude: 28.2293),
    '0002',
  ),
  durban(
    'durban',
    'Durban',
    Coordinates(latitude: -29.8587, longitude: 31.0218),
    '4001',
  ),
  gqeberha(
    'gqeberha',
    'Gqeberha',
    Coordinates(latitude: -33.9608, longitude: 25.6022),
    '6001',
  ),
  bloemfontein(
    'bloemfontein',
    'Bloemfontein',
    Coordinates(latitude: -29.0852, longitude: 26.1596),
    '9301',
  ),
  eastLondon(
    'eastLondon',
    'East London',
    Coordinates(latitude: -33.0292, longitude: 27.8546),
    '5201',
  );

  const CheckersArea(this.code, this.label, this.centre, this.postalCode);

  /// As stored on the phone.
  final String code;
  final String label;
  final Coordinates centre;

  /// The city centre's postal code.
  final String postalCode;

  static const fallback = capeTown;

  /// The area whose centre is closest to [point].
  static CheckersArea nearest(Coordinates point) => values.reduce(
    (best, area) =>
        area.centre.metresTo(point) < best.centre.metresTo(point) ? area : best,
  );

  static CheckersArea? fromCode(String code) =>
      values.where((area) => area.code == code).firstOrNull;
}
