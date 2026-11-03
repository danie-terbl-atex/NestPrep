import UIKit

struct BatteryReading: Equatable {
  let percent: Int?
  let charging: Bool

  init(level: Float, state: UIDevice.BatteryState) {
    percent = level < 0 ? nil : min(100, max(0, Int((level * 100).rounded())))
    charging = state == .charging || state == .full
  }

  static func current() -> BatteryReading {
    let device = UIDevice.current
    device.isBatteryMonitoringEnabled = true
    return BatteryReading(level: device.batteryLevel, state: device.batteryState)
  }
}
