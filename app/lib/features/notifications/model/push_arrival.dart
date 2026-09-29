import 'package:flutter/foundation.dart';

import 'notification_vocabulary.dart';

/// Whether the phone lets this app notify, as the app reads it.
enum PushPermission {
  /// Not read yet.
  unknown,

  /// Never asked — the moment to ask is a person's tap, not a launch
  /// (notifications ADR-0003).
  notAsked,
  granted,

  /// Refused; only the phone's own settings can change it now.
  denied,
}

/// A push, as the app receives one: which household and inbox item it is,
/// and where tapping it lands (notifications ADR-0001). Built from the push's
/// data — ids and kinds only — and refused rather than guessed when that data
/// is not ours (`ENG-09`).
@immutable
final class PushArrival {
  const PushArrival({
    required this.householdId,
    required this.inboxId,
    required this.target,
    required this.targetId,
    this.title,
    this.body,
  });

  /// Null for a push that is not one of ours, or is missing what it needs.
  static PushArrival? fromData(
    Map<String, Object?> data, {
    String? title,
    String? body,
  }) {
    final householdId = data[PushDataKeys.householdId];
    final inboxId = data[PushDataKeys.inboxId];
    final target = data[PushDataKeys.target];
    final targetId = data[PushDataKeys.targetId];
    if (householdId is! String || householdId.isEmpty) return null;
    if (inboxId is! String || inboxId.isEmpty) return null;
    return PushArrival(
      householdId: householdId,
      inboxId: inboxId,
      target: target is String
          ? NotificationTarget.fromName(target)
          : NotificationTarget.inboxItem,
      targetId: targetId is String && targetId.isNotEmpty ? targetId : null,
      title: title,
      body: body,
    );
  }

  final String householdId;
  final String inboxId;
  final NotificationTarget target;
  final String? targetId;

  /// What the lock screen showed, for the banner while the app is open.
  final String? title;
  final String? body;
}
