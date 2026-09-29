import '../model/inbox_item.dart';
import '../model/notification_settings.dart';

/// A person's inbox and their choices, as Firestore holds them (notifications
/// ADR-0001, ADR-0003).
///
/// The inbox is written by Functions only: the app reads a person's own
/// items, marks one read and clears one — the rules refuse anything else, and
/// refuse everybody else's. Settings are a person's own, or a kid's for
/// family.
abstract interface class NotificationRepository {
  /// One person's notifications, newest first.
  Stream<List<InboxItem>> watchInbox(String householdId, String memberId);

  /// How many of them are unread — the bell's dot.
  Stream<int> watchUnreadCount(String householdId, String memberId);

  /// One notification, or null once it has been cleared.
  Stream<InboxItem?> watchItem(String householdId, String itemId);

  Future<void> markRead(String householdId, String itemId);

  Future<void> clear(String householdId, String itemId);

  /// A person's choices, or null before they have made any.
  Stream<NotificationSettings?> watchSettings(
    String householdId,
    String memberId,
  );

  Future<void> saveSettings(String householdId, NotificationSettings settings);

  /// Bounds every read that could grow (`BE-08`).
  static const inboxLimit = 50;
  static const unreadLimit = 20;
}
