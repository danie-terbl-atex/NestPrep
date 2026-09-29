import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';
import 'care_routine.dart';

part 'child_card.freezed.dart';
part 'child_card.g.dart';

/// What a carer needs to know about one child that nobody else in the app
/// holds, at `households/{id}/nannyChildCards/{memberId}` (nanny-hub
/// ADR-0003): the routine, the comfort items, how to settle them.
///
/// **Allergies, medication and likes are not here.** They live in family
/// profiles and are read from there, so the lunch planner and the carer can
/// never disagree about an allergy (nanny-hub overview). The document id is
/// the child's member id, and a child with no document has
/// `ChildCard.empty`.
@freezed
abstract class ChildCard with _$ChildCard {
  const factory ChildCard({
    @JsonKey(includeToJson: false) required String id,
    @Default(<CareRoutine>[]) List<CareRoutine> routines,
    @Default(<String>[]) List<String> comfortItems,

    /// How to settle them when they are upset or will not sleep.
    String? settling,

    /// Anything else a carer should know: a fear of the dark, a word they use.
    String? goodToKnow,

    /// A photo of the child, by its Storage object name.
    String? photoId,
    String? updatedBy,
    @ServerTimestampConverter() DateTime? updatedAt,
  }) = _ChildCard;

  const ChildCard._();

  factory ChildCard.fromJson(Map<String, Object?> json) =>
      _$ChildCardFromJson(json);

  factory ChildCard.empty(String memberId) => ChildCard(id: memberId);

  bool get isEmpty =>
      routines.isEmpty &&
      comfortItems.isEmpty &&
      settling == null &&
      goodToKnow == null &&
      photoId == null;

  List<CareRoutine> get routinesInOrder =>
      CareRoutine.inOrderOfTheDay(routines);
}
