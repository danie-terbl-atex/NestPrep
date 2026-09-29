import 'package:flutter/foundation.dart';

import 'contact_kind.dart';

/// An emergency contact as the contact sheet hands it over, already trimmed
/// and checked against the rules' shape (`FE-10`).
@immutable
class ContactDraft {
  const ContactDraft({
    required this.name,
    required this.kind,
    required this.phone,
    this.note,
  });

  final String name;
  final ContactKind kind;
  final String phone;
  final String? note;

  @override
  bool operator ==(Object other) =>
      other is ContactDraft &&
      other.name == name &&
      other.kind == kind &&
      other.phone == phone &&
      other.note == note;

  @override
  int get hashCode => Object.hash(name, kind, phone, note);
}
