import 'package:flutter/foundation.dart';

import '../../live_location/model/coordinates.dart';
import 'checkers_area.dart';

/// Where a product search looks: the phone's own position, when its owner
/// has already let NestPrep use it, or the household's chosen area.
@immutable
final class CheckersPlace {
  const CheckersPlace.device(Coordinates this.deviceAt) : area = null;

  const CheckersPlace.area(CheckersArea this.area) : deviceAt = null;

  final Coordinates? deviceAt;
  final CheckersArea? area;

  bool get isDevice => deviceAt != null;

  Coordinates get coordinates =>
      deviceAt ?? (area ?? CheckersArea.fallback).centre;
}
