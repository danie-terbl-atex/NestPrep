import 'package:flutter/foundation.dart';

/// A ready-made step a parent can take with one tap: its words and the
/// sticker that goes with them (kid-routines ADR-0001).
@immutable
final class KidRoutineStarter {
  const KidRoutineStarter(this.title, this.picture);

  final String title;
  final String picture;
}
