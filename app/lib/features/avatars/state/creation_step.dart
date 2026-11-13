import 'package:flutter/foundation.dart';

import '../model/avatar_buddy.dart';
import '../model/avatar_creation.dart';

@immutable
sealed class CreationStep {
  const CreationStep();
}

final class CreationComposing extends CreationStep {
  const CreationComposing();
}

final class CreationSending extends CreationStep {
  const CreationSending(this.recipe);

  final CreationRecipe recipe;
}

final class CreationWaiting extends CreationStep {
  const CreationWaiting(this.recipe, {this.status});

  final CreationRecipe recipe;
  final CreationStatus? status;

  bool get isDrawing => status == CreationStatus.drawing;
}

final class CreationReady extends CreationStep {
  const CreationReady(this.creation, {this.buddy});

  final AvatarCreation creation;
  final AvatarBuddy? buddy;

  String get imageHash => creation.imageHash!;
}

final class CreationRefused extends CreationStep {
  const CreationRefused(this.recipe, this.reason, {this.left});

  final CreationRecipe recipe;
  final CreationRefusal reason;
  final int? left;
}

final class CreationTooSlow extends CreationStep {
  const CreationTooSlow(this.recipe);

  final CreationRecipe recipe;
}
