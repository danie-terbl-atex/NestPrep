import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/documents/model/document_tags.dart';

/// A document's tags on the phone: tidy, no repeats whatever the case, and no
/// more than the rules allow (documents ADR-0005).
void main() {
  test('tidies what was typed rather than storing stray spaces', () {
    expect(DocumentTags.adding(const [], '  medical   aid '), ['medical aid']);
  });

  test('"ID" and "id" are one tag to somebody searching', () {
    expect(DocumentTags.adding(const ['ID'], 'id'), ['ID']);
    expect(DocumentTags.contains(const ['School'], 'school'), isTrue);
  });

  test('refuses an empty tag, a ninth tag, and one past 24 letters', () {
    expect(DocumentTags.adding(const [], '   '), isEmpty);
    final eight = [for (var i = 0; i < 8; i++) 't$i'];
    expect(DocumentTags.adding(eight, 'ninth'), eight);
    expect(DocumentTags.canAdd(const [], 'x' * 25), isFalse);
    expect(DocumentTags.canAdd(const [], 'x' * 24), isTrue);
  });

  test('the vocabulary is every tag once, in the order first seen', () {
    expect(
      DocumentTags.vocabulary([
        ['ID', 'Travel'],
        ['id', 'School'],
        ['travel'],
      ]),
      ['ID', 'Travel', 'School'],
    );
  });
}
