import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../data/avatar_photo_store.dart';
import '../model/avatar_catalogue.g.dart';
import '../model/avatar_face_anchor.dart';
import '../model/resolved_avatar.dart';

class ResolvedMemberAvatar extends StatefulWidget {
  const ResolvedMemberAvatar({
    required this.name,
    required this.color,
    required this.avatar,
    required this.memberId,
    this.householdId,
    this.size = NestSize.avatarMedium,
    this.highlighted = false,
    super.key,
  });

  final String name;
  final MemberColor color;
  final ResolvedAvatar avatar;
  final String memberId;
  final String? householdId;
  final double size;
  final bool highlighted;

  static NestAvatarSlot slotOf(AvatarSlot slot) => switch (slot) {
    AvatarSlot.top => NestAvatarSlot.top,
    AvatarSlot.badge => NestAvatarSlot.badge,
    AvatarSlot.ring => NestAvatarSlot.ring,
    AvatarSlot.face => NestAvatarSlot.face,
  };

  @override
  State<ResolvedMemberAvatar> createState() => _ResolvedMemberAvatarState();
}

class _ResolvedMemberAvatarState extends State<ResolvedMemberAvatar> {
  String? _hash;
  Uint8List? _bytes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _follow();
  }

  @override
  void didUpdateWidget(ResolvedMemberAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _follow();
  }

  void _follow() {
    final base = widget.avatar.base;
    final householdId = widget.householdId;
    final hash = base is ResolvedImage && householdId != null
        ? base.hash
        : null;
    final isNew = hash != _hash;
    if (!isNew && (_bytes != null || hash == null)) return;
    _hash = hash;
    if (isNew) _bytes = null;
    if (hash == null || householdId == null) return;
    final store = context.read<AvatarPhotoStore?>();
    if (store == null) return;
    final kept = store.kept(
      householdId: householdId,
      memberId: widget.memberId,
      hash: hash,
    );
    if (kept != null) {
      _bytes = kept;
      return;
    }
    if (isNew) unawaited(_load(store, householdId, hash));
  }

  Future<void> _load(
    AvatarPhotoStore store,
    String householdId,
    String hash,
  ) async {
    final bytes = await store.read(
      householdId: householdId,
      memberId: widget.memberId,
      hash: hash,
    );
    if (!mounted || _hash != hash || bytes == null) return;
    setState(() => _bytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    final face = switch (widget.avatar.base) {
      final ResolvedPreset preset => preset.face,
      _ => null,
    };
    return NestAvatar(
      name: widget.name,
      color: widget.color,
      size: widget.size,
      isHighlighted: widget.highlighted,
      picture: switch (widget.avatar.base) {
        ResolvedPreset(:final assetId) => AssetImage(avatarAssetPath(assetId)),
        ResolvedImage() when bytes != null => MemoryImage(bytes),
        _ => null,
      },
      layers: [
        for (final MapEntry(key: slot, value: id)
            in widget.avatar.layers.entries)
          NestAvatarLayer(
            slot: ResolvedMemberAvatar.slotOf(slot),
            image: AssetImage(avatarAssetPath(id)),
            centre: slot == AvatarSlot.face && face != null
                ? Offset(face.x, face.y)
                : null,
            width: slot == AvatarSlot.face && face != null
                ? face.w * avatarFaceScale
                : null,
          ),
      ],
    );
  }
}
