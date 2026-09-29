import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';

part 'pickup_person.freezed.dart';
part 'pickup_person.g.dart';

/// An adult a parent has said may collect a child, at
/// `households/{id}/nannyPickupPeople/{id}` (nanny-hub ADR-0005): their name,
/// who they are to the family, how a carer at the door knows it is them, and
/// the children they may take.
///
/// Only family writes one. A child nobody is listed for is a child nobody is
/// released to — the carer is told so, not shown an empty list.
@freezed
abstract class PickupPerson with _$PickupPerson {
  const factory PickupPerson({
    @JsonKey(includeToJson: false) required String id,
    required String name,

    /// "Gogo", "Uncle Thabo", "Lebo's mom".
    required String relationship,

    /// How to be sure at the door: "Shows her ID; drives a white Polo".
    String? idNote,
    String? phone,
    String? photoId,
    @Default(<String>[]) List<String> childIds,
    required String createdBy,
    @ServerTimestampConverter() DateTime? createdAt,
  }) = _PickupPerson;

  const PickupPerson._();

  factory PickupPerson.fromJson(Map<String, Object?> json) =>
      _$PickupPersonFromJson(json);

  bool mayCollect(String childId) => childIds.contains(childId);

  /// What the phone dials, when there is a number.
  Uri? get dialLink {
    final number = phone?.replaceAll(RegExp('[^+0-9]'), '');
    return number == null || number.isEmpty
        ? null
        : Uri(scheme: 'tel', path: number);
  }
}
