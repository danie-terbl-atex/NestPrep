import 'package:freezed_annotation/freezed_annotation.dart';

import 'avatar_base.dart';
import 'avatar_catalogue.g.dart';
import 'avatar_stage.dart';
import 'member_look.dart';

part 'avatar_choice.freezed.dart';

@freezed
abstract class AvatarChoice with _$AvatarChoice {
  const factory AvatarChoice({
    @Default(InitialBase()) AvatarBase base,
    int? stage,
    @Default(<AvatarSlot, String>{}) Map<AvatarSlot, String> wear,
  }) = _AvatarChoice;

  const AvatarChoice._();

  static AvatarChoice? fromFirestore(Object? json) {
    if (json is! Map) return null;
    final base = json['base'];
    final stage = json['stage'];
    return AvatarChoice(
      base: AvatarBase.parse(base is String ? base : null),
      stage: stage is int ? AvatarStage.clamp(stage) : null,
      wear: MemberLook.wearFrom(json['wear']),
    );
  }

  Map<String, Object?> toFirestore() => {
    'base': base.stored,
    'stage': ?stage,
    'wear': {
      for (final MapEntry(key: slot, value: id) in wear.entries) slot.name: id,
    },
  };

  AvatarChoice wearing(AvatarSlot slot, String? accessoryId) => copyWith(
    wear: {
      for (final MapEntry(:key, :value) in wear.entries)
        if (key != slot) key: value,
      slot: ?accessoryId,
    },
  );

  AvatarChoice onBase(AvatarBase next) =>
      copyWith(base: next, wear: _wornOn(next));

  MemberLook lookFor({required int stage}) =>
      MemberLook(base: base, stage: stage, wear: _wornOn(base));

  Map<AvatarSlot, String> _wornOn(AvatarBase base) => base is PresetBase
      ? wear
      : {
          for (final MapEntry(:key, :value) in wear.entries)
            if (key != AvatarSlot.face) key: value,
        };
}
