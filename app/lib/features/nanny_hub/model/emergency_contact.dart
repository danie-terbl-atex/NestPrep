import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';
import 'contact_kind.dart';

part 'emergency_contact.freezed.dart';
part 'emergency_contact.g.dart';

/// Somebody a carer may need to call, at `households/{id}/nannyContacts/{id}`
/// — a parent, a grandparent down the road, the doctor, the hospital.
///
/// One document each, so two parents adding two numbers never overwrite each
/// other. These are people who are not users of the app; their numbers are
/// read only by whoever the `nannyHub` grant opens (nanny-hub ADR-0003).
@freezed
abstract class EmergencyContact with _$EmergencyContact {
  const factory EmergencyContact({
    @JsonKey(includeToJson: false) required String id,
    required String name,
    @JsonKey(unknownEnumValue: ContactKind.other) required ContactKind kind,
    required String phone,

    /// "Lives two streets away", "ask for Sister Dlamini".
    String? note,
    required String createdBy,
    @ServerTimestampConverter() DateTime? createdAt,
  }) = _EmergencyContact;

  const EmergencyContact._();

  factory EmergencyContact.fromJson(Map<String, Object?> json) =>
      _$EmergencyContactFromJson(json);

  /// What the phone dials: the digits and a leading plus, nothing a person
  /// typed to make it readable.
  Uri get dialLink => Uri(scheme: 'tel', path: dialable(phone));

  static String dialable(String phone) =>
      phone.replaceAll(RegExp('[^+0-9]'), '');

  /// Parents first, the hospital last, and by name within each.
  static int bySheetOrder(EmergencyContact a, EmergencyContact b) {
    final byKind = a.kind.index.compareTo(b.kind.index);
    return byKind != 0 ? byKind : a.name.compareTo(b.name);
  }
}
