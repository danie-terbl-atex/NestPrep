import 'package:flutter/foundation.dart';

import 'lunch_card_format.dart';
import 'lunch_card_naming.dart';
import 'lunch_card_style.dart';

/// What the parent chose on the share screen, for this share only (lunch-box
/// ADR-0005): whose week, which shape, which look, how children are named,
/// and whether the invite line is on. Never stored.
@immutable
class LunchCardOptions {
  const LunchCardOptions({
    required this.childId,
    this.format = LunchCardFormat.story,
    this.style = LunchCardStyle.cream,
    this.naming = LunchCardNaming.initials,
    this.showsInvite = true,
  });

  /// One child's week; null for every child's on one card.
  final String? childId;
  final LunchCardFormat format;
  final LunchCardStyle style;
  final LunchCardNaming naming;
  final bool showsInvite;

  bool get isFamily => childId == null;

  LunchCardOptions copyWith({
    ValueGetter<String?>? childId,
    LunchCardFormat? format,
    LunchCardStyle? style,
    LunchCardNaming? naming,
    bool? showsInvite,
  }) => LunchCardOptions(
    childId: childId == null ? this.childId : childId(),
    format: format ?? this.format,
    style: style ?? this.style,
    naming: naming ?? this.naming,
    showsInvite: showsInvite ?? this.showsInvite,
  );

  @override
  bool operator ==(Object other) =>
      other is LunchCardOptions &&
      other.childId == childId &&
      other.format == format &&
      other.style == style &&
      other.naming == naming &&
      other.showsInvite == showsInvite;

  @override
  int get hashCode => Object.hash(childId, format, style, naming, showsInvite);
}
