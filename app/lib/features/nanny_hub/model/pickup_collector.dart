import 'package:flutter/foundation.dart';

/// Who collects on a run or a changed day: a listed pickup person, a
/// household member, or — only on a changed day — nobody (nanny-hub ADR-0005).
/// Stored as two flat ids, never a nested map, because Firestore never calls a
/// nested model's `toJson`.
@immutable
sealed class PickupCollector {
  const PickupCollector();

  /// A person id wins over a member id; the rules refuse a document with both.
  factory PickupCollector.from({String? personId, String? memberId}) =>
      personId != null
      ? CollectedByPerson(personId)
      : memberId != null
      ? CollectedByMember(memberId)
      : const NobodyCollects();

  String? get personId => null;
  String? get memberId => null;
}

final class CollectedByPerson extends PickupCollector {
  const CollectedByPerson(this.id);

  final String id;

  @override
  String get personId => id;

  @override
  bool operator ==(Object other) =>
      other is CollectedByPerson && other.id == id;

  @override
  int get hashCode => Object.hash(CollectedByPerson, id);
}

final class CollectedByMember extends PickupCollector {
  const CollectedByMember(this.id);

  final String id;

  @override
  String get memberId => id;

  @override
  bool operator ==(Object other) =>
      other is CollectedByMember && other.id == id;

  @override
  int get hashCode => Object.hash(CollectedByMember, id);
}

final class NobodyCollects extends PickupCollector {
  const NobodyCollects();

  @override
  bool operator ==(Object other) => other is NobodyCollects;

  @override
  int get hashCode => (NobodyCollects).hashCode;
}
