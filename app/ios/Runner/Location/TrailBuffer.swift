import Foundation

final class TrailBuffer {
  static let capacity = 3_000

  private let file: URL
  private(set) var points: [TrailPoint]

  init(file: URL) {
    self.file = file
    points = Self.read(file)
  }

  func reload() {
    points = Self.read(file)
  }

  func append(_ point: TrailPoint) {
    points.append(point)
    if points.count > Self.capacity {
      points = Self.capped(points)
      rewrite()
    } else {
      appendLine(point)
    }
  }

  func remove(_ sent: [TrailPoint]) {
    guard !sent.isEmpty else { return }
    let gone = Set(sent)
    points.removeAll { gone.contains($0) }
    rewrite()
  }

  func clear() {
    points = []
    try? FileManager.default.removeItem(at: file)
  }

  static func capped(_ points: [TrailPoint], capacity: Int = capacity) -> [TrailPoint] {
    Array(points.suffix(capacity))
  }

  static func defaultFile() -> URL {
    let manager = FileManager.default
    let support = manager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    var folder = support.appendingPathComponent("NestPrepLocation", isDirectory: true)
    try? manager.createDirectory(at: folder, withIntermediateDirectories: true)
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try? folder.setResourceValues(values)
    return folder.appendingPathComponent("trail.jsonl")
  }

  private static func read(_ file: URL) -> [TrailPoint] {
    guard let text = try? String(contentsOf: file, encoding: .utf8) else { return [] }
    let decoder = JSONDecoder()
    let points = text.split(separator: "\n").compactMap {
      try? decoder.decode(TrailPoint.self, from: Data($0.utf8))
    }
    return capped(points)
  }

  private func appendLine(_ point: TrailPoint) {
    guard let line = Self.line(point) else { return }
    guard let handle = try? FileHandle(forWritingTo: file) else {
      try? line.write(to: file, options: .atomic)
      return
    }
    defer { try? handle.close() }
    _ = try? handle.seekToEnd()
    try? handle.write(contentsOf: line)
  }

  private func rewrite() {
    let data = points.compactMap(Self.line).reduce(Data(), +)
    try? data.write(to: file, options: .atomic)
  }

  private static func line(_ point: TrailPoint) -> Data? {
    guard var data = try? JSONEncoder().encode(point) else { return nil }
    data.append(0x0A)
    return data
  }
}
