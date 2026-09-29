import '../data/notification_repository.dart';
import '../model/notification_settings.dart';
import '../model/push_arrival.dart';
import 'push_registrar.dart';

/// Who is turning notifications on, and where.
final class NotificationsOwner {
  const NotificationsOwner({
    required this.householdId,
    required this.memberId,
    required this.isFamily,
  });

  final String householdId;
  final String memberId;
  final bool isFamily;
}

/// A person's tap on *Turn on notifications* (notifications ADR-0003): the
/// phone's own prompt, and — the first time the answer is yes — their
/// choices written with the defaults, so the digest job can find them. The
/// inbox's card and the settings screen both call this, so the first-time
/// rule is written once (`ENG-02`).
Future<PushPermission> turnOnNotifications({
  required PushRegistrar registrar,
  required NotificationRepository repository,
  required NotificationsOwner owner,
}) async {
  final answer = await registrar.turnOn();
  if (answer != PushPermission.granted || owner.memberId.isEmpty) {
    return answer;
  }
  final stored = await repository
      .watchSettings(owner.householdId, owner.memberId)
      .first;
  if (stored == null) {
    await repository.saveSettings(
      owner.householdId,
      NotificationSettings.firstTime(
        memberId: owner.memberId,
        updatedBy: owner.memberId,
        isFamily: owner.isFamily,
      ),
    );
  }
  return answer;
}
