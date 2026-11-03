import BackgroundTasks

enum LeaseRefresh {
  static let identifier = "io.nullstate.nestprep.location.refresh"
  static let interval: TimeInterval = 60 * 60

  static func register(_ run: @escaping (_ finish: @escaping (Bool) -> Void) -> Void) {
    _ = BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: .main) { task in
      var finished = false
      let finish = { (success: Bool) in
        guard !finished else { return }
        finished = true
        task.setTaskCompleted(success: success)
      }
      task.expirationHandler = { finish(false) }
      run(finish)
    }
  }

  static func schedule() {
    let request = BGAppRefreshTaskRequest(identifier: identifier)
    request.earliestBeginDate = Date(timeIntervalSinceNow: interval)
    try? BGTaskScheduler.shared.submit(request)
  }

  static func cancel() {
    BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
  }
}
