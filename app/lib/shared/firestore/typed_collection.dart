import 'package:cloud_firestore/cloud_firestore.dart';

/// The one place a raw Firestore map becomes a model and back (`ENG-09`).
/// Nothing inward of a repository sees `Map<String, dynamic>`. The document id
/// is handed to `fromJson` under the key `id`; `toJson` must leave it out.
CollectionReference<T> typedCollection<T>(
  CollectionReference<Map<String, dynamic>> raw, {
  required T Function(Map<String, Object?> json) fromJson,
  required Map<String, Object?> Function(T value) toJson,
}) {
  return raw.withConverter<T>(
    fromFirestore: (snapshot, _) =>
        fromJson({...?snapshot.data(), 'id': snapshot.id}),
    toFirestore: (value, _) => toJson(value),
  );
}
