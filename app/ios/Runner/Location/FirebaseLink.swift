import FirebaseAppCheck
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import UIKit

final class FirebaseLink {
  enum Session {
    case ready(Firestore)
    case waiting
    case signedOut
  }

  private static let appName = "nestprep-location"

  private(set) var firestore: Firestore?
  private var auth: Auth?
  private var mirroring = false

  func signedInUid() -> String? {
    guard FirebaseApp.app() != nil else { return nil }
    return Auth.auth().currentUser?.uid
  }

  func session(_ config: EngineConfig, uid: String?, changed: @escaping () -> Void) -> Session {
    guard let firestore = connect(config), let auth else { return .waiting }
    guard FirebaseApp.app() != nil else {
      // Without a Flutter engine nothing configures the default app, and configuring it here would cost the
      // app its App Check; the user this app copied last time stands in until Flutter starts.
      guard let own = auth.currentUser, uid == nil || own.uid == uid else { return .waiting }
      return .ready(firestore)
    }
    guard let user = Auth.auth().currentUser else {
      // Auth's keychain item is AfterFirstUnlock, so a locked phone still reads the user; before the first
      // unlock it reads as nobody.
      return UIApplication.shared.isProtectedDataAvailable ? .signedOut : .waiting
    }
    guard uid == nil || user.uid == uid else { return .signedOut }
    if auth.currentUser?.uid == user.uid { return .ready(firestore) }
    guard !mirroring else { return .waiting }
    mirroring = true
    auth.updateCurrentUser(user) { [weak self] error in
      self?.mirroring = false
      if error == nil { changed() }
    }
    return .waiting
  }

  func connect(_ config: EngineConfig) -> Firestore? {
    if let firestore { return firestore }
    if FirebaseApp.app(name: Self.appName) == nil {
      guard let options = FirebaseOptions.defaultOptions() else { return nil }
      // App Check has one global factory, read as each app is configured. This one answers only for the
      // engine's app, and FlutterFire installs its own when its plugin registers.
      AppCheck.setAppCheckProviderFactory(LocationAppCheck(appName: Self.appName, enabled: config.emulatorHost == nil))
      FirebaseApp.configure(name: Self.appName, options: options)
    }
    guard let app = FirebaseApp.app(name: Self.appName) else { return nil }
    let firestore = Firestore.firestore(app: app)
    let settings = firestore.settings
    // The trail buffer is the durable queue; a disk cache would replay unacknowledged writes on relaunch
    // beside the engine's own retry, and the second would trip the server's pace rules.
    settings.cacheSettings = MemoryCacheSettings()
    firestore.settings = settings
    let auth = Auth.auth(app: app)
    if let host = config.emulatorHost {
      firestore.useEmulator(withHost: host, port: config.firestorePort ?? 8080)
      auth.useEmulator(withHost: host, port: config.authPort ?? 9099)
    }
    self.firestore = firestore
    self.auth = auth
    return firestore
  }

  func signOut() {
    try? auth?.signOut()
  }
}
