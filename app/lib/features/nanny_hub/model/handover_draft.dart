import 'package:flutter/foundation.dart';

import 'handover_kind.dart';
import 'handover_mood.dart';

/// A handover entry as the log sheet hands it over, before it has an id or a
/// photo in Storage. [photoId] is set once the photo is stored — the entry is
/// only written after its photo exists, so no entry ever points at nothing.
@immutable
class HandoverDraft {
  const HandoverDraft({
    required this.kind,
    required this.at,
    this.note,
    this.mood,
    this.childIds = const [],
    this.photoId,
  });

  final HandoverKind kind;
  final DateTime at;
  final String? note;
  final HandoverMood? mood;
  final List<String> childIds;
  final String? photoId;

  /// The rules refuse an entry that says nothing.
  bool get saysSomething => note != null || mood != null || photoId != null;

  HandoverDraft withPhoto(String? photoId) => HandoverDraft(
    kind: kind,
    at: at,
    note: note,
    mood: mood,
    childIds: childIds,
    photoId: photoId,
  );

  @override
  bool operator ==(Object other) =>
      other is HandoverDraft &&
      other.kind == kind &&
      other.at == at &&
      other.note == note &&
      other.mood == mood &&
      listEquals(other.childIds, childIds) &&
      other.photoId == photoId;

  @override
  int get hashCode =>
      Object.hash(kind, at, note, mood, Object.hashAll(childIds), photoId);
}
