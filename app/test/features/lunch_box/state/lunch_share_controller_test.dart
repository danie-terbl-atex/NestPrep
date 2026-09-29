import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/data/lunch_card_sharer.dart';
import 'package:nestprep/features/lunch_box/model/lunch_card_format.dart';
import 'package:nestprep/features/lunch_box/model/lunch_card_naming.dart';
import 'package:nestprep/features/lunch_box/model/lunch_card_style.dart';
import 'package:nestprep/features/lunch_box/state/lunch_share_controller.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_lunch_share.dart';
import '../../../support/lunch_card_fixtures.dart';
import '../../../support/lunch_fixtures.dart';

void main() {
  late FakeLunchCardRenderer renderer;
  late FakeLunchCardSharer sharer;
  late FakeLunchPlannerComposer planner;

  LunchShareController controllerFor({Uri? appLink}) => LunchShareController(
    cardRenderer: renderer,
    cardSharer: sharer,
    plannerComposer: planner,
    initialChildId: LunchFixtures.lwaziId,
    appLink: appLink,
  );

  setUp(() {
    renderer = FakeLunchCardRenderer();
    sharer = FakeLunchCardSharer();
    planner = FakeLunchPlannerComposer();
  });

  final board = LunchCardFixtures.board();

  group('the choices, for this share only', () {
    test('open on the board’s child, a story, initials and the invite on', () {
      final options = controllerFor().options;
      expect(options.childId, LunchFixtures.lwaziId);
      expect(options.format, LunchCardFormat.story);
      expect(options.style, LunchCardStyle.cream);
      expect(options.naming, LunchCardNaming.initials);
      expect(options.showsInvite, isTrue);
    });

    test('a first name chosen once is gone the next time the screen opens', () {
      final first = controllerFor()..chooseNaming(LunchCardNaming.firstNames);
      expect(first.contentFor(board).children.single.label, 'Lwazi');
      final next = controllerFor();
      expect(next.options.naming, LunchCardNaming.initials);
      expect(next.contentFor(board).children.single.label, 'L');
    });

    test('each choice changes the card, and says so once', () {
      final controller = controllerFor();
      var changes = 0;
      controller.addListener(() => changes++);
      controller
        ..chooseChild(null)
        ..chooseFormat(LunchCardFormat.post)
        ..chooseStyle(LunchCardStyle.forest)
        ..chooseNaming(LunchCardNaming.none)
        ..setShowsInvite(showsInvite: false)
        ..chooseFormat(LunchCardFormat.post);
      expect(changes, 5);
      expect(controller.contentFor(board).isFamily, isTrue);
    });

    test('the card is worked out once per board and choice', () {
      final controller = controllerFor();
      final first = controller.contentFor(board);
      expect(identical(controller.contentFor(board), first), isTrue);
      controller.chooseNaming(LunchCardNaming.none);
      expect(identical(controller.contentFor(board), first), isFalse);
    });
  });

  group('sharing the card', () {
    test(
      'draws the card as chosen and sends it with the invite link',
      () async {
        final controller = controllerFor(
          appLink: Uri.parse('https://nestprep.app/get'),
        )..chooseFormat(LunchCardFormat.chat);
        await controller.shareCard(board);

        final (content, options, host) = renderer.requests.single;
        expect(content.children.single.label, 'L');
        expect(options.format, LunchCardFormat.chat);
        expect(host, 'nestprep.app');
        final file = sharer.shared.single;
        expect(file.mimeType, LunchSharedFile.png);
        expect(file.bytes, FakeLunchCardRenderer.png);
        expect(file.fileName, 'nest-prep-lunches-2026-W40-chat.png');
        expect(file.text, contains('https://nestprep.app/get'));
        expect(controller.isBusy, isFalse);
        expect(controller.actionFailure, isNull);
      },
    );

    test('without the invite line, the words carry no link either', () async {
      final controller = controllerFor(
        appLink: Uri.parse('https://nestprep.app/get'),
      )..setShowsInvite(showsInvite: false);
      await controller.shareCard(board);
      expect(sharer.shared.single.text, LunchShareCopy.shareText(null));
      expect(renderer.requests.single.$2.showsInvite, isFalse);
    });

    test('with no link configured, the card names the app instead', () async {
      await controllerFor().shareCard(board);
      expect(renderer.requests.single.$3, isNull);
      expect(sharer.shared.single.text, LunchShareCopy.shareText(null));
    });

    test('a week with nothing packed is not drawn or sent', () async {
      await controllerFor().shareCard(LunchCardFixtures.board(plans: const []));
      expect(renderer.requests, isEmpty);
      expect(sharer.shared, isEmpty);
    });

    test(
      'a card that cannot be drawn is said in copy, and nothing is sent',
      () async {
        renderer.failWith = const LunchFailure(LunchProblem.cardNotDrawn);
        final controller = controllerFor();
        await controller.shareCard(board);
        expect(
          controller.actionFailure,
          const LunchFailure(LunchProblem.cardNotDrawn),
        );
        expect(sharer.shared, isEmpty);
        expect(controller.isBusy, isFalse);
      },
    );

    test('a share sheet that will not open is said in copy', () async {
      sharer.failWith = const LunchFailure(LunchProblem.shareUnavailable);
      final controller = controllerFor();
      await controller.shareCard(board);
      expect(
        controller.actionFailure,
        const LunchFailure(LunchProblem.shareUnavailable),
      );
    });

    test(
      'one thing at a time: a second tap while drawing does nothing',
      () async {
        renderer.gate = Completer<void>();
        final controller = controllerFor();
        final first = controller.shareCard(board);
        expect(controller.task, LunchShareTask.sharingCard);
        await controller.shareCard(board);
        await controller.printPlanner(board);
        renderer.gate!.complete();
        await first;
        expect(renderer.requests, hasLength(1));
        expect(sharer.printed, isEmpty);
        expect(controller.task, isNull);
      },
    );
  });

  group('the printable planner', () {
    test('this week, a page per child, named as the card would', () async {
      final controller = controllerFor()
        ..chooseChild(null)
        ..chooseNaming(LunchCardNaming.firstNames);
      await controller.printPlanner(board);
      final (content, showsInvite, _) = planner.requests.single;
      expect(
        [for (final child in content!.children) child.label],
        ['Lwazi', 'Ayanda'],
      );
      expect(showsInvite, isTrue);
      expect(sharer.printed.single, 'nest-prep-lunch-planner-2026-W40.pdf');
    });

    test('blank is the free printable: no week, no child', () async {
      final controller = controllerFor()..choosePlanner(LunchPlannerKind.blank);
      await controller.sendPlanner(board);
      expect(planner.requests.single.$1, isNull);
      final file = sharer.shared.single;
      expect(file.mimeType, LunchSharedFile.pdf);
      expect(file.fileName, 'nest-prep-lunch-planner.pdf');
    });

    test(
      'a phone that cannot print says so, and offers the PDF instead',
      () async {
        sharer.failWith = const LunchFailure(LunchProblem.printUnavailable);
        final controller = controllerFor();
        await controller.printPlanner(board);
        expect(
          controller.actionFailure,
          const LunchFailure(LunchProblem.printUnavailable),
        );
        expect(
          AppCopy.failure(controller.actionFailure!),
          contains('Send the PDF'),
        );
      },
    );
  });
}
