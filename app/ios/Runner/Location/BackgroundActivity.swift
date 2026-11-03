import UIKit

final class BackgroundActivity {
  private var task: UIBackgroundTaskIdentifier = .invalid

  func hold(_ busy: Bool) {
    if busy, task == .invalid {
      task = UIApplication.shared.beginBackgroundTask(withName: "NestPrepLocationWrite") { [weak self] in
        self?.hold(false)
      }
    } else if !busy, task != .invalid {
      UIApplication.shared.endBackgroundTask(task)
      task = .invalid
    }
  }
}
