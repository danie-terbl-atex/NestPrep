import FirebaseAppCheck
import FirebaseCore

final class LocationAppCheck: NSObject, AppCheckProviderFactory {
  private let appName: String
  private let enabled: Bool

  init(appName: String, enabled: Bool) {
    self.appName = appName
    self.enabled = enabled
  }

  func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
    guard enabled, app.name == appName else { return nil }
    #if DEBUG
      return AppCheckDebugProvider(app: app)
    #else
      return AppAttestProvider(app: app) ?? DeviceCheckProvider(app: app)
    #endif
  }
}
