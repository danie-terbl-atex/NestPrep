import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';

part 'grocery_plan_settings.freezed.dart';
part 'grocery_plan_settings.g.dart';

/// How the household wants the week's plans to reach its list, at
/// `households/{id}/grocerySettings/plans` (groceries ADR-0002). One per
/// household; a household that never opened the sheet reads [empty].
@freezed
abstract class GroceryPlanSettings with _$GroceryPlanSettings {
  const factory GroceryPlanSettings({
    /// Add and take off proposed items as the plans change, without asking —
    /// never touching what a person typed or ticked. Off until a parent turns
    /// it on.
    @Default(false) bool keepInStep,

    /// Normalised names marked *usually in the house*: never proposed. A skip
    /// list, not a re-add list — nothing is ever added from it.
    @Default(<String>[]) List<String> staples,

    /// The member who last changed either, so the sheet can say who.
    String? updatedBy,
    @ServerTimestampConverter() DateTime? updatedAt,
  }) = _GroceryPlanSettings;

  const GroceryPlanSettings._();

  factory GroceryPlanSettings.fromJson(Map<String, Object?> json) =>
      _$GroceryPlanSettingsFromJson(json);

  static const empty = GroceryPlanSettings();

  /// The document's id under `grocerySettings`; the rules accept no other.
  static const documentId = 'plans';

  /// More names than a household keeps in the cupboard; the rules hold it too.
  static const stapleLimit = 200;

  bool isStaple(String key) => staples.contains(key);
}
