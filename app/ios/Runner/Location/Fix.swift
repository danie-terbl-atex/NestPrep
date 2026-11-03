import CoreLocation

struct Fix: Codable, Equatable {
  let latitude: Double
  let longitude: Double
  let accuracy: Double
  let timestamp: Date

  init(latitude: Double, longitude: Double, accuracy: Double, timestamp: Date) {
    self.latitude = latitude
    self.longitude = longitude
    self.accuracy = accuracy
    self.timestamp = timestamp
  }

  init(_ location: CLLocation) {
    self.init(
      latitude: location.coordinate.latitude,
      longitude: location.coordinate.longitude,
      accuracy: location.horizontalAccuracy,
      timestamp: location.timestamp
    )
  }

  var coordinate: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }

  func distance(to other: Fix) -> CLLocationDistance {
    distance(toLatitude: other.latitude, longitude: other.longitude)
  }

  func distance(to place: FamilyPlace) -> CLLocationDistance {
    distance(toLatitude: place.latitude, longitude: place.longitude)
  }

  func isInside(_ place: FamilyPlace) -> Bool { distance(to: place) <= place.radiusMetres }

  private func distance(toLatitude otherLatitude: Double, longitude otherLongitude: Double) -> CLLocationDistance {
    CLLocation(latitude: latitude, longitude: longitude)
      .distance(from: CLLocation(latitude: otherLatitude, longitude: otherLongitude))
  }
}
