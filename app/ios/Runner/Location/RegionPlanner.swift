import Foundation

enum RegionPlanner {
  static let placeSlots = 19
  static let replanDistance: Double = 500

  static func places(_ places: [FamilyPlace], nearest fix: Fix?) -> [FamilyPlace] {
    guard let fix else { return Array(places.prefix(placeSlots)) }
    let edge = { (place: FamilyPlace) in fix.distance(to: place) - place.radiusMetres }
    return Array(places.sorted { edge($0) < edge($1) }.prefix(placeSlots))
  }

  static func needsReplan(plannedAround anchor: Fix?, now fix: Fix) -> Bool {
    guard let anchor else { return true }
    return fix.distance(to: anchor) >= replanDistance
  }
}
