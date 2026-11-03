import Foundation

struct DocumentPaths: Equatable {
  let householdId: String
  let memberId: String

  init(_ config: EngineConfig) {
    householdId = config.householdId
    memberId = config.memberId
  }

  var live: String { "households/\(householdId)/memberLocations/\(memberId)" }

  var places: String { "households/\(householdId)/places" }

  func day(_ key: String) -> String { "\(trail)/trailDays/\(key)" }

  func event(_ id: String) -> String { "\(trail)/placeEvents/\(id)" }

  private var trail: String { "households/\(householdId)/locationTrails/\(memberId)" }
}
