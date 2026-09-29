import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/documents/model/document_search.dart';
import 'package:nestprep/features/documents/state/document_search_controller.dart';

/// The search screen's query: it starts from its link, and each filter is one
/// tap on and one tap off.
void main() {
  test('starts from the filters its link carried', () {
    final controller = DocumentSearchController(
      initial: const DocumentQuery(expiringSoonOnly: true),
    );
    expect(controller.query.expiringSoonOnly, isTrue);
  });

  test('a tag is toggled, whatever case it was tapped in', () {
    final controller = DocumentSearchController()..toggleTag('ID');
    expect(controller.query.tag, 'ID');
    controller.toggleTag('id');
    expect(controller.query.tag, isNull);
  });

  test('clearing the filters keeps what was typed', () {
    final controller = DocumentSearchController()
      ..setText('passport')
      ..setOwner(OwnerFilter.household)
      ..setExpiringSoonOnly(true)
      ..clear();
    expect(controller.query.text, 'passport');
    expect(controller.query.owner, OwnerFilter.anyone);
    expect(controller.query.expiringSoonOnly, isFalse);
  });
}
