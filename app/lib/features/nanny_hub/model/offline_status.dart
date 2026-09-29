import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';

/// How ready the hub is to work without a signal (nanny-hub ADR-0007) — what
/// the "saved for offline" line on the emergency sheet and a child's card
/// says.
@immutable
sealed class OfflineStatus {
  const OfflineStatus();

  /// When the hub was last saved in full, if ever.
  DateTime? get savedAt;
}

/// Nothing saved on this phone yet.
final class NotSavedOffline extends OfflineStatus {
  const NotSavedOffline();

  @override
  DateTime? get savedAt => null;
}

/// Saving now, over whatever was saved before.
final class SavingOffline extends OfflineStatus {
  const SavingOffline({this.savedAt});

  @override
  final DateTime? savedAt;
}

final class SavedOffline extends OfflineStatus {
  const SavedOffline(this.savedAt);

  @override
  final DateTime savedAt;

  @override
  bool operator ==(Object other) =>
      other is SavedOffline && other.savedAt == savedAt;

  @override
  int get hashCode => savedAt.hashCode;
}

/// The last save did not finish — most often, no signal. What was saved
/// before, if anything, is still on the phone and still shown.
final class OfflineSaveFailed extends OfflineStatus {
  const OfflineSaveFailed(this.failure, {this.savedAt});

  final AppFailure failure;

  @override
  final DateTime? savedAt;

  bool get isNoSignal => failure is UnavailableFailure;
}
