import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../design/tokens/nest_member_palette.dart';
import '../../household/model/member_color_converter.dart';

part 'co_parent_home.freezed.dart';
part 'co_parent_home.g.dart';

/// How one home is shown to both: the name and colour its own admin chose —
/// *Mum's home* in coral (household ADR-0004). It is all the other home
/// learns about the household behind it.
@freezed
abstract class CoParentHome with _$CoParentHome {
  const factory CoParentHome({
    required String name,
    @MemberColorConverter() required MemberColor color,
  }) = _CoParentHome;

  factory CoParentHome.fromJson(Map<String, Object?> json) =>
      _$CoParentHomeFromJson(json);

  /// The longest name a home may have; the server refuses longer.
  static const maxNameLength = 40;
}

/// Both homes of a link, by side.
@freezed
abstract class CoParentHomes with _$CoParentHomes {
  const factory CoParentHomes({
    required CoParentHome a,
    required CoParentHome b,
  }) = _CoParentHomes;

  factory CoParentHomes.fromJson(Map<String, Object?> json) =>
      _$CoParentHomesFromJson(json);
}
