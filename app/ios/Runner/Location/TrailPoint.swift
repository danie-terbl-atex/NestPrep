import Foundation

struct TrailPoint: Codable, Hashable {
  let t: Int64
  let la: Double
  let lo: Double
  let ac: Int

  init(t: Int64, la: Double, lo: Double, ac: Int) {
    self.t = t
    self.la = la
    self.lo = lo
    self.ac = ac
  }

  init(_ fix: Fix) {
    self.init(
      t: Int64(fix.timestamp.timeIntervalSince1970.rounded(.down)),
      la: fix.latitude,
      lo: fix.longitude,
      ac: Int(fix.accuracy.rounded())
    )
  }

  var fields: [String: Any] { ["t": t, "la": la, "lo": lo, "ac": ac] }

  func day(in zone: TimeZone) -> String {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = zone
    let parts = calendar.dateComponents([.year, .month, .day], from: Date(timeIntervalSince1970: TimeInterval(t)))
    return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
  }
}
