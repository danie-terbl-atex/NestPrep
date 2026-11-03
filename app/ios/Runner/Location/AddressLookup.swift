import CoreLocation

enum AddressLookup {
  static func line(latitude: Double, longitude: Double, reply: @escaping (String?) -> Void) {
    CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: latitude, longitude: longitude)) { placemarks, _ in
      reply(placemarks?.first.flatMap(line(for:)))
    }
  }

  static func line(for placemark: CLPlacemark) -> String? {
    line(
      number: placemark.subThoroughfare,
      street: placemark.thoroughfare,
      area: placemark.subLocality ?? placemark.locality,
      name: placemark.name
    )
  }

  static func line(number: String?, street: String?, area: String?, name: String?) -> String? {
    let road = [number, street].compactMap(nonEmpty).joined(separator: " ")
    let parts = [nonEmpty(road) ?? nonEmpty(name), nonEmpty(area)].compactMap { $0 }
    var unique: [String] = []
    for part in parts where !unique.contains(part) { unique.append(part) }
    return unique.isEmpty ? nil : unique.joined(separator: ", ")
  }

  private static func nonEmpty(_ text: String?) -> String? {
    guard let text = text?.trimmingCharacters(in: .whitespaces), !text.isEmpty else { return nil }
    return text
  }
}
