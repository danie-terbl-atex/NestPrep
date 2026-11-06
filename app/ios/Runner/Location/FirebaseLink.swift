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

  private var app: FirebaseApp?
  private var auth: Auth?
  private var firestore: Firestore?
  private var listener: AuthStateDidChangeListenerHandle?
  private var mirroring = false

  func signedInUid() -> String? {
    guard FirebaseApp.app() != nil else { return nil }
    return Auth.auth().currentUser?.uid
  }

  func session(_ config: EngineConfig, uid: String?, changed: @escaping () -> Void) -> Session {
    guard let auth = connect(config) else { return .waiting }
    if listener == nil {
      listener = auth.addStateDidChangeListener { _, _ in changed() }
    }
    guard FirebaseApp.app() != nil else {
      // Without a Flutter engine nothing configures the default app, and configuring it here would cost the
      // app its App Check; the user this app copied last time stands in until Flutter starts.
      guard let own = auth.currentUser, uid == nil || own.uid == uid else { return .waiting }
      return open(config)
    }
    guard let user = Auth.auth().currentUser else {
      // Auth's keychain item is AfterFirstUnlock, so a locked phone still reads the user; before the first
      // unlock it reads as nobody.
      return UIApplication.shared.isProtectedDataAvailable ? .signedOut : .waiting
    }
    guard uid == nil || user.uid == uid else { return .signedOut }
    if auth.currentUser?.uid == user.uid { return open(config) }
    guard !mirroring else { return .waiting }
    mirroring = true
    auth.updateCurrentUser(user) { [weak self] error in
      self?.mirroring = false
      if error == nil { changed() }
    }
    return .waiting
  }

  func current(_ config: EngineConfig) -> Firestore? {
    if let firestore { return firestore }
    guard connect(config)?.currentUser != nil, let app else { return nil }
    return make(app, config)
  }

  func signOut() {
    try? auth?.signOut()
  }

  private func open(_ config: EngineConfig) -> Session {
    if let firestore { return .ready(firestore) }
    guard let app else { return .waiting }
    return .ready(make(app, config))
  }

  // Firestore reads its user once, when the instance is made, and queues writes per user. Made before Auth
  // has restored the signed-in user, it starts as nobody, and a write sent then waits in nobody's queue for
  // ever once the real user arrives.
  private func make(_ app: FirebaseApp, _ config: EngineConfig) -> Firestore {
    let firestore = Firestore.firestore(app: app)
    let settings = firestore.settings
    // The trail buffer is the durable queue; a disk cache would replay unacknowledged writes on relaunch
    // beside the engine's own retry, and the second would trip the server's pace rules.
    settings.cacheSettings = MemoryCacheSettings()
    if let host = config.emulatorHost {
      // `useEmulator` moves only the host and leaves TLS on, which the emulator does not speak.
      settings.host = "\(host):\(config.firestorePort ?? 8080)"
      settings.isSSLEnabled = false
    }
    firestore.settings = settings
    self.firestore = firestore
    return firestore
  }

  private func connect(_ config: EngineConfig) -> Auth? {
    if let auth { return auth }
    if FirebaseApp.app(name: Self.appName) == nil {
      guard let options = FirebaseOptions.defaultOptions() else { return nil }
      // App Check has one global factory, read as each app is configured. This one answers only for the
      // engine's app, and FlutterFire installs its own when its plugin registers.
      AppCheck.setAppCheckProviderFactory(LocationAppCheck(appName: Self.appName, enabled: config.emulatorHost == nil))
      FirebaseApp.configure(name: Self.appName, options: options)
    }
    guard let app = FirebaseApp.app(name: Self.appName) else { return nil }
    let auth = Auth.auth(app: app)
    if let host = config.emulatorHost {
      auth.useEmulator(withHost: host, port: config.authPort ?? 9099)
    }
    self.app = app
    self.auth = auth
    return auth
  }
}
