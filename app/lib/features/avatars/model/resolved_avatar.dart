import 'package:flutter/foundation.dart';

import '../../../shared/time/calendar_date.dart';
import '../../household/model/birthday.dart';
import 'avatar_base.dart';
import 'avatar_catalogue.g.dart';
import 'avatar_face_anchor.dart';
import 'avatar_library.dart';
import 'avatar_moments.dart';
import 'member_look.dart';

@immutable
sealed class ResolvedBase {
  const ResolvedBase();
}

final class ResolvedInitial extends ResolvedBase {
  const ResolvedInitial();
}

final class ResolvedPreset extends ResolvedBase {
  const ResolvedPreset(this.assetId);

  final String assetId;

  AvatarFace? get face => avatarFaceAnchorOf(assetId);
}

final class ResolvedImage extends ResolvedBase {
  const ResolvedImage(this.hash);

  final String hash;
}

@immutable
final class ResolvedAvatar {
  const ResolvedAvatar({required this.base, required this.layers});

  static const initial = ResolvedAvatar(
    base: ResolvedInitial(),
    layers: <AvatarSlot, String>{},
  );

  factory ResolvedAvatar.of(
    MemberLook? look, {
    required CalendarDate today,
    required AvatarHemisphere hemisphere,
    Birthday? birthday,
    AvatarLibrary? library,
  }) {
    if (look == null) return initial;
    final known = library ?? AvatarLibrary.bundled;
    final base = switch (look.base) {
      PresetBase(:final name) when known.nestling(name) != null =>
        ResolvedPreset(nestlingAssetId(name, look.stage)),
      ImageBase(:final hash) => ResolvedImage(hash),
      _ => const ResolvedInitial(),
    };
    final hasFace = base is ResolvedPreset && base.face != null;
    final wear = {
      for (final MapEntry(key: slot, value: id) in look.wear.entries)
        if (known.accessory(id)?.slot == slot &&
            (hasFace || slot != AvatarSlot.face))
          slot: id,
    };
    final moments = avatarMomentsOn(
      today: today,
      hemisphere: hemisphere,
      birthday: birthday,
      wear: wear,
      moments: known.moments,
    );
    return ResolvedAvatar(
      base: base,
      layers: {
        for (final slot in AvatarSlot.values)
          if (moments[slot] ?? wear[slot] case final id?
              when hasFace || slot != AvatarSlot.face)
            slot: id,
      },
    );
  }

  final ResolvedBase base;
  final Map<AvatarSlot, String> layers;

  bool get isInitialOnly => base is ResolvedInitial && layers.isEmpty;

  String get signature => [
    switch (base) {
      ResolvedInitial() => InitialBase.value,
      ResolvedPreset(:final assetId) => assetId,
      ResolvedImage(:final hash) => '${ImageBase.prefix}$hash',
    },
    for (final slot in AvatarSlot.values) layers[slot] ?? '',
  ].join('|');

  @override
  bool operator ==(Object other) =>
      other is ResolvedAvatar && other.signature == signature;

  @override
  int get hashCode => signature.hashCode;
}
