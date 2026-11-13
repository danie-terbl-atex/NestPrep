import 'dart:math';

abstract final class OwnRecipeIds {
  static final _random = Random.secure();

  static String newRecipeId() => 'own-${_hex(20)}';

  static String newPhotoId() => _hex(20);

  static String _hex(int length) =>
      [for (var i = 0; i < length; i++) _random.nextInt(16).toRadixString(16)]
          .join();
}
