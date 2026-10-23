import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/plan_week/model/packing_preference.dart';
import 'package:nestprep/features/plan_week/model/treat_days.dart';

/// A brief's packing choice for a test: the compartments it fills, no
/// preference, and Friday's treat unless the test says otherwise.
PackingChoice packingFor(
  Set<LunchSlot> slots, {
  Set<int> treatDays = TreatDays.fridayOnly,
  Set<PackingPreference> preferences = const {},
}) => (preferences: preferences, slots: slots, treatDays: treatDays);
