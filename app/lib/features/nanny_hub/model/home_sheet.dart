import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';

part 'home_sheet.freezed.dart';
part 'home_sheet.g.dart';

/// The home's own facts for the emergency sheet, in one document at
/// `households/{id}/nannyHome/sheet`: where the house is — what an ambulance
/// is told — and the medical aid a hospital asks for first.
@freezed
abstract class HomeSheet with _$HomeSheet {
  const factory HomeSheet({
    @JsonKey(includeToJson: false) @Default(HomeSheet.documentId) String id,
    String? address,
    String? medicalAidScheme,
    String? medicalAidPlan,
    String? medicalAidNumber,
    String? updatedBy,
    @ServerTimestampConverter() DateTime? updatedAt,
  }) = _HomeSheet;

  const HomeSheet._();

  factory HomeSheet.fromJson(Map<String, Object?> json) =>
      _$HomeSheetFromJson(json);

  /// The only id the rules accept for it.
  static const documentId = 'sheet';

  static const empty = HomeSheet();

  bool get hasMedicalAid =>
      medicalAidScheme != null ||
      medicalAidPlan != null ||
      medicalAidNumber != null;
}
