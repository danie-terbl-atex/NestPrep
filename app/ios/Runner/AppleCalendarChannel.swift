import EventKit
import Flutter
import UIKit

final class AppleCalendarChannel: NSObject {
  private var store = EKEventStore()
  private let queue = DispatchQueue(label: "io.nullstate.nestprep.apple-calendar", qos: .userInitiated)

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = AppleCalendarChannel()
    FlutterMethodChannel(name: "io.nullstate.nestprep/apple_calendar", binaryMessenger: messenger)
      .setMethodCallHandler { call, result in channel.handle(call, result: result) }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "access":
      result(Self.access())
    case "requestAccess":
      requestAccess(result: result)
    case "calendars":
      guard Self.access() == "granted" else { return result([]) }
      result(store.calendars(for: .event).map(Self.calendar))
    case "occurrences":
      occurrences(arguments, result: result)
    case "openSettings":
      if let settings = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(settings)
      }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func access() -> String {
    switch EKEventStore.authorizationStatus(for: .event) {
    case .notDetermined: return "notDetermined"
    case .restricted: return "restricted"
    case .denied: return "denied"
    case .authorized: return "granted"
    case .fullAccess: return "granted"
    case .writeOnly: return "denied"
    @unknown default: return "denied"
    }
  }

  private func requestAccess(result: @escaping FlutterResult) {
    let done: (Bool, Error?) -> Void = { [weak self] _, _ in
      DispatchQueue.main.async {
        // A store made before access was granted keeps seeing no calendars.
        self?.store = EKEventStore()
        result(Self.access())
      }
    }
    if #available(iOS 17.0, *) {
      store.requestFullAccessToEvents(completion: done)
    } else {
      store.requestAccess(to: .event, completion: done)
    }
  }

  private func occurrences(_ arguments: [String: Any], result: @escaping FlutterResult) {
    guard Self.access() == "granted",
      let ids = arguments["calendarIds"] as? [String],
      let from = (arguments["fromMs"] as? NSNumber)?.doubleValue,
      let to = (arguments["toMs"] as? NSNumber)?.doubleValue
    else { return result([]) }
    let store = self.store
    queue.async {
      let wanted = Set(ids)
      let calendars = store.calendars(for: .event).filter { wanted.contains($0.calendarIdentifier) }
      var found: [[String: Any]] = []
      if !calendars.isEmpty {
        let predicate = store.predicateForEvents(
          withStart: Date(timeIntervalSince1970: from / 1000),
          end: Date(timeIntervalSince1970: to / 1000),
          calendars: calendars
        )
        found = store.events(matching: predicate).compactMap(Self.occurrence)
      }
      DispatchQueue.main.async { result(found) }
    }
  }

  private static func calendar(_ calendar: EKCalendar) -> [String: Any] {
    [
      "id": calendar.calendarIdentifier,
      "title": calendar.title,
      "account": calendar.source?.title ?? "",
      "suggested": calendar.type != .birthday && calendar.type != .subscription,
    ]
  }

  private static func occurrence(_ event: EKEvent) -> [String: Any]? {
    if event.status == .canceled { return nil }
    if event.attendees?.first(where: { $0.isCurrentUser })?.participantStatus == .declined {
      return nil
    }
    guard let start = event.startDate, let end = event.endDate else { return nil }
    let occurrenceStart = event.occurrenceDate ?? start
    var fields: [String: Any] = [
      "id": "\(event.calendarItemIdentifier)@\(Int64(occurrenceStart.timeIntervalSince1970))",
      "title": event.title ?? "",
      "allDay": event.isAllDay,
    ]
    if event.isAllDay {
      var days = Calendar(identifier: .gregorian)
      days.timeZone = .current
      // An all-day end is the last second of its last day, or the next
      // midnight, depending on the account it came from.
      let lastInstant = end > start ? end.addingTimeInterval(-1) : start
      let lastDay = days.startOfDay(for: lastInstant)
      guard let afterLast = days.date(byAdding: .day, value: 1, to: lastDay) else { return nil }
      fields["startDate"] = dateString(days.startOfDay(for: start), in: days)
      fields["endDateExclusive"] = dateString(afterLast, in: days)
    } else {
      fields["start"] = Int64(start.timeIntervalSince1970 * 1000)
      fields["end"] = Int64(end.timeIntervalSince1970 * 1000)
    }
    return fields
  }

  private static func dateString(_ date: Date, in calendar: Calendar) -> String {
    let parts = calendar.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
  }
}
