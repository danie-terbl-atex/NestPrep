import 'package:flutter/foundation.dart';

import 'avatar_catalogue.g.dart';

@immutable
final class AvatarBuddy {
  const AvatarBuddy([this.picks = const {}]);

  static AvatarBuddy? fromFirestore(Object? json) {
    if (json is! Map) return null;
    final picks = {
      for (final kind in AvatarBuddyKind.values)
        if (json[kind.name] case final String id when wordOf(kind, id) != null)
          kind: id,
    };
    return picks.isEmpty ? null : AvatarBuddy(picks);
  }

  static AvatarChoiceWord? wordOf(AvatarBuddyKind kind, String? id) {
    if (id == null) return null;
    for (final word in avatarBuddy[kind] ?? const <AvatarChoiceWord>[]) {
      if (word.id == id) return word;
    }
    return null;
  }

  final Map<AvatarBuddyKind, String> picks;

  bool get isComplete => AvatarBuddyKind.values.every(picks.containsKey);

  bool get isEmpty => picks.isEmpty;

  AvatarChoiceWord? word(AvatarBuddyKind kind) => wordOf(kind, picks[kind]);

  AvatarBuddy picking(AvatarBuddyKind kind, String id) =>
      AvatarBuddy({...picks, kind: id});

  Map<String, Object?> toFirestore() => {
    for (final MapEntry(key: kind, value: id) in picks.entries) kind.name: id,
  };

  @override
  bool operator ==(Object other) =>
      other is AvatarBuddy && mapEquals(other.picks, picks);

  @override
  int get hashCode => Object.hashAllUnordered(
    picks.entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}
