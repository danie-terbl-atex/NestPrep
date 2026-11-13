import 'package:flutter/foundation.dart';

@immutable
sealed class AvatarBase {
  const AvatarBase();

  static final _name = RegExp(r'^[a-z0-9-]{1,48}$');
  static final _hash = RegExp(r'^[0-9a-f]{32}$');

  static AvatarBase parse(String? stored) {
    if (stored == null) return const InitialBase();
    if (stored.startsWith(PresetBase.prefix)) {
      final name = stored.substring(PresetBase.prefix.length);
      if (_name.hasMatch(name)) return PresetBase(name);
    }
    if (stored.startsWith(ImageBase.prefix)) {
      final hash = stored.substring(ImageBase.prefix.length);
      if (_hash.hasMatch(hash)) return ImageBase(hash);
    }
    return const InitialBase();
  }

  static bool isImageHash(String value) => _hash.hasMatch(value);

  String get stored;
}

final class InitialBase extends AvatarBase {
  const InitialBase();

  static const value = 'initial';

  @override
  String get stored => value;

  @override
  bool operator ==(Object other) => other is InitialBase;

  @override
  int get hashCode => value.hashCode;
}

final class PresetBase extends AvatarBase {
  const PresetBase(this.name);

  static const prefix = 'preset:';

  final String name;

  @override
  String get stored => '$prefix$name';

  @override
  bool operator ==(Object other) => other is PresetBase && other.name == name;

  @override
  int get hashCode => stored.hashCode;
}

final class ImageBase extends AvatarBase {
  const ImageBase(this.hash);

  static const prefix = 'image:';

  final String hash;

  @override
  String get stored => '$prefix$hash';

  @override
  bool operator ==(Object other) => other is ImageBase && other.hash == hash;

  @override
  int get hashCode => stored.hashCode;
}
