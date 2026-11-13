import 'package:flutter/material.dart';

import '../model/avatar_catalogue.g.dart';
import '../model/avatar_stage.dart';
import '../model/avatar_studio.dart';
import 'nestling_picture.dart';

class CreationEgg extends StatelessWidget {
  const CreationEgg({required this.studio, this.size, super.key});

  final AvatarStudio studio;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final name = studio.nestlingName() ?? avatarNestlings.first.name;
    return ExcludeSemantics(
      child: NestlingPicture(
        name: name,
        label: studio.library.nestling(name)?.label ?? name,
        stage: AvatarStage.egg,
        color: studio.member.color,
        size: size,
      ),
    );
  }
}
