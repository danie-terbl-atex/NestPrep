import 'package:json_annotation/json_annotation.dart';

import 'helper_language.dart';

/// A [HelperLanguage] stored as its code (`zu`, `nso`), which is what the
/// rules check and Cloud Translation takes — not the enum's Dart name.
class HelperLanguageConverter
    implements JsonConverter<HelperLanguage, Object?> {
  const HelperLanguageConverter();

  @override
  HelperLanguage fromJson(Object? json) =>
      HelperLanguage.fromCode(json is String ? json : null);

  @override
  Object toJson(HelperLanguage value) => value.code;
}
