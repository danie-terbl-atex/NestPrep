import 'package:flutter/foundation.dart';

import 'shared_page.dart';

@immutable
sealed class FrameShareItem {
  const FrameShareItem();

  bool get isSendable;
}

final class FrameSharePage extends FrameShareItem {
  const FrameSharePage(this.page);

  final SharedPage page;

  @override
  bool get isSendable => page.url != null;
}

final class FrameShareRecipe extends FrameShareItem {
  const FrameShareRecipe({
    required this.recipeId,
    required this.name,
    required this.people,
    required this.amounts,
    this.cardPhotoPath,
  });

  final String recipeId;
  final String name;
  final int people;

  /// One per ingredient line in the recipe's order, null where the line has
  /// no quantity: the server refuses any other shape as `badRecipe`.
  final List<String?> amounts;
  final String? cardPhotoPath;

  @override
  bool get isSendable => true;
}
