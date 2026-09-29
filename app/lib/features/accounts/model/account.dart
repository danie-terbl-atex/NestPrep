import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';
import '../../legal/model/legal_versions.dart';
import 'legal_consent.dart';

part 'account.freezed.dart';
part 'account.g.dart';

/// The account document at `users/{uid}` (accounts ADR-0001): what this Google
/// identity is called, which households it belongs to, and which one the app is
/// currently showing.
///
/// `householdIds` is written only by Cloud Functions — creating a household,
/// redeeming an invite, leaving one (household ADR-0002). The client may change
/// only `activeHouseholdId`, and only to a household already in the list; the
/// rules enforce both.
@freezed
abstract class Account with _$Account {
  const factory Account({
    @JsonKey(includeToJson: false) required String id,
    required String displayName,
    String? photoUrl,
    @Default(<String>[]) List<String> householdIds,
    String? activeHouseholdId,
    @ServerTimestampConverter() DateTime? createdAt,
    @ServerTimestampConverter() DateTime? lastSignedInAt,

    /// What this person agreed to (accounts ADR-0005). Read here, never
    /// written with the rest of the document: the create rule does not allow
    /// it, and `acceptLegal` writes it on its own with the server's time.
    @JsonKey(includeToJson: false) LegalConsent? legalConsent,
  }) = _Account;

  const Account._();

  factory Account.fromJson(Map<String, Object?> json) =>
      _$AccountFromJson(json);

  bool get belongsToAHousehold => householdIds.isNotEmpty;

  /// Whether this person has agreed to the documents this build ships. The
  /// router asks for consent until they have (accounts ADR-0005).
  bool get hasAcceptedCurrentLegal =>
      legalConsent?.covers(
        terms: LegalVersions.terms,
        privacy: LegalVersions.privacy,
      ) ??
      false;

  /// Whether this person agreed to an earlier version — the consent screen
  /// says "we have updated" rather than "before you start".
  bool get hasAcceptedEarlierLegal => legalConsent != null;

  /// The household the app should show: the chosen one while it is still one of
  /// ours, otherwise the first we belong to. A stale `activeHouseholdId` — the
  /// household was left on another device — must not leave the app pointing at
  /// a household this account can no longer read.
  String? get householdToShow {
    final active = activeHouseholdId;
    if (active != null && householdIds.contains(active)) return active;
    return householdIds.isEmpty ? null : householdIds.first;
  }
}
