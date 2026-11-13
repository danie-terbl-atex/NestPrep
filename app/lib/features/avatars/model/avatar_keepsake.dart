import 'package:flutter/foundation.dart';

import 'avatar_base.dart';
import 'avatar_buddy.dart';
import 'avatar_creation.dart';

@immutable
final class AvatarKeepsake {
  const AvatarKeepsake({
    required this.id,
    required this.memberId,
    required this.recipe,
    required this.imageHash,
    this.style,
    this.originalPath,
    this.buddy,
    this.createdAt,
  });

  static AvatarKeepsake? fromFirestore(String id, Map<String, Object?> json) {
    final memberId = json['memberId'];
    final hash = json['imageHash'];
    final recipe = CreationRecipe.values
        .where((recipe) => recipe.name == json['recipe'])
        .firstOrNull;
    if (memberId is! String ||
        recipe == null ||
        hash is! String ||
        !AvatarBase.isImageHash(hash)) {
      return null;
    }
    final original = json['originalPath'];
    return AvatarKeepsake(
      id: id,
      memberId: memberId,
      recipe: recipe,
      imageHash: hash,
      style: CreationStyle.values
          .where((style) => style.name == json['style'])
          .firstOrNull,
      originalPath: original is String && original.isNotEmpty ? original : null,
      buddy: AvatarBuddy.fromFirestore(json['buddy']),
      createdAt: switch (json['createdAt']) {
        final DateTime at => at,
        _ => null,
      },
    );
  }

  final String id;
  final String memberId;
  final CreationRecipe recipe;
  final String imageHash;
  final CreationStyle? style;
  final String? originalPath;
  final AvatarBuddy? buddy;
  final DateTime? createdAt;

  bool get isPortrait => recipe == CreationRecipe.portrait;

  static int newestFirst(AvatarKeepsake a, AvatarKeepsake b) {
    final (at, bt) = (a.createdAt, b.createdAt);
    if (at == null && bt == null) return b.id.compareTo(a.id);
    if (at == null) return -1;
    if (bt == null) return 1;
    return bt.compareTo(at);
  }
}
