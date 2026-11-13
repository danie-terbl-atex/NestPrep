import Flutter
import Foundation

/// Hands the app the PDF the ShareToFrame extension left in the app group
/// (recipes ADR-0009). The link names only a token; the path never comes from it.
enum SharedPdfChannel {
  private static let appGroup = "group.io.nullstate.nestprep.app"

  static func register(messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(name: "io.nullstate.nestprep/shared_pdf", binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        guard call.method == "take" else { return result(FlutterMethodNotImplemented) }
        let token = (call.arguments as? [String: Any])?["token"] as? String
        DispatchQueue.global(qos: .userInitiated).async {
          let taken = token.flatMap(take)
          DispatchQueue.main.async { result(taken) }
        }
      }
  }

  private static func take(_ token: String) -> [String: String]? {
    guard UUID(uuidString: token) != nil,
      let inbox = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
        .appendingPathComponent("SharedPDFs", isDirectory: true)
    else { return nil }
    let folder = inbox.appendingPathComponent(token, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: folder) }
    guard
      let shared = try? FileManager.default.contentsOfDirectory(
        at: folder, includingPropertiesForKeys: nil
      ).first
    else { return nil }
    let taken = FileManager.default.temporaryDirectory
      .appendingPathComponent("\(token).pdf")
    try? FileManager.default.removeItem(at: taken)
    guard (try? FileManager.default.moveItem(at: shared, to: taken)) != nil else { return nil }
    return ["path": taken.path, "name": shared.lastPathComponent]
  }
}
