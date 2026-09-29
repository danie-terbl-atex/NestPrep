import 'dart:async';
import 'dart:typed_data';

import 'package:nestprep/features/lunch_box/data/lunch_card_renderer.dart';
import 'package:nestprep/features/lunch_box/data/lunch_card_sharer.dart';
import 'package:nestprep/features/lunch_box/data/lunch_planner_composer.dart';
import 'package:nestprep/features/lunch_box/model/lunch_card_content.dart';
import 'package:nestprep/features/lunch_box/model/lunch_card_options.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// A card renderer that draws nothing: it remembers what it was asked for
/// and answers with a few bytes — or the failure it was told to throw.
final class FakeLunchCardRenderer implements LunchCardRenderer {
  static final png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);

  final requests = <(LunchCardContent, LunchCardOptions, String?)>[];
  AppFailure? failWith;

  /// Holds the render open until completed, for a test of what happens
  /// while it runs.
  Completer<void>? gate;

  @override
  Future<Uint8List> render({
    required LunchCardContent content,
    required LunchCardOptions options,
    required String? inviteHost,
  }) async {
    requests.add((content, options, inviteHost));
    await gate?.future;
    final failure = failWith;
    if (failure != null) throw failure;
    return png;
  }
}

/// The share sheet and print dialog, recorded rather than opened.
final class FakeLunchCardSharer implements LunchCardSharer {
  final shared = <LunchSharedFile>[];
  final printed = <String>[];
  AppFailure? failWith;

  @override
  Future<void> shareFile(LunchSharedFile file) async {
    final failure = failWith;
    if (failure != null) throw failure;
    shared.add(file);
  }

  @override
  Future<void> printPdf({required Uint8List pdf, required String name}) async {
    final failure = failWith;
    if (failure != null) throw failure;
    printed.add(name);
  }
}

/// A planner that remembers what it was asked to put on its pages.
final class FakeLunchPlannerComposer implements LunchPlannerComposer {
  static final pdf = Uint8List.fromList('%PDF'.codeUnits);

  final requests = <(LunchCardContent?, bool, String?)>[];

  @override
  Future<Uint8List> compose({
    required LunchCardContent? content,
    required bool showsInvite,
    required String? inviteHost,
  }) async {
    requests.add((content, showsInvite, inviteHost));
    return pdf;
  }
}
