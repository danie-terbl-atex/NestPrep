import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/photo_frames/data/frame_share_payload.dart';
import 'package:nestprep/features/photo_frames/model/frame_share_item.dart';
import 'package:nestprep/features/photo_frames/model/shared_page.dart';

void main() {
  test('a page is sent exactly as before', () {
    expect(
      frameSharePayload(
        householdId: 'house',
        frameId: 'frame-kitchen',
        item: const FrameSharePage(
          SharedPage(url: 'https://example.com/tart', title: 'Lemon tart'),
        ),
      ),
      {
        'householdId': 'house',
        'frameId': 'frame-kitchen',
        'url': 'https://example.com/tart',
        'title': 'Lemon tart',
      },
    );
  });

  test('a page with no title sends no title', () {
    final payload = frameSharePayload(
      householdId: 'house',
      frameId: 'frame-kitchen',
      item: const FrameSharePage(SharedPage(url: 'https://example.com')),
    );

    expect(payload.containsKey('title'), isFalse);
  });

  test('a recipe sends its id, people and amounts, and nothing else', () {
    expect(
      frameSharePayload(
        householdId: 'house',
        frameId: 'frame-kitchen',
        item: const FrameShareRecipe(
          recipeId: 'bobotie',
          name: 'Bobotie',
          people: 4,
          amounts: ['500 g', null, '1 1/2 cups'],
          cardPhotoPath: 'recipes/bobotie/card.jpg',
        ),
      ),
      {
        'householdId': 'house',
        'frameId': 'frame-kitchen',
        'recipe': {
          'id': 'bobotie',
          'people': 4,
          'amounts': ['500 g', null, '1 1/2 cups'],
        },
      },
    );
  });
}
