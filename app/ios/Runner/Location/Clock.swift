import Foundation

protocol Clock {
  var now: Date { get }
}

struct SystemClock: Clock {
  var now: Date { Date() }
}

final class Alarm {
  private var item: DispatchWorkItem?

  func set(at date: Date, now: Date, _ action: @escaping () -> Void) {
    cancel()
    let item = DispatchWorkItem(block: action)
    self.item = item
    DispatchQueue.main.asyncAfter(deadline: .now() + max(0, date.timeIntervalSince(now)), execute: item)
  }

  func cancel() {
    item?.cancel()
    item = nil
  }
}

final class Once {
  private var action: (() -> Void)?

  init(_ action: @escaping () -> Void) {
    self.action = action
  }

  func run() {
    let action = self.action
    self.action = nil
    action?()
  }
}
