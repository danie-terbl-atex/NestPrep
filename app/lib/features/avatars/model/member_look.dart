import 'package:freezed_annotation/freezed_annotation.dart';

import 'avatar_base.dart';
import 'avatar_catalogue.g.dart';
import 'avatar_stage.dart';

part 'member_look.freezed.dart';

@freezed
abstract class MemberLook with _$MemberLook {
  const factory MemberLook({
    @Default(InitialBase()) AvatarBase base,
    @Default(AvatarStage.egg) int stage,
    @Default(<AvatarSlot, String>{}) Map<AvatarSlot, String> wear,
  }) = _MemberLook;

  const MemberLook._();

  static MemberLook? fromFirestore(Object? json) {
    if (json is! Map) return null;
    final base = json['base'];
    final stage = json['stage'];
    final wear = json['wear'];
    return MemberLook(
      base: AvatarBase.parse(base is String ? base : null),
      stage: stage is int ? AvatarStage.clamp(stage) : AvatarStage.egg,
      wear: wearFrom(wear),
    );
  }

  static Map<AvatarSlot, String> wearFrom(Object? json) {
    if (json is! Map) return const {};
    return {
      for (final slot in AvatarSlot.values)
        if (json[slot.name] case final String id when id.isNotEmpty) slot: id,
    };
  }

  String get signature => [
    base.stored,
    stage,
    for (final slot in AvatarSlot.values) wear[slot] ?? '',
  ].join('|');
}
