import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/todos/model/chore_picture.dart';
import 'package:nestprep/features/todos/model/chore_picture_catalogue.dart';
import 'package:nestprep/features/todos/model/chore_picture_match.dart';
import 'package:nestprep/features/todos/ui/chore_picture_picker.dart';
import 'package:nestprep/shared/copy/chore_picture_copy.dart';

/// The picture picker (todos ADR-0005): search, what fits the title first,
/// every picture by category, and "No picture". The chosen one is said to be
/// selected, never shown by colour alone (`FE-13`).
void main() {
  late List<ChorePictureChoice?> results;

  setUp(() => results = []);

  Future<void> open(
    WidgetTester tester, {
    String title = 'Brush your teeth',
    String? selected,
    Brightness brightness = Brightness.light,
    double textScale = 1,
    Size phone = const Size(390, 844),
  }) async {
    tester.view.physicalSize = phone * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final nest = brightness == Brightness.dark
        ? NestTheme.dark()
        : NestTheme.light();
    await tester.pumpWidget(
      MaterialApp(
        theme: nestThemeData(nest),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => results.add(
                await showChorePicturePicker(
                  context: context,
                  title: title,
                  selected: selected,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder option(String id) => find.byKey(ValueKey('chore-picture-option-$id'));
  Finder anyOption() => find.byWidgetPredicate(
    (widget) =>
        widget.key is ValueKey<String> &&
        (widget.key! as ValueKey<String>).value.startsWith(
          'chore-picture-option-',
        ),
  );
  Finder library() => find.byType(Scrollable).last;

  Future<void> bringIntoView(
    WidgetTester tester,
    Finder finder, {
    double step = 200,
  }) async {
    await tester.scrollUntilVisible(finder, step, scrollable: library());
    await tester.pumpAndSettle();
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.pumpAndSettle();
  }

  /// The first tile the library draws: top row, leading edge.
  String firstTile(WidgetTester tester) {
    final tiles = anyOption().evaluate().map((e) => e.widget).toList()
      ..sort((a, b) {
        final pa = tester.getTopLeft(find.byWidget(a));
        final pb = tester.getTopLeft(find.byWidget(b));
        return pa.dy != pb.dy ? pa.dy.compareTo(pb.dy) : pa.dx.compareTo(pb.dx);
      });
    return (tiles.first.key! as ValueKey<String>).value.replaceFirst(
      'chore-picture-option-',
      '',
    );
  }

  testWidgets('offers what fits the title first, under Suggested', (
    tester,
  ) async {
    await open(tester);
    expect(find.text(ChorePictureCopy.pickerTitle), findsOneWidget);
    expect(find.text(ChorePictureCopy.suggested), findsOneWidget);
    expect(firstTile(tester), 'brush-teeth');
    expect(
      tester.getTopLeft(option('brush-teeth').first).dy,
      greaterThan(tester.getTopLeft(find.text(ChorePictureCopy.suggested)).dy),
    );
  });

  testWidgets('has nothing to suggest for a title nothing fits', (
    tester,
  ) async {
    await open(tester, title: 'Xyzzy plugh');
    expect(find.text(ChorePictureCopy.suggested), findsNothing);
    expect(firstTile(tester), chorePictureCatalogue.first.id);
  });

  testWidgets('draws the library as it scrolls, not all at once', (
    tester,
  ) async {
    await open(tester, title: '');
    expect(
      anyOption().evaluate().length,
      lessThan(chorePictureCatalogue.length ~/ 4),
    );
    await bringIntoView(
      tester,
      option(chorePictureCatalogue.last.id),
      step: 600,
    );
    expect(option(chorePictureCatalogue.last.id), findsOneWidget);
    expect(option(chorePictureCatalogue.first.id), findsNothing);
  });

  testWidgets('a search narrows the library as it is typed', (tester) async {
    await open(tester, title: '');
    await search(tester, 'water pla');
    expect(option('water-plants'), findsOneWidget);
    expect(option('brush-teeth'), findsNothing);
    expect(find.text(ChorePictureCopy.noPicture), findsNothing);
    for (final picture in searchChorePictures('water pla')) {
      expect(picture.label.toLowerCase(), isNot(contains('teeth')));
    }

    await search(tester, 'zebra');
    expect(find.text(ChorePictureCopy.nothingFound), findsOneWidget);
  });

  testWidgets('a category chip shows only that category', (tester) async {
    await open(tester, title: '');
    final pets = find.widgetWithText(
      NestChip,
      ChorePictureCopy.category(ChorePictureCategory.pets),
    );
    await tester.ensureVisible(pets);
    await tester.pumpAndSettle();
    await tester.tap(pets);
    await tester.pumpAndSettle();
    expect(
      firstTile(tester),
      [
        for (final picture in chorePictureCatalogue)
          if (picture.category == ChorePictureCategory.pets) picture.id,
      ].first,
    );
    await bringIntoView(tester, option('feed-dog'));
    expect(option('feed-dog'), findsOneWidget);
    expect(option('make-bed'), findsNothing);
  });

  testWidgets('tapping a picture returns its id', (tester) async {
    await open(tester, title: '');
    await search(tester, 'make bed');
    await bringIntoView(tester, option('make-bed'));
    await tester.tap(option('make-bed'));
    await tester.pumpAndSettle();
    expect(results.single?.id, 'make-bed');
    expect(find.text(ChorePictureCopy.pickerTitle), findsNothing);
  });

  testWidgets('No picture returns a clear, and closing returns nothing', (
    tester,
  ) async {
    await open(tester, selected: 'make-bed');
    await tester.tap(find.text(ChorePictureCopy.noPicture));
    await tester.pumpAndSettle();
    expect(results.single, isNotNull);
    expect(results.single!.id, isNull);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(results.last, isNull);
  });

  testWidgets('the chosen picture is announced as selected, and labelled', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await open(tester, title: '', selected: 'brush-teeth');
    await search(tester, 'teeth');
    final other = searchChorePictures('teeth')
        .firstWhere((picture) => picture.id != 'brush-teeth');
    expect(
      tester.getSemantics(option('brush-teeth')),
      isSemantics(
        label: 'Brush teeth',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(option(other.id)),
      isSemantics(
        label: other.label,
        isButton: true,
        isSelected: false,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSize(option(other.id)).shortestSide,
      greaterThanOrEqualTo(NestSize.touchTarget),
    );
    semantics.dispose();
  });

  testWidgets('renders in dark at 200% text on a 360-wide phone', (
    tester,
  ) async {
    await open(
      tester,
      brightness: Brightness.dark,
      textScale: 2,
      phone: const Size(360, 800),
    );
    expect(tester.takeException(), isNull);
    expect(find.text(ChorePictureCopy.suggested), findsOneWidget);

    await search(tester, 'dog');
    expect(tester.takeException(), isNull);
    await bringIntoView(tester, option('feed-dog'));
    expect(option('feed-dog'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
