import '../../../shared/failure/app_failure.dart';

/// A callable's answer as the string-keyed map a `fromJson` reads, or null
/// when it is not a map at all. The plugin hands back `Map<Object?, Object?>`
/// all the way down, so nested maps and lists are rebuilt rather than cast
/// (`ENG-09`).
Map<String, Object?>? stringKeyed(Object? value) {
  if (value is! Map) return null;
  return {
    for (final MapEntry(:key, :value) in value.entries)
      if (key is String) key: _plain(value),
  };
}

Object? _plain(Object? value) => switch (value) {
  final Map<Object?, Object?> map => stringKeyed(map),
  final List<Object?> list => [for (final item in list) _plain(item)],
  _ => value,
};

/// Builds a model from a callable's answer, turning a shape this build cannot
/// read into an `UnknownFailure` the screen can say something about, rather
/// than a crash (`BE-10`).
T parseOrFail<T>(String operation, T Function() parse) {
  try {
    return parse();
  } on FormatException catch (error) {
    throw UnknownFailure(error);
  } on TypeError catch (error) {
    throw UnknownFailure(FormatException('$operation: $error'));
  }
}
