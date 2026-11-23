import 'dart:async';

import 'package:nestprep/features/app_update/data/app_restarter.dart';
import 'package:nestprep/features/app_update/data/patch_updates.dart';

final class FakePatchUpdates implements PatchUpdates {
  FakePatchUpdates([List<PatchReadiness> answers = const []])
    : _answers = [...answers];

  final List<PatchReadiness> _answers;
  Exception? error;
  int checks = 0;

  @override
  Future<PatchReadiness> check() async {
    checks++;
    final failure = error;
    if (failure != null) throw failure;
    return _answers.isEmpty ? PatchReadiness.current : _answers.removeAt(0);
  }
}

final class FakeAppRestarter implements AppRestarter {
  FakeAppRestarter({this.relaunches = true});

  final bool relaunches;
  int restarts = 0;

  @override
  Future<bool> canRelaunch() async => relaunches;

  @override
  Future<void> restart() async => restarts++;
}
