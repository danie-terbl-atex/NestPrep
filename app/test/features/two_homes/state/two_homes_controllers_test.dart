import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/two_homes/data/two_homes_directory.dart';
import 'package:nestprep/features/two_homes/model/change_request.dart';
import 'package:nestprep/features/two_homes/model/co_parent_link.dart';
import 'package:nestprep/features/two_homes/model/custody_side.dart';
import 'package:nestprep/features/two_homes/model/handover_note.dart';
import 'package:nestprep/features/two_homes/model/two_homes_access.dart';
import 'package:nestprep/features/two_homes/state/custody_calendar.dart';
import 'package:nestprep/features/two_homes/state/handover_controller.dart';
import 'package:nestprep/features/two_homes/state/link_controller.dart';
import 'package:nestprep/features/two_homes/state/two_homes_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../../support/fake_two_homes.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/two_homes_model_fixtures.dart';

/// The controllers behind the two-homes screens (household ADR-0004), over
/// fakes: what they read, which reads a grant opens, what they send, and
/// where a refusal goes.
void main() {
  late FakeTwoHomesRepository repository;
  late FakeTwoHomesDirectory directory;
  final today = CalendarDate(2026, 9, 29);

  setUp(() {
    repository = FakeTwoHomesRepository();
    directory = FakeTwoHomesDirectory();
  });

  tearDown(() => repository.close());

  group('the list', () {
    TwoHomesController make() => TwoHomesController(
      twoHomesRepository: repository,
      twoHomesDirectory: directory,
      householdId: 'h1',
      today: today,
    );

    test(
      'puts pending links first, then active, and keeps the rest apart',
      () async {
        final controller = make();
        expect(controller.links, isA<AsyncLoading<List<CoParentLink>>>());
        repository.links.add([
          aLink().copyWith(id: 'active'),
          aLink(status: LinkStatus.ended).copyWith(id: 'ended'),
          aLink(status: LinkStatus.pending).copyWith(id: 'pending'),
        ]);
        await pumpEventQueue();
        expect(
          [for (final link in controller.openLinks) link.id],
          ['pending', 'active'],
        );
        expect([for (final link in controller.pastLinks) link.id], ['ended']);
        controller.dispose();
      },
    );

    test('confirms and ends through the callables', () async {
      final controller = make();
      final link = aLink(status: LinkStatus.pending);
      await controller.confirm(link, accept: true);
      await controller.end(link);
      expect(directory.names, ['confirmLink', 'endLink']);
      expect(directory.lastOf('confirmLink'), {
        'linkId': 'link-sam',
        'accept': true,
      });
      expect(controller.busyLinkId, isNull);
      controller.dispose();
    });

    test('holds a refusal for the banner', () async {
      final controller = make();
      directory.failWith = const CoParentFailure(CoParentProblem.notYourTurn);
      await controller.confirm(aLink(), accept: true);
      expect(controller.actionFailure, isA<CoParentFailure>());
      controller.dispose();
    });

    test('a read that fails is a failure the screen can retry', () async {
      final controller = make();
      repository.links.addError(const PermissionDeniedFailure());
      await pumpEventQueue();
      expect(controller.links, isA<AsyncFailure<List<CoParentLink>>>());
      await controller.retry();
      repository.links.add([]);
      await pumpEventQueue();
      expect(controller.links, isA<AsyncData<List<CoParentLink>>>());
      controller.dispose();
    });
  });

  group('one link', () {
    LinkController make(TwoHomesAccess access) => LinkController(
      twoHomesRepository: repository,
      twoHomesDirectory: directory,
      householdId: 'h1',
      linkId: 'link-sam',
      today: today,
      access: access,
    );

    test('family opens the link, its requests and its handovers', () async {
      final controller = make(TwoHomesAccess.of(Fixtures.view()));
      expect(repository.readsOpened, ['link', 'requests', 'handovers']);
      repository.link.add(aLink());
      repository.requests.add([
        const ChangeRequest(
          id: 'waiting',
          kind: ChangeKind.swap,
          proposedBySide: CustodySide.b,
          status: RequestStatus.pending,
        ),
        const ChangeRequest(
          id: 'done',
          kind: ChangeKind.swap,
          proposedBySide: CustodySide.a,
          status: RequestStatus.declined,
        ),
      ]);
      final friday = CalendarDate(2026, 10, 2);
      repository.handovers.add([HandoverNote(id: friday.iso, date: friday)]);
      await pumpEventQueue();
      expect(controller.link, isA<AsyncData<CoParentLink?>>());
      expect([for (final r in controller.waiting) r.id], ['waiting']);
      expect([for (final r in controller.answered) r.id], ['done']);
      expect(controller.handoverOn(friday), isNotNull);
      controller.dispose();
    });

    test('a helper who only reads the calendar opens the link alone', () {
      final controller = make(
        TwoHomesAccess.of(
          Fixtures.helperView(
            AccessGrant.uniform(
              AccessLevel.none,
            ).withLevel(HouseholdArea.calendar, AccessLevel.view),
          ),
        ),
      );
      expect(repository.readsOpened, ['link']);
      controller.dispose();
    });

    test('sends a swap, a schedule, an answer and an end, trimmed', () async {
      final controller = make(TwoHomesAccess.of(Fixtures.view()));
      final friday = CalendarDate(2026, 10, 2);
      expect(
        await controller.proposeSwap(
          from: friday,
          to: friday.addDays(1),
          toSide: CustodySide.a,
          note: '  Granny’s birthday ',
        ),
        isTrue,
      );
      expect(directory.lastOf('proposeSwap')['note'], 'Granny’s birthday');
      await controller.proposeSchedule(aLink().schedule, note: '   ');
      expect(directory.lastOf('proposeSchedule')['note'], isNull);
      await controller.answer(
        const ChangeRequest(
          id: 'r1',
          kind: ChangeKind.swap,
          proposedBySide: CustodySide.b,
          status: RequestStatus.pending,
        ),
        ChangeAnswer.accept,
      );
      expect(directory.lastOf('answerChange')['answer'], ChangeAnswer.accept);
      await controller.confirm(accept: false);
      await controller.end();
      expect(directory.names, [
        'proposeSwap',
        'proposeSchedule',
        'answerChange',
        'confirmLink',
        'endLink',
      ]);
      controller.dispose();
    });

    test('a refused send says so, and returns false', () async {
      final controller = make(TwoHomesAccess.of(Fixtures.view()));
      directory.failWith = const CoParentFailure(
        CoParentProblem.tooManyRequests,
      );
      expect(await controller.end(), isFalse);
      expect(controller.actionFailure, isA<CoParentFailure>());
      controller.dispose();
    });

    test('a failed part keeps the link and raises the banner', () async {
      final controller = make(TwoHomesAccess.of(Fixtures.view()));
      repository.link.add(aLink());
      repository.requests.addError(const PermissionDeniedFailure());
      await pumpEventQueue();
      expect(controller.link, isA<AsyncData<CoParentLink?>>());
      expect(controller.actionFailure, isA<PermissionDeniedFailure>());
      await controller.retry();
      expect(controller.link, isA<AsyncLoading<CoParentLink?>>());
      controller.dispose();
    });
  });

  group('one handover', () {
    final friday = CalendarDate(2026, 10, 2);
    HandoverController make() => HandoverController(
      twoHomesRepository: repository,
      twoHomesDirectory: directory,
      householdId: 'h1',
      linkId: 'link-sam',
      date: friday,
    );

    test('waits for both reads, then shows the link and the note', () async {
      final controller = make();
      repository.link.add(aLink());
      await pumpEventQueue();
      expect(controller.view, isA<AsyncLoading<Object?>>());
      repository.handover.add(null);
      await pumpEventQueue();
      final view = (controller.view as AsyncData).value;
      expect(view, isNotNull);
      controller.dispose();
    });

    test('saves trimmed text and drops empty items', () async {
      final controller = make();
      final saved = await controller.save(
        items: const [
          HandoverItem(text: ' Bag ', packed: true),
          HandoverItem(text: '   ', packed: false),
        ],
        medicine: ' Inhaler ',
        homework: '',
        note: 'Tired',
      );
      expect(saved, isTrue);
      expect(controller.justSaved, isTrue);
      final sent = directory.lastOf('saveHandover');
      expect(sent['items'], const [HandoverItem(text: 'Bag', packed: true)]);
      expect(sent['medicine'], 'Inhaler');
      expect(sent['homework'], isNull);
      controller.edited();
      expect(controller.justSaved, isFalse);
      controller.dispose();
    });

    test(
      'a refused save is held, and the read failing is the screen’s',
      () async {
        final controller = make();
        directory.failWith = const CoParentFailure(
          CoParentProblem.linkNotActive,
        );
        expect(await controller.save(items: const []), isFalse);
        expect(controller.actionFailure, isA<CoParentFailure>());
        repository.handover.addError(const PermissionDeniedFailure());
        await pumpEventQueue();
        expect(controller.view, isA<AsyncFailure<Object?>>());
        await controller.retry();
        expect(controller.view, isA<AsyncLoading<Object?>>());
        controller.dispose();
      },
    );
  });

  group('the calendar’s bands', () {
    test('one per active link, in the home the child is with', () async {
      final calendar = CustodyCalendar(
        twoHomesRepository: repository,
        householdId: 'h1',
      );
      final friday = CalendarDate(2026, 10, 2);
      expect(calendar.on(friday), isEmpty);
      repository.links.add([aLink(), aLink(status: LinkStatus.pending)]);
      await pumpEventQueue();
      expect(calendar.hasLinks, isTrue);
      final bands = calendar.on(friday);
      expect(bands, hasLength(1));
      expect(bands.single.day.isHandover, isTrue);
      expect(calendar.coloursOn(friday), [bands.single.home.color]);
      calendar.dispose();
    });

    test('a read that fails is held for a quiet retry', () async {
      final calendar = CustodyCalendar(
        twoHomesRepository: repository,
        householdId: 'h1',
      );
      repository.links.addError(const UnavailableFailure());
      await pumpEventQueue();
      expect(calendar.failure, isA<UnavailableFailure>());
      await calendar.retry();
      expect(calendar.failure, isNull);
      calendar.dispose();
    });
  });
}
