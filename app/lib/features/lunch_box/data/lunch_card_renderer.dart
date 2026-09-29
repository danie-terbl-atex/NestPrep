import 'dart:typed_data';

import '../model/lunch_card_content.dart';
import '../model/lunch_card_options.dart';

/// Turns a card into the PNG a parent shares (lunch-box ADR-0005). Behind an
/// interface so the share screen's tests need no engine to rasterise.
abstract interface class LunchCardRenderer {
  /// The card at its format's export size. Throws `LunchFailure` with
  /// `cardNotDrawn` when this phone cannot draw it.
  Future<Uint8List> render({
    required LunchCardContent content,
    required LunchCardOptions options,
    required String? inviteHost,
  });
}
