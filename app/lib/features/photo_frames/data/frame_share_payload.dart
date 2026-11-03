import '../model/frame_share_item.dart';

Map<String, Object?> frameSharePayload({
  required String householdId,
  required String frameId,
  required FrameShareItem item,
}) => {
  'householdId': householdId,
  'frameId': frameId,
  ...switch (item) {
    FrameSharePage(:final page) => {'url': page.url, 'title': ?page.title},
    FrameShareRecipe(:final recipeId, :final people, :final amounts) => {
      'recipe': {'id': recipeId, 'people': people, 'amounts': amounts},
    },
  },
};
