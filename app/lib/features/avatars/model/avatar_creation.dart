import 'package:flutter/foundation.dart';

import 'avatar_base.dart';

enum CreationRecipe { drawing, buddy, pet, portrait }

enum CreationStyle { plush, clay, knitted, wooden, vinyl, sticker }

enum CreationStatus { checking, drawing, ready, refused, failed }

enum CreationRefusal {
  notAllowed,
  creationsOff,
  limitReached,
  premiumRequired,
  unavailable,
  declined,
}

@immutable
final class AvatarCreation {
  const AvatarCreation({
    required this.id,
    required this.memberId,
    required this.recipe,
    this.status,
    this.reason,
    this.imageHash,
    this.keepsakeId,
    this.left,
    this.requestedAt,
  });

  static AvatarCreation? fromFirestore(String id, Map<String, Object?> json) {
    final recipe = _named(CreationRecipe.values, json['recipe']);
    final memberId = json['memberId'];
    if (recipe == null || memberId is! String) return null;
    final hash = json['imageHash'];
    final keepsake = json['keepsakeId'];
    final left = json['left'];
    final status = _named(CreationStatus.values, json['status']);
    return AvatarCreation(
      id: id,
      memberId: memberId,
      recipe: recipe,
      status: status,
      reason:
          _named(CreationRefusal.values, json['reason']) ??
          switch (status) {
            CreationStatus.refused => CreationRefusal.notAllowed,
            CreationStatus.failed => CreationRefusal.unavailable,
            _ => null,
          },
      imageHash: hash is String && AvatarBase.isImageHash(hash) ? hash : null,
      keepsakeId: keepsake is String ? keepsake : null,
      left: left is int ? left : null,
      requestedAt: switch (json['requestedAt']) {
        final DateTime at => at,
        _ => null,
      },
    );
  }

  static T? _named<T extends Enum>(List<T> values, Object? name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }

  final String id;
  final String memberId;
  final CreationRecipe recipe;
  final CreationStatus? status;
  final CreationRefusal? reason;
  final String? imageHash;
  final String? keepsakeId;
  final int? left;
  final DateTime? requestedAt;

  bool get isReady => status == CreationStatus.ready && imageHash != null;

  bool get isSettled =>
      status == CreationStatus.refused ||
      status == CreationStatus.failed ||
      isReady;
}
