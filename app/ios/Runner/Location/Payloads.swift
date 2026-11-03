import FirebaseFirestore

struct LiveSnapshot: Equatable {
  let fix: Fix
  let motion: MotionLabel
  let battery: BatteryReading
}

enum Payloads {
  static let lease: TimeInterval = 24 * 60 * 60
  static let retention: TimeInterval = 30 * 24 * 60 * 60

  static func live(_ snapshot: LiveSnapshot, now: Date) -> [String: Any] {
    var data: [String: Any] = [
      "point": GeoPoint(latitude: snapshot.fix.latitude, longitude: snapshot.fix.longitude),
      "accuracyMetres": Int(snapshot.fix.accuracy.rounded()),
      "reportedAt": FieldValue.serverTimestamp(),
      "sharingUntil": Timestamp(date: now.addingTimeInterval(lease)),
      "mode": "continuous",
      "charging": snapshot.battery.charging,
      "motion": snapshot.motion.rawValue,
    ]
    if let percent = snapshot.battery.percent {
      data["batteryPercent"] = percent
    }
    return data
  }

  static func trail(_ points: [TrailPoint], now: Date) -> [String: Any] {
    [
      "points": FieldValue.arrayUnion(points.map(\.fields)),
      "updatedAt": FieldValue.serverTimestamp(),
      "expiresAt": Timestamp(date: now.addingTimeInterval(retention)),
    ]
  }

  static func event(_ event: PlaceEvent, now: Date) -> [String: Any] {
    [
      "placeId": event.placeId,
      "kind": event.kind.rawValue,
      "at": FieldValue.serverTimestamp(),
      "expiresAt": Timestamp(date: now.addingTimeInterval(retention)),
    ]
  }
}

extension WriteFailure {
  init(_ error: Error) {
    let error = error as NSError
    guard error.domain == FirestoreErrorDomain else {
      self = .other
      return
    }
    switch error.code {
    case FirestoreErrorCode.permissionDenied.rawValue: self = .permissionDenied
    case FirestoreErrorCode.alreadyExists.rawValue: self = .alreadyExists
    default: self = .other
    }
  }
}

extension FamilyPlace {
  static func list(fromDocuments documents: [(id: String, data: [String: Any])]) -> [FamilyPlace] {
    documents.compactMap { document in
      guard let centre = document.data["centre"] as? GeoPoint,
        let radius = (document.data["radiusMetres"] as? NSNumber)?.doubleValue
      else { return nil }
      return FamilyPlace(id: document.id, latitude: centre.latitude, longitude: centre.longitude, radiusMetres: radius)
    }
  }
}
