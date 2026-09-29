import 'package:freezed_annotation/freezed_annotation.dart';

part 'lunch_prep.freezed.dart';
part 'lunch_prep.g.dart';

/// What has been ticked off a week's Sunday prep list, at
/// `households/{id}/lunchPrep/{YYYY-Www}` (lunch-box ADR-0003). One per
/// household per week: the prep is the household's, not a child's.
@freezed
abstract class LunchPrep with _$LunchPrep {
  const factory LunchPrep({
    /// The week key — also the document id.
    @JsonKey(includeToJson: false) required String id,

    /// Item ids prepped already.
    @Default(<String>[]) List<String> done,
  }) = _LunchPrep;

  const LunchPrep._();

  factory LunchPrep.fromJson(Map<String, Object?> json) =>
      _$LunchPrepFromJson(json);

  factory LunchPrep.empty(String weekKey) => LunchPrep(id: weekKey);

  /// More than a week could list; the rules refuse past it.
  static const doneLimit = 200;

  bool isDone(String itemId) => done.contains(itemId);
}
