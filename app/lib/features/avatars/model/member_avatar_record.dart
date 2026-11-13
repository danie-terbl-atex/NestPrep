import 'package:flutter/foundation.dart';

import 'avatar_base.dart';
import 'avatar_choice.dart';

@immutable
final class MemberAvatarRecord {
  const MemberAvatarRecord({
    this.choice,
    this.pendingPhoto,
    this.ownedAccessories = const {},
    this.ownedImages = const [],
  });

  factory MemberAvatarRecord.fromFirestore(Map<String, Object?> json) {
    final owned = json['owned'];
    final pending = json['pendingPhoto'];
    return MemberAvatarRecord(
      choice: AvatarChoice.fromFirestore(json['choice']),
      pendingPhoto: pending is String && AvatarBase.isImageHash(pending)
          ? pending
          : null,
      ownedAccessories: {
        if (owned is Map && owned['accessories'] is List)
          for (final id in owned['accessories'] as List)
            if (id is String) id,
      },
      ownedImages: [
        if (owned is Map && owned['images'] is List)
          for (final hash in owned['images'] as List)
            if (hash is String && AvatarBase.isImageHash(hash)) hash,
      ],
    );
  }

  static const none = MemberAvatarRecord();

  final AvatarChoice? choice;
  final String? pendingPhoto;
  final Set<String> ownedAccessories;
  final List<String> ownedImages;

  bool owns(String accessoryId) => ownedAccessories.contains(accessoryId);
}
