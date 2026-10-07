import 'dart:async';

import 'package:nestprep/features/add_to_checkers/data/checkers_catalogue.dart';
import 'package:nestprep/features/add_to_checkers/model/checkers_product.dart';
import 'package:nestprep/features/add_to_checkers/model/checkers_shelf.dart';
import 'package:nestprep/features/live_location/model/coordinates.dart';
import 'package:nestprep/features/lunch_box/model/lunch_week.dart';
import 'package:nestprep/features/plan_week/data/lunch_aisle_source.dart';
import 'package:nestprep/features/plan_week/data/lunch_idea_drafter.dart';
import 'package:nestprep/features/plan_week/data/lunch_week_builder.dart';
import 'package:nestprep/features/plan_week/data/packing_choice_store.dart';
import 'package:nestprep/features/plan_week/model/aisle_shelf.dart';
import 'package:nestprep/features/plan_week/model/idea_search.dart';
import 'package:nestprep/features/plan_week/model/lunch_ideas_reply.dart';
import 'package:nestprep/features/plan_week/model/lunch_week_reply.dart';
import 'package:nestprep/features/plan_week/model/packing_preference.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// `draftLunchIdeas`, answered by the test: [reply], or [failWith].
final class FakeLunchIdeaDrafter implements LunchIdeaDrafter {
  LunchIdeasReply? reply;
  AppFailure? failWith;

  /// When set, an answer waits for it — so a test sees the step working.
  Completer<void>? gate;
  final asked = <Set<String>>[];
  final aisles = <List<AisleShelfNames>>[];
  final packed = <PackingChoice>[];

  @override
  Future<LunchIdeasReply> draft({
    required String householdId,
    required LunchWeek week,
    required Set<String> childIds,
    required PackingChoice packing,
    List<AisleShelfNames> aisle = const [],
  }) async {
    asked.add(childIds);
    aisles.add(aisle);
    packed.add(packing);
    await gate?.future;
    final failure = failWith;
    if (failure != null) throw failure;
    return reply ??
        LunchIdeasReply(ideas: const [], budgetCents: null, callsLeft: null);
  }
}

/// `buildLunchWeek`, answered by the test: [reply], or [failWith].
final class FakeLunchWeekBuilder implements LunchWeekBuilder {
  LunchWeekReply? reply;
  AppFailure? failWith;
  final sent = <List<IdeaSearch>>[];
  final packed = <PackingChoice>[];

  @override
  Future<LunchWeekReply> build({
    required String householdId,
    required LunchWeek week,
    required Set<String> childIds,
    required List<IdeaSearch> searches,
    required PackingChoice packing,
  }) async {
    sent.add(searches);
    packed.add(packing);
    final failure = failWith;
    if (failure != null) throw failure;
    return reply ??
        LunchWeekReply(
          lunches: const [],
          boxesPerPack: const {},
          budgetCents: null,
          dropped: 0,
          callsLeft: null,
        );
  }
}

/// The shop, answering each search by its words and each shelf by its id;
/// [failFor] fails a search, [failShelf] a shelf.
final class FakeShopCatalogue implements CheckersCatalogue {
  final byQuery = <String, List<CheckersProduct>>{};
  final byShelf = <CheckersShelf, List<CheckersProduct>>{};
  final failFor = <String, AppFailure>{};
  final failShelf = <CheckersShelf, AppFailure>{};
  final queries = <String>[];
  final shelves = <CheckersShelf>[];

  /// When set, a search waits for it — so a test sees the shop working.
  Completer<void>? gate;

  @override
  Future<List<CheckersProduct>> search({
    required String query,
    required Coordinates near,
    int limit = CheckersCatalogue.defaultLimit,
  }) async {
    queries.add(query);
    await gate?.future;
    final failure = failFor[query];
    if (failure != null) throw failure;
    return (byQuery[query] ?? const []).take(limit).toList();
  }

  @override
  Future<List<CheckersProduct>> shelf({
    required CheckersShelf shelf,
    required Coordinates near,
    int limit = CheckersCatalogue.defaultLimit,
  }) async {
    shelves.add(shelf);
    final failure = failShelf[shelf];
    if (failure != null) throw failure;
    return (byShelf[shelf] ?? const []).take(limit).toList();
  }
}

/// The shelves to read, decided by the test: none unless it says so, so a
/// test about something else is not walking the aisle.
final class FakeLunchAisleSource implements LunchAisleSource {
  List<AisleShelf> answer = const [];

  @override
  Future<List<AisleShelf>> shelves() async => answer;
}

/// The packing choices this phone remembers, per household; [failRead]
/// answers as an unreadable store does.
final class FakePackingChoiceStore implements PackingChoiceStore {
  final kept = <String, PackingChoice>{};
  var failRead = false;

  @override
  Future<PackingChoice?> read(String householdId) async =>
      failRead ? null : kept[householdId];

  @override
  Future<void> write(String householdId, PackingChoice choice) async =>
      kept[householdId] = choice;
}
