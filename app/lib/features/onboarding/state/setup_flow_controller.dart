import 'package:flutter/foundation.dart';

import '../model/onboarding_step.dart';

/// The panels of a new household's setup step (onboarding ADR-0001): family,
/// calendar, and the payoff once both are behind the person.
enum SetupPanel { family, calendar, ready }

/// Which setup panel is showing and who was last added, held on the phone
/// only: a restart begins at the family again, where everything already
/// added shows from Firestore. Closing the step is the invite controller's.
final class SetupFlowController extends ChangeNotifier {
  SetupPanel _panel = SetupPanel.family;
  String? _lastAdded;
  int _added = 0;

  SetupPanel get panel => _panel;

  /// The bar's step; the payoff keeps the last one, so the bar stays full.
  CreatorStep get step => switch (_panel) {
    SetupPanel.family => CreatorStep.family,
    SetupPanel.calendar || SetupPanel.ready => CreatorStep.calendar,
  };

  /// Who joined the nest last on this run, for Twig to name.
  String? get lastAdded => _lastAdded;

  /// How many people this run added, which Twig reacts to.
  int get added => _added;

  void noteAdded(String displayName) {
    _lastAdded = displayName;
    _added++;
    notifyListeners();
  }

  void next() {
    if (_panel == SetupPanel.ready) return;
    _panel = SetupPanel.values[_panel.index + 1];
    notifyListeners();
  }

  void back() {
    if (_panel == SetupPanel.family) return;
    _panel = SetupPanel.values[_panel.index - 1];
    notifyListeners();
  }
}
