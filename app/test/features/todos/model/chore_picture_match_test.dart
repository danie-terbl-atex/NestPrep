import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/todos/model/chore_picture.dart';
import 'package:nestprep/features/todos/model/chore_picture_catalogue.dart';
import 'package:nestprep/features/todos/model/chore_picture_match.dart';
import 'package:nestprep/features/todos/model/task.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

/// The app suggests a picture from the title and never sets one (todos
/// ADR-0005); these are the suggestions it makes.
void main() {
  const library = [
    ChorePicture(
      id: 'brush-teeth',
      label: 'Brush teeth',
      category: ChorePictureCategory.hygiene,
      keywords: ['teeth', 'toothbrush', 'brush teeth'],
    ),
    ChorePicture(
      id: 'brush-hair',
      label: 'Brush hair',
      category: ChorePictureCategory.hygiene,
      keywords: ['hair', 'hairbrush', 'brush hair'],
    ),
    ChorePicture(
      id: 'wash-dishes',
      label: 'Wash the dishes',
      category: ChorePictureCategory.kitchen,
      keywords: ['wash dish', 'washing up', 'sink'],
    ),
    ChorePicture(
      id: 'tidy-toys',
      label: 'Tidy toys',
      category: ChorePictureCategory.bedroom,
      keywords: ['tidy toys', 'toy box', 'pack away toys'],
    ),
    ChorePicture(
      id: 'feed-dog',
      label: 'Feed the dog',
      category: ChorePictureCategory.pets,
      keywords: ['feed dog', 'dog bowl', 'dog'],
    ),
  ];

  List<String> suggest(String title, {int limit = 4}) => [
    for (final picture in suggestChorePictures(
      title,
      limit: limit,
      catalogue: library,
    ))
      picture.id,
  ];

  group('suggestChorePictures', () {
    test('"Brush your teeth" puts brushing teeth first', () {
      final found = suggest('Brush your teeth');
      expect(found.first, 'brush-teeth');
      // One word in common is a weaker match, behind the whole phrase.
      expect(found, ['brush-teeth', 'brush-hair']);
    });

    test('a whole-phrase keyword outranks words in common', () {
      expect(suggest('Hair brush before school').first, 'brush-hair');
    });

    test('a name it cannot know shares only the word it can', () {
      expect(suggest('Feed Rex'), ['feed-dog']);
      expect(suggest('Feed the dog'), ['feed-dog']);
    });

    test('says nothing for an empty or wordless title', () {
      expect(suggest(''), isEmpty);
      expect(suggest('   '), isEmpty);
      expect(suggest('!!!'), isEmpty);
      expect(suggest('the and your'), isEmpty);
    });

    test('ignores case, punctuation and apostrophes', () {
      expect(suggest('BRUSH TEETH!!').first, 'brush-teeth');
      expect(suggest("brush ya' teeth, pls.").first, 'brush-teeth');
      expect(suggest('Kid’s toothbrush').first, 'brush-teeth');
    });

    test('a plural or an -ing form is the same word', () {
      expect(suggest('Wash the dishes').first, 'wash-dishes');
      expect(suggest('Washing dishes').first, 'wash-dishes');
      expect(suggest('Tidying your toy').first, 'tidy-toys');
      expect(suggest('Feed the dogs'), ['feed-dog']);
    });

    test('a word that only sits in a phrase on its own is not enough', () {
      expect(suggest('Get up'), isEmpty);
    });

    test('returns at most the limit, nothing scored zero', () {
      expect(suggest('brush', limit: 1), hasLength(1));
      expect(suggest('Call Gran'), isEmpty);
    });

    test('the shipped library finds its own pictures from their labels', () {
      for (final picture in chorePictureCatalogue) {
        expect(
          suggestChorePictures(picture.label, limit: 1).single.id,
          picture.id,
          reason: picture.label,
        );
      }
    });
  });

  group('searchChorePictures', () {
    List<String> search(String query) => [
      for (final picture in searchChorePictures(query, catalogue: library))
        picture.id,
    ];

    test('finds as it is typed, by the start of any word', () {
      expect(search('bru'), containsAll(['brush-teeth', 'brush-hair']));
      expect(search('bru'), isNot(contains('feed-dog')));
      expect(search('tooth'), ['brush-teeth']);
    });

    test('every word typed has to match, and the best match leads', () {
      expect(search('brush hair'), ['brush-hair']);
      expect(search('brush').length, 2);
    });

    test('an empty search is the whole library, in order', () {
      expect(search(''), [for (final picture in library) picture.id]);
    });

    test('a search that matches nothing finds nothing', () {
      expect(search('zebra'), isEmpty);
    });
  });

  group('a task wearing a picture', () {
    Task task(String? picture) => Task(
      id: 't',
      title: 'Brush teeth',
      dueDate: CalendarDate(2026, 11, 5),
      createdBy: 'm',
      picture: picture,
    );

    test('draws the picture it names', () {
      expect(task('brush-teeth').chorePicture?.label, 'Brush teeth');
    });

    test('draws nothing for none, or an id this build does not ship', () {
      expect(task(null).chorePicture, isNull);
      expect(task('from-a-newer-build').chorePicture, isNull);
    });

    test('keeps an id it cannot draw, through both directions', () {
      final read = Task.fromJson({
        ...task('from-a-newer-build').toJson(),
        'id': 't',
        'createdAt': null,
      });
      expect(read.picture, 'from-a-newer-build');
      expect(read.toJson()['picture'], 'from-a-newer-build');
    });

    test('a document written before pictures reads as none', () {
      final json = task(null).toJson()..remove('picture');
      final read = Task.fromJson({...json, 'id': 't', 'createdAt': null});
      expect(read.picture, isNull);
    });
  });
}
