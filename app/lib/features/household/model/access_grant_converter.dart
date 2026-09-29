import 'package:json_annotation/json_annotation.dart';

import 'access_grant.dart';

/// A profile's grant (household ADR-0003), absent on every family profile and
/// on every profile written before the field existed — both read as no grant
/// rather than as a failure (`BE-10`).
class AccessGrantConverter implements JsonConverter<AccessGrant?, Object?> {
  const AccessGrantConverter();

  @override
  AccessGrant? fromJson(Object? json) => AccessGrant.fromJson(json);

  @override
  Object? toJson(AccessGrant? value) => value?.toJson();
}

/// The household's uid → grant map, which only Functions write and every rule
/// reads. An entry that is not a grant is skipped rather than failing the
/// household listener every screen waits on.
class GrantsByUidConverter
    implements JsonConverter<Map<String, AccessGrant>, Object?> {
  const GrantsByUidConverter();

  @override
  Map<String, AccessGrant> fromJson(Object? json) {
    if (json is! Map) return const {};
    return {
      for (final MapEntry(:key, :value) in json.entries)
        if (key is String) key: ?AccessGrant.fromJson(value),
    };
  }

  @override
  Object toJson(Map<String, AccessGrant> value) => {
    for (final MapEntry(:key, :value) in value.entries) key: value.toJson(),
  };
}
