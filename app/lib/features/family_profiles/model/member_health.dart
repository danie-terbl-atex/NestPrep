import 'package:freezed_annotation/freezed_annotation.dart';

import 'medication.dart';
import 'readable_json.dart';

part 'member_health.freezed.dart';
part 'member_health.g.dart';

/// A member's medication, at `households/{id}/memberHealth/{memberId}`.
///
/// Its own document because Security Rules can only hide whole documents: an
/// admin, a `member` and the person themselves read it; a helper does not,
/// until household phase 2 grants it (family-profiles ADR-0001). Medications
/// are keyed by a generated id and written one at a time, so two parents
/// editing two medicines never overwrite each other.
@freezed
abstract class MemberHealth with _$MemberHealth {
  const factory MemberHealth({
    @JsonKey(includeToJson: false) required String id,
    @Default(<String, Medication>{}) Map<String, Medication> medications,
  }) = _MemberHealth;

  const MemberHealth._();

  /// Reads a stored document forgivingly — a malformed medicine is shown
  /// under its id rather than failing the profile (`readableHealthJson`).
  factory MemberHealth.fromJson(Map<String, Object?> json) =>
      _$MemberHealthFromJson(readableHealthJson(json));

  factory MemberHealth.empty(String memberId) => MemberHealth(id: memberId);

  /// As many medicines as the rules keep for one person.
  static const medicationLimit = 12;

  bool get canAddMedication => medications.length < medicationLimit;

  /// The medicines in the order they are given through the day, each with the
  /// id it is edited by.
  List<({String id, Medication medication})> get inOrderOfTheDay =>
      [
        for (final MapEntry(:key, :value) in medications.entries)
          (id: key, medication: value),
      ]..sort((a, b) {
        final byTime = a.medication.firstTime.compareTo(b.medication.firstTime);
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });
}
