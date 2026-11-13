import 'dart:math' as math;

import '../../chore_points/model/point_balance.dart';
import '../../household/model/member.dart';
import '../../household/model/member_role.dart';
import 'avatar_base.dart';
import 'avatar_catalogue.g.dart';
import 'avatar_choice.dart';
import 'avatar_face_anchor.dart';
import 'avatar_library.dart';
import 'avatar_stage.dart';
import 'member_avatar_record.dart';
import 'member_look.dart';

final class AvatarStudio {
  AvatarStudio({
    required this.member,
    required this.record,
    required this.choice,
    required this.shopIsOpen,
    required this.library,
    this.creationsOn = true,
    this.timeZone = 'UTC',
    this.balance,
    this.offeredPhoto,
  });

  static const grownUpStage = AvatarStage.flyer;

  final Member member;
  final MemberAvatarRecord record;
  final AvatarChoice choice;
  final bool shopIsOpen;
  final bool creationsOn;
  final String timeZone;
  final AvatarLibrary library;
  final PointBalance? balance;
  final String? offeredPhoto;

  bool get isKid => member.role == MemberRole.kid;

  int get stars => balance?.balance ?? 0;

  late final int stage = isKid
      ? math.max(
          member.look?.stage ?? AvatarStage.egg,
          AvatarStage.forStars(
            earned: balance?.earned ?? 0,
            bestStreak: balance?.bestStreak ?? 0,
          ),
        )
      : choice.stage ?? member.look?.stage ?? grownUpStage;

  late final StageProgress progress = StageProgress.of(
    stage: stage,
    earned: balance?.earned ?? 0,
    bestStreak: balance?.bestStreak ?? 0,
  );

  late final MemberLook preview = switch (offeredPhoto) {
    final hash? => choice.copyWith(base: ImageBase(hash)).lookFor(stage: stage),
    null => choice.lookFor(stage: stage),
  };

  bool get hasFace => switch (preview.base) {
    PresetBase(:final name) =>
      avatarFaceAnchorOf(nestlingAssetId(name, stage)) != null,
    _ => false,
  };

  bool get usesInitial => preview.base is InitialBase;

  String? nestlingName() => switch (preview.base) {
    PresetBase(:final name) => name,
    _ => null,
  };

  String? wornOn(AvatarSlot slot) => preview.wear[slot];

  bool wears(String hash) => switch (preview.base) {
    ImageBase(hash: final worn) => worn == hash,
    _ => false,
  };

  bool canWear(AvatarAccessory accessory) =>
      !isKid || accessory.isFree || record.owns(accessory.id);

  bool get showsShop => isKid && shopIsOpen;
}
