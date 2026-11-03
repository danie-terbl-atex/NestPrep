import Flutter
import UIKit

final class LocationChannel: NSObject, FlutterStreamHandler {
  private let engine: LocationEngine
  private var sink: FlutterEventSink?

  private init(engine: LocationEngine) {
    self.engine = engine
  }

  static func register(_ engine: LocationEngine, messenger: FlutterBinaryMessenger) {
    let channel = LocationChannel(engine: engine)
    FlutterMethodChannel(name: "io.nullstate.nestprep/location", binaryMessenger: messenger)
      .setMethodCallHandler(channel.handle)
    FlutterEventChannel(name: "io.nullstate.nestprep/location/events", binaryMessenger: messenger)
      .setStreamHandler(channel)
    engine.onEvent = { [weak channel] event in channel?.sink?(event) }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "start":
      start(call.arguments, result: result)
    case "stop":
      engine.stop { result(nil) }
    case "status":
      result(engine.status)
    case "setForeground":
      engine.setForeground(arguments["foreground"] as? Bool ?? false)
      result(nil)
    case "setPlaces":
      engine.setPlaces(FamilyPlace.list(from: arguments["places"]))
      result(nil)
    case "permissions":
      engine.permissions.current { result($0) }
    case "requestAlways":
      engine.permissions.requestAlways { result($0) }
    case "requestMotion":
      engine.permissions.requestMotion { result($0) }
    case "openBatterySettings":
      if let settings = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(settings)
      }
      result(nil)
    case "reverseGeocode":
      guard let latitude = (arguments["latitude"] as? NSNumber)?.doubleValue,
        let longitude = (arguments["longitude"] as? NSNumber)?.doubleValue
      else { return result(nil) }
      AddressLookup.line(latitude: latitude, longitude: longitude) { result($0) }
    case "ready":
      engine.flutterStarted()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func start(_ arguments: Any?, result: FlutterResult) {
    guard let config = EngineConfig(arguments: arguments) else {
      return result(FlutterError(code: "badArguments", message: "start needs householdId, memberId and timeZone", details: nil))
    }
    do {
      try engine.start(config)
      result(nil)
    } catch StartRefusal.noBackground {
      result(FlutterError(code: "noBackground", message: "Location is allowed only while the app is in use", details: nil))
    } catch {
      result(FlutterError(code: "noPermission", message: "Location is not allowed", details: nil))
    }
  }
}
