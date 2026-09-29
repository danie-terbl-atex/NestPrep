import 'access_level.dart';
import 'household_area.dart';

/// One level per area: what a kid, helper or carer may use (household
/// ADR-0003). Immutable; a change is a new grant.
final class AccessGrant {
  AccessGrant(Map<HouseholdArea, AccessLevel> levels)
    : _levels = Map.unmodifiable({
        for (final area in HouseholdArea.values)
          area: area.accept(levels[area] ?? AccessLevel.none),
      });

  /// Every area at one level (narrowed to what each area accepts).
  factory AccessGrant.uniform(AccessLevel level) =>
      AccessGrant({for (final area in HouseholdArea.values) area: level});

  /// A stored grant, read the way the rules read it: an unknown area is
  /// dropped, a missing area is `none`, and a level an area does not accept is
  /// `none`. Anything that is not a map is no grant at all (`BE-10`).
  static AccessGrant? fromJson(Object? json) {
    if (json is! Map) return null;
    final levels = <HouseholdArea, AccessLevel>{};
    for (final MapEntry(:key, :value) in json.entries) {
      final area = key is String ? HouseholdArea.fromKey(key) : null;
      if (area != null) levels[area] = AccessLevel.fromName(value);
    }
    return AccessGrant(levels);
  }

  final Map<HouseholdArea, AccessLevel> _levels;

  AccessLevel levelIn(HouseholdArea area) => _levels[area] ?? AccessLevel.none;

  AccessGrant withLevel(HouseholdArea area, AccessLevel level) =>
      AccessGrant({..._levels, area: level});

  /// The areas this grant opens at all, in the order they are listed.
  List<HouseholdArea> get openAreas => [
    for (final area in HouseholdArea.values)
      if (levelIn(area).isAnything) area,
  ];

  /// Every area, named — what the callable and the rules expect.
  Map<String, String> toJson() => {
    for (final area in HouseholdArea.values) area.key: levelIn(area).name,
  };

  @override
  bool operator ==(Object other) =>
      other is AccessGrant &&
      HouseholdArea.values.every(
        (area) => other.levelIn(area) == levelIn(area),
      );

  @override
  int get hashCode =>
      Object.hashAll([for (final area in HouseholdArea.values) levelIn(area)]);

  @override
  String toString() => 'AccessGrant(${toJson()})';
}
